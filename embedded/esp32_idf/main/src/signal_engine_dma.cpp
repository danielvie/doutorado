// Copyright 2026 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.
//
// I2S1-parallel DMA signal engine (see signal_engine_dma.h and
// docs/adr/0001-dual-signal-engine-i2s-dma.md).
//
// Peripheral choice: the analog pipeline (adc_continuous) internally owns
// I2S0 on the classic ESP32, so this engine uses I2S1, whose 8-bit LCD mode
// supports single-byte parallel output. Register recipe follows the
// field-proven i2s_parallel drivers (Sprite_tm lineage): sample rate =
// 80 MHz / clkm_div_num with lcd_tx_wrx2_en=1, and the TX FIFO transmits the
// bytes of each 32-bit word in the order 2,3,0,1 — the renderer stores byte j
// at buf[j ^ 2] so the wire order is sequential.

#include "signal_engine_dma.h"
#include "helper_analog.h"

#include "esp_heap_caps.h"
#include "esp_intr_alloc.h"
#include "esp_private/periph_ctrl.h"
#include "esp_rom_gpio.h"
#include "hal/gpio_ll.h"
#include "rom/lldesc.h"
#include "soc/gpio_sig_map.h"
#include "soc/gpio_struct.h"
#include "soc/i2s_struct.h"
#include "soc/io_mux_reg.h"
#include "soc/periph_defs.h"
#include "soc/soc.h"

#include <cstdio>
#include <cstring>

static const char *TAG = "SIG_DMA";

static constexpr uint32_t CYCLES_PER_US = 240;
static constexpr uint32_t DMA_SAMPLES_PER_US =
    SIGNAL_TIME_TICKS_PER_US * SIGNAL_DMA_SAMPLES_PER_TICK;

// 80 MHz APLL-free I2S base clock divided down to the sample clock (D2).
static constexpr uint32_t DMA_CLKM_DIV_NUM =
    80000000U / SIGNAL_DMA_SAMPLE_RATE_HZ;
static_assert(80000000U % SIGNAL_DMA_SAMPLE_RATE_HZ == 0,
              "sample clock must divide 80 MHz exactly");
static_assert(DMA_CLKM_DIV_NUM >= 2, "clkm_div_num must be >= 2");

// Minimum active hold mirrors the CPU engine's 1 us floor.
static constexpr uint32_t DMA_MIN_ACTIVE_HOLD_SAMPLES = DMA_SAMPLES_PER_US;

// Buffer budget: 16 KB per buffer = 819 us of bitstream at 20 MHz. Patterns
// that render longer than this must use the CPU engine.
static constexpr size_t DMA_MAX_BUFFER_BYTES = 16384;

// Short cycles are replicated until a buffer pass reaches this floor, so the
// control task is not woken at unsustainable rates (mirrors the CPU engine's
// short-pattern batching).
static constexpr uint32_t DMA_MIN_PASS_SAMPLES = 200 * DMA_SAMPLES_PER_US;

// Control Point lead (D3/D4): the control-trigger EOF descriptor sits this
// far before the buffer-pass boundary. Measurement, correction, render and
// relink must all complete inside this window for the N -> N+1 contract.
static constexpr uint32_t DMA_CONTROL_LEAD_US = 120;

static constexpr size_t DMA_DESC_MAX_BYTES = 4092; // < 4095, multiple of 4
static constexpr uint32_t DMA_DESC_COUNT =
    (DMA_MAX_BUFFER_BYTES / DMA_DESC_MAX_BYTES) + 3;

// Task notification bits from the ISR.
static constexpr uint32_t NOTIF_TRIGGER = 1u << 0; // control point reached
static constexpr uint32_t NOTIF_TAIL = 1u << 1;    // buffer pass boundary
static constexpr uint32_t NOTIF_FAULT = 1u << 2;   // descriptor error

// Reserved per-boundary edge trim in whole samples (D10). Stays 0 until Lab
// Timing Characterization proves a systematic offset.
volatile int32_t g_dma_edge_trim_up_samples = 0;
volatile int32_t g_dma_edge_trim_down_samples = 0;

// ---------------------------------------------------------------------------
// Pin lanes: I2S1 parallel data bit k drives lane k's GPIO.
// ---------------------------------------------------------------------------
struct DmaLane {
    gpio_num_t pin;
    uint32_t gpio_mask;
};

static const DmaLane k_lanes[6] = {
    {(gpio_num_t)PIN_U1_LOW, MASK_U1_LOW},   // I2S1 D0
    {(gpio_num_t)PIN_U1_HIGH, MASK_U1_HIGH}, // I2S1 D1
    {(gpio_num_t)PIN_U2_LOW, MASK_U2_LOW},   // I2S1 D2
    {(gpio_num_t)PIN_U2_HIGH, MASK_U2_HIGH}, // I2S1 D3
    {(gpio_num_t)PIN_U3_LOW, MASK_U3_LOW},   // I2S1 D4
    {(gpio_num_t)PIN_U3_HIGH, MASK_U3_HIGH}, // I2S1 D5
};

static inline uint8_t lanes_from_gpio_mask(uint32_t gpio_mask) {
    uint8_t bits = 0;
    for (int k = 0; k < 6; ++k) {
        if (gpio_mask & k_lanes[k].gpio_mask) {
            bits |= (uint8_t)(1u << k);
        }
    }
    return bits;
}

// ---------------------------------------------------------------------------
// Engine state
// ---------------------------------------------------------------------------
struct DmaChain {
    lldesc_t desc[DMA_DESC_COUNT];
    uint32_t count;
};

static DmaChain s_chain[2];
static uint8_t *s_buf[2] = {nullptr, nullptr};
static TaskHandle_t s_dma_task = nullptr;
static intr_handle_t s_intr = nullptr;
static std::atomic<bool> s_dma_active(false);

// ISR <-> task shared state.
static volatile lldesc_t *s_tail_desc[2] = {nullptr, nullptr};
static volatile bool s_hw_fault = false;
static volatile int s_isr_tail_chain = 0;
static volatile uint32_t s_trigger_cycles = 0;
static volatile uint32_t s_prev_tail_cycles = 0;
static volatile uint32_t s_pass_period_cycles = 0;
static volatile uint32_t s_pass_count = 0;

// Telemetry (written by the control task).
static volatile uint32_t s_missed_control_updates = 0;
static volatile uint32_t s_fault_count = 0;
static volatile uint32_t s_clamped_segments = 0;
static volatile uint32_t s_render_us = 0;
static volatile uint32_t s_ctl_us = 0;
static volatile int32_t s_commit_margin_us = 0;
static volatile uint32_t s_copies = 1;
static volatile uint32_t s_buf_len = 0;
static volatile uint32_t s_step_count = 0;
static volatile float s_req_cycle_us = 0.0f;

// ---------------------------------------------------------------------------
// Bitstream renderer (D5, D10)
// ---------------------------------------------------------------------------

// Stream byte j must be stored at buf[j ^ 2] (I2S TX FIFO word order 2,3,0,1).
// For runs of one value whole 32-bit words are order-independent, so the
// middle of a run is filled word-wise.
static void fill_run(uint8_t *buf, size_t pos, size_t count, uint8_t value) {
    size_t end = pos + count;
    while (pos < end && (pos & 3)) {
        buf[pos ^ 2] = value;
        pos++;
    }
    if (pos + 4 <= end) {
        const uint32_t word = value * 0x01010101u;
        uint32_t *w = (uint32_t *)(buf + pos);
        size_t words = (end - pos) / 4;
        for (size_t k = 0; k < words; ++k) {
            w[k] = word;
        }
        pos += words * 4;
    }
    while (pos < end) {
        buf[pos ^ 2] = value;
        pos++;
    }
}

size_t signal_render_bitstream(const DataSet *ds, const int32_t *corrections,
                               uint32_t copies, uint8_t *buf, size_t capacity,
                               DmaRenderStats *stats) {
    if (ds == nullptr || ds->size == 0 || buf == nullptr || copies == 0) {
        return 0;
    }

    const uint32_t n = ds->size;

    // Per-step derivation from the single-sourced SignalStep semantics.
    uint8_t state[MAX_SIGNAL_SIZE];
    uint8_t changing[MAX_SIGNAL_SIZE];
    uint32_t dur[MAX_SIGNAL_SIZE];
    uint32_t dead[MAX_SIGNAL_SIZE];

    // Commanded dead time in samples. The CPU engine's cycle-compensated
    // values embed software overhead that does not exist under DMA (D10).
    const uint32_t dead_samples =
        g_dead_time_tenths_us * SIGNAL_DMA_SAMPLES_PER_TICK;

    uint32_t cycle_samples = 0;
    for (uint32_t i = 0; i < n; ++i) {
        const SignalStep &step = ds->steps[i];
        state[i] = lanes_from_gpio_mask(step.set_mask);
        changing[i] = lanes_from_gpio_mask(step.clear_mask);
        dead[i] = changing[i] ? dead_samples : 0;

        int32_t ticks = (int32_t)step.duration_ticks;
        if (corrections != nullptr) {
            ticks += corrections[i];
        }
        if (ticks < 1) {
            ticks = 1;
        }
        dur[i] = (uint32_t)ticks * SIGNAL_DMA_SAMPLES_PER_TICK;
        cycle_samples += dur[i];
    }

    const int32_t trim_up = g_dma_edge_trim_up_samples;
    const int32_t trim_down = g_dma_edge_trim_down_samples;

    uint32_t clamped = 0;
    uint32_t faults = 0;
    size_t pos = 0;
    uint8_t last_byte = state[n - 1];

    for (uint32_t c = 0; c < copies; ++c) {
        for (uint32_t i = 0; i < n; ++i) {
            const uint32_t j = (i + 1) % n;
            // Boundary trim (reserved, D10): a positive trim moves the
            // boundary earlier, so segment i loses trim_j samples and gains
            // trim_i at its own boundary. Trims cancel over the full cycle.
            const int32_t trim_i =
                changing[i] ? (ds->steps[i].is_rising ? trim_up : trim_down)
                            : 0;
            const int32_t trim_j =
                changing[j] ? (ds->steps[j].is_rising ? trim_up : trim_down)
                            : 0;

            int32_t active =
                (int32_t)dur[i] - (int32_t)dead[j] + trim_i - trim_j;
            if (active < (int32_t)DMA_MIN_ACTIVE_HOLD_SAMPLES) {
                active = (int32_t)DMA_MIN_ACTIVE_HOLD_SAMPLES;
                clamped++;
                faults++;
            }

            if (pos + (size_t)active + dead[j] > capacity) {
                return 0;
            }

            fill_run(buf, pos, (size_t)active, state[i]);
            pos += (size_t)active;
            last_byte = state[i];

            if (dead[j]) {
                // Shoot-through guard: both terminals of every changing
                // output group inactive during the dead-time window.
                const uint8_t dead_state = state[i] & (uint8_t)~changing[j];
                fill_run(buf, pos, dead[j], dead_state);
                pos += dead[j];
                last_byte = dead_state;
            }
        }
    }

    // The DMA FIFO consumes whole 32-bit words. Copies are chosen so the
    // nominal length is word-aligned; clamping can break that, which is
    // already a timing fault — pad with the final state to realign.
    while (pos & 3) {
        if (pos >= capacity) {
            return 0;
        }
        buf[pos ^ 2] = last_byte;
        pos++;
        faults++;
    }

    if (stats != nullptr) {
        stats->cycle_samples = cycle_samples;
        stats->copies = copies;
        stats->clamped_segments = clamped;
        stats->timing_faults = faults;
    }
    return pos;
}

// ---------------------------------------------------------------------------
// Descriptor chains
// ---------------------------------------------------------------------------

// Builds the chain for buffer b: [0, trigger_off) then [trigger_off, len),
// with EOF flags on the control-trigger descriptor and on the tail. The tail
// links back to the chain head, so a missed relink replays the same buffer
// (Missed Control Update, zero timing disturbance).
static bool chain_build(int b, size_t len, size_t trigger_off) {
    DmaChain &c = s_chain[b];
    uint32_t di = 0;
    size_t pos = 0;

    auto add_region = [&](size_t end) -> bool {
        while (pos < end) {
            if (di >= DMA_DESC_COUNT) {
                return false;
            }
            size_t chunk = end - pos;
            if (chunk > DMA_DESC_MAX_BYTES) {
                chunk = DMA_DESC_MAX_BYTES;
            }
            lldesc_t &d = c.desc[di];
            d.size = chunk;
            d.length = chunk;
            d.offset = 0;
            d.sosf = 0;
            d.eof = 0;
            d.owner = 1;
            d.buf = s_buf[b] + pos;
            if (di > 0) {
                c.desc[di - 1].qe.stqe_next = &d;
            }
            pos += chunk;
            di++;
        }
        c.desc[di - 1].eof = 1;
        return true;
    };

    if (trigger_off == 0 || trigger_off >= len) {
        return false;
    }
    if (!add_region(trigger_off) || !add_region(len)) {
        ESP_LOGE(TAG, "Descriptor chain overflow (len=%u)", (unsigned)len);
        return false;
    }

    c.count = di;
    c.desc[di - 1].qe.stqe_next = &c.desc[0]; // self-loop by default
    s_tail_desc[b] = &c.desc[di - 1];
    return true;
}

static void chain_self_loop(int b) {
    DmaChain &c = s_chain[b];
    ((volatile lldesc_t *)&c.desc[c.count - 1])->qe.stqe_next = &c.desc[0];
}

// Buffer-pass geometry: replicate short cycles to reach the pass floor, then
// keep the total length word-aligned (cycle samples are always even at 2
// samples/tick, so at most one doubling is needed).
static uint32_t dma_compute_copies(uint32_t cycle_samples) {
    uint32_t copies = 1;
    if (cycle_samples < DMA_MIN_PASS_SAMPLES) {
        copies = (DMA_MIN_PASS_SAMPLES + cycle_samples - 1) / cycle_samples;
    }
    if (((uint64_t)cycle_samples * copies) % 4 != 0) {
        copies *= 2;
    }
    return copies;
}

static size_t dma_trigger_offset(size_t len) {
    size_t lead = (size_t)DMA_CONTROL_LEAD_US * DMA_SAMPLES_PER_US;
    if (lead > len / 2) {
        lead = len / 2;
    }
    size_t off = (len - lead) & ~(size_t)3;
    if (off == 0) {
        off = 4;
    }
    return off;
}

// ---------------------------------------------------------------------------
// Safe state (D6): pins detach from the I2S matrix back to plain GPIO whose
// output latch is held LOW, so all six terminals go inactive no matter where
// the bitstream halted. Register-only, callable from the ISR.
// ---------------------------------------------------------------------------
static inline void dma_detach_pins(void) {
    for (int k = 0; k < 6; ++k) {
        GPIO.func_out_sel_cfg[k_lanes[k].pin].val = SIG_GPIO_OUT_IDX;
    }
}

static void dma_attach_pins(void) {
    for (int k = 0; k < 6; ++k) {
        const DmaLane &lane = k_lanes[k];
        // Route through the GPIO matrix (covers the GPIO23 IO_MUX quirk) and
        // park the GPIO latch LOW so a later detach lands all-off.
        gpio_ll_func_sel(&GPIO, lane.pin, PIN_FUNC_GPIO);
        GPIO.out_w1tc = lane.gpio_mask;
        esp_rom_gpio_connect_out_signal(lane.pin, I2S1O_DATA_OUT0_IDX + k,
                                        false, false);
    }
}

// ---------------------------------------------------------------------------
// I2S1 hardware
// ---------------------------------------------------------------------------
static void dma_i2s_init(void) {
    periph_module_enable(PERIPH_I2S1_MODULE);

    I2S1.conf.tx_reset = 1;
    I2S1.conf.tx_reset = 0;
    I2S1.conf.tx_fifo_reset = 1;
    I2S1.conf.tx_fifo_reset = 0;
    I2S1.lc_conf.out_rst = 1;
    I2S1.lc_conf.out_rst = 0;

    I2S1.conf.val = 0;

    // 8-bit LCD/parallel master TX; wrx2 makes one datum per sample clock.
    I2S1.conf2.val = 0;
    I2S1.conf2.lcd_en = 1;
    I2S1.conf2.lcd_tx_wrx2_en = 1;
    I2S1.conf2.lcd_tx_sdx2_en = 0;

    I2S1.sample_rate_conf.val = 0;
    I2S1.sample_rate_conf.tx_bits_mod = 8;
    I2S1.sample_rate_conf.rx_bits_mod = 8;
    I2S1.sample_rate_conf.tx_bck_div_num = 4;
    I2S1.sample_rate_conf.rx_bck_div_num = 4;

    // Sample clock (D2): 80 MHz / DMA_CLKM_DIV_NUM, integer divider only.
    I2S1.clkm_conf.val = 0;
    I2S1.clkm_conf.clka_en = 0;
    I2S1.clkm_conf.clkm_div_a = 1;
    I2S1.clkm_conf.clkm_div_b = 0;
    I2S1.clkm_conf.clkm_div_num = DMA_CLKM_DIV_NUM;
    I2S1.clkm_conf.clk_en = 1;

    I2S1.fifo_conf.val = 0;
    I2S1.fifo_conf.tx_fifo_mod_force_en = 1;
    I2S1.fifo_conf.rx_fifo_mod_force_en = 1;
    I2S1.fifo_conf.tx_fifo_mod = 1;
    I2S1.fifo_conf.rx_fifo_mod = 1;
    I2S1.fifo_conf.tx_data_num = 32;
    I2S1.fifo_conf.rx_data_num = 32;
    I2S1.fifo_conf.dscr_en = 1;

    I2S1.conf_chan.val = 0;
    I2S1.conf_chan.tx_chan_mod = 1;
    I2S1.conf_chan.rx_chan_mod = 1;

    I2S1.conf1.val = 0;
    I2S1.conf1.tx_pcm_bypass = 1;
    I2S1.conf1.tx_stop_en = 0;

    I2S1.timing.val = 0;

    I2S1.int_ena.val = 0;
    I2S1.int_clr.val = 0xFFFFFFFF;
}

static void IRAM_ATTR dma_isr(void *arg) {
    decltype(I2S1.int_st) st;
    st.val = I2S1.int_st.val;
    I2S1.int_clr.val = st.val;

    BaseType_t hpw = pdFALSE;
    uint32_t bits = 0;

    if (st.out_dscr_err) {
        // Unrecoverable Timing Fault: force the safe state immediately,
        // mid-cycle (D6), before anything else.
        dma_detach_pins();
        I2S1.conf.tx_start = 0;
        s_hw_fault = true;
        bits |= NOTIF_FAULT;
    } else if (st.out_eof) {
        lldesc_t *d = (lldesc_t *)I2S1.out_eof_des_addr;
        const uint32_t now = esp_cpu_get_cycle_count();
        if (d == s_tail_desc[0] || d == s_tail_desc[1]) {
            s_isr_tail_chain = (d == s_tail_desc[1]) ? 1 : 0;
            if (s_prev_tail_cycles != 0) {
                s_pass_period_cycles = now - s_prev_tail_cycles;
            }
            s_prev_tail_cycles = now;
            s_pass_count = s_pass_count + 1;
            bits |= NOTIF_TAIL;
        } else {
            s_trigger_cycles = now;
            bits |= NOTIF_TRIGGER;
        }
    }

    if (bits != 0 && s_dma_task != nullptr) {
        xTaskNotifyFromISR(s_dma_task, bits, eSetBits, &hpw);
    }
    if (hpw == pdTRUE) {
        portYIELD_FROM_ISR();
    }
}

static void dma_hw_start(int active) {
    dma_i2s_init();
    dma_attach_pins();

    I2S1.lc_conf.out_data_burst_en = 1;
    I2S1.lc_conf.outdscr_burst_en = 1;

    I2S1.out_link.addr = ((uint32_t)&s_chain[active].desc[0]) & 0xFFFFF;
    I2S1.int_clr.val = 0xFFFFFFFF;
    I2S1.int_ena.out_eof = 1;
    I2S1.int_ena.out_dscr_err = 1;
    I2S1.out_link.start = 1;
    I2S1.conf.tx_start = 1;
}

static void dma_hw_stop(void) {
    // D6 ordering: pins first (deterministic all-off), then DMA teardown.
    dma_detach_pins();
    I2S1.int_ena.val = 0;
    I2S1.conf.tx_start = 0;
    I2S1.out_link.stop = 1;
    I2S1.conf.tx_reset = 1;
    I2S1.conf.tx_reset = 0;
    I2S1.conf.tx_fifo_reset = 1;
    I2S1.conf.tx_fifo_reset = 0;
    I2S1.lc_conf.out_rst = 1;
    I2S1.lc_conf.out_rst = 0;
    periph_module_disable(PERIPH_I2S1_MODULE);
}

// ---------------------------------------------------------------------------
// Render + commit (D4): rebuild the inactive buffer, then relink the active
// tail with one atomic pointer write before the pass boundary latches it.
// ---------------------------------------------------------------------------
static bool dma_render_and_commit(const DataSet *ds, const int32_t *corr,
                                  int active) {
    const int inactive = 1 - active;

    const uint32_t t0 = esp_cpu_get_cycle_count();
    uint32_t nominal = 0;
    for (uint32_t i = 0; i < ds->size; ++i) {
        nominal += ds->steps[i].duration_ticks;
    }
    const uint32_t copies =
        dma_compute_copies(nominal * SIGNAL_DMA_SAMPLES_PER_TICK);

    DmaRenderStats rs;
    const size_t len = signal_render_bitstream(
        ds, corr, copies, s_buf[inactive], DMA_MAX_BUFFER_BYTES, &rs);
    if (len == 0) {
        return false;
    }
    if (!chain_build(inactive, len, dma_trigger_offset(len))) {
        return false;
    }
    const uint32_t t1 = esp_cpu_get_cycle_count();

    s_render_us = (t1 - t0) / CYCLES_PER_US;
    s_clamped_segments += rs.clamped_segments;
    s_fault_count += rs.timing_faults;
    s_copies = copies;
    s_buf_len = (uint32_t)len;
    s_step_count = ds->size;
    s_req_cycle_us = (float)rs.cycle_samples / (float)DMA_SAMPLES_PER_US;

    // Correction commit (D4): one atomic pointer write.
    ((volatile lldesc_t *)s_tail_desc[active])->qe.stqe_next =
        &s_chain[inactive].desc[0];

    const uint32_t commit = esp_cpu_get_cycle_count();
    s_ctl_us = (commit - s_trigger_cycles) / CYCLES_PER_US;
    if (s_pass_period_cycles != 0) {
        const uint32_t expected_tail =
            s_prev_tail_cycles + s_pass_period_cycles;
        s_commit_margin_us =
            (int32_t)(expected_tail - commit) / (int32_t)CYCLES_PER_US;
    }
    return true;
}

// ---------------------------------------------------------------------------
// Control task (D3): normal-priority, watchdog-covered, on Core 1.
// ---------------------------------------------------------------------------
static void dma_control_task(void *arg) {
    static SignalControlContext ctl;
    ctl.dataset = get_dataset_active();
    signal_control_reset(ctl);

    ESP_LOGI(TAG, "DMA engine task started on Core %d (sample clock %lu Hz)",
             xPortGetCoreID(), (unsigned long)SIGNAL_DMA_SAMPLE_RATE_HZ);

    // Allocate the interrupt here so it is serviced on this core.
    esp_err_t err = esp_intr_alloc(ETS_I2S1_INTR_SOURCE, ESP_INTR_FLAG_IRAM,
                                   dma_isr, nullptr, &s_intr);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_intr_alloc failed: %d", (int)err);
        s_dma_active.store(false, std::memory_order_release);
        g_system_state.signal_state.store(SignalState::IDLE,
                                          std::memory_order_release);
        s_dma_task = nullptr;
        vTaskDelete(NULL);
        return;
    }

    const bool wdt_added = (esp_task_wdt_add(NULL) == ESP_OK);

    dma_hw_start(0);
    led_on();

    int active = 0;
    bool pending_flip = false;
    int flip_target = 0;
    uint32_t tails_since_commit = 0;
    bool prev_control = false;
    bool fault_exit = false;

    for (;;) {
        uint32_t notif = 0;
        const BaseType_t got =
            xTaskNotifyWait(0, ULONG_MAX, &notif, pdMS_TO_TICKS(100));
        if (wdt_added) {
            esp_task_wdt_reset();
        }

        if (s_hw_fault) {
            ESP_LOGE(TAG, "Unrecoverable Timing Fault: DMA descriptor error");
            s_fault_count = s_fault_count + 1;
            fault_exit = true;
            break;
        }

        if (got == pdFALSE) {
            // Watchdog tick: no EOF in 100 ms. Honour a stop request even if
            // the hardware stopped signalling.
            if (!signal_is_running_dma_check()) {
                break;
            }
            continue;
        }

        if (notif & NOTIF_TAIL) {
            if (pending_flip) {
                tails_since_commit++;
                if (s_isr_tail_chain == flip_target) {
                    const int old = active;
                    active = flip_target;
                    chain_self_loop(old);
                    pending_flip = false;
                } else if (tails_since_commit >= 2) {
                    // The old buffer replayed past the latch boundary.
                    s_missed_control_updates = s_missed_control_updates + 1;
                }
            }
            signal_trigger_periodic_analog_read();
            if (!signal_is_running_dma_check()) {
                // Graceful stop at the pass boundary (D6).
                break;
            }
        }

        if ((notif & NOTIF_TRIGGER) && !pending_flip &&
            signal_is_running_dma_check()) {
            // Control Point (D3): measurement, correction, render, relink.
            bool need_render = false;
            const int32_t *corr = nullptr;

            if (g_ds_update_pending.load(std::memory_order_acquire)) {
                const DataSet *next_ds =
                    (g_active_set.load(std::memory_order_relaxed) ==
                     SignalSet::SET_A)
                        ? &g_dataset_b
                        : &g_dataset_a;
                ctl.dataset = next_ds;
                signal_control_reset(ctl);
                if (g_active_set.load(std::memory_order_relaxed) ==
                    SignalSet::SET_A) {
                    g_active_set.store(SignalSet::SET_B,
                                       std::memory_order_relaxed);
                } else {
                    g_active_set.store(SignalSet::SET_A,
                                       std::memory_order_relaxed);
                }
                g_ds_update_pending.store(false, std::memory_order_release);
                need_render = true;
            }

            const bool control =
                g_control_enabled.load(std::memory_order_acquire);
            if (control) {
                if (signal_control_update_corrections(ctl)) {
                    corr = ctl.current_correction;
                    need_render = true;
                }
            } else if (prev_control) {
                // Control switched off: return to the nominal pattern.
                need_render = true;
            }
            prev_control = control;

            if (need_render) {
                if (dma_render_and_commit(ctl.dataset, corr, active)) {
                    pending_flip = true;
                    flip_target = 1 - active;
                    tails_since_commit = 0;
                } else {
                    ESP_LOGE(TAG,
                             "Bitstream render failed; keeping current cycle");
                    s_fault_count = s_fault_count + 1;
                }
            }
        }
    }

    dma_hw_stop();
    if (s_intr != nullptr) {
        esp_intr_free(s_intr);
        s_intr = nullptr;
    }
    if (wdt_added) {
        esp_task_wdt_delete(NULL);
    }
    if (fault_exit) {
        // Enter the safe stopped state through the shared path.
        if (g_system_state.signal_state.load(std::memory_order_acquire) ==
            SignalState::RUNNING) {
            signal_stop();
        }
    }

    heap_caps_free(s_buf[0]);
    heap_caps_free(s_buf[1]);
    s_buf[0] = nullptr;
    s_buf[1] = nullptr;
    s_tail_desc[0] = nullptr;
    s_tail_desc[1] = nullptr;

    led_off();
    ESP_LOGI(TAG, "DMA engine stopped (%s)",
             fault_exit ? "timing fault" : "commanded");
    s_dma_task = nullptr;
    s_dma_active.store(false, std::memory_order_release);
    vTaskDelete(NULL);
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------
bool signal_dma_engine_is_active() {
    return s_dma_active.load(std::memory_order_acquire);
}

bool signal_dma_engine_start() {
    if (s_dma_active.load(std::memory_order_acquire)) {
        ESP_LOGW(TAG, "DMA engine already active");
        return false;
    }

    const DataSet *ds = get_dataset_active();
    if (ds == nullptr || ds->size == 0) {
        ESP_LOGE(TAG, "No dataset to play");
        return false;
    }

    uint32_t nominal_ticks = 0;
    for (uint32_t i = 0; i < ds->size; ++i) {
        nominal_ticks += ds->steps[i].duration_ticks;
    }
    const uint32_t cycle_samples = nominal_ticks * SIGNAL_DMA_SAMPLES_PER_TICK;
    const uint32_t copies = dma_compute_copies(cycle_samples);
    if ((uint64_t)cycle_samples * copies + 64 > DMA_MAX_BUFFER_BYTES) {
        ESP_LOGE(TAG,
                 "Pattern too long for DMA engine: %lu samples x%lu copies "
                 "exceeds %u bytes — use the CPU engine",
                 (unsigned long)cycle_samples, (unsigned long)copies,
                 (unsigned)DMA_MAX_BUFFER_BYTES);
        return false;
    }

    for (int b = 0; b < 2; ++b) {
        s_buf[b] = (uint8_t *)heap_caps_malloc(DMA_MAX_BUFFER_BYTES,
                                               MALLOC_CAP_DMA);
        if (s_buf[b] == nullptr) {
            ESP_LOGE(TAG, "DMA buffer allocation failed");
            heap_caps_free(s_buf[0]);
            s_buf[0] = nullptr;
            s_buf[1] = nullptr;
            return false;
        }
    }

    DmaRenderStats rs;
    const size_t len = signal_render_bitstream(ds, nullptr, copies, s_buf[0],
                                               DMA_MAX_BUFFER_BYTES, &rs);
    if (len == 0 || !chain_build(0, len, dma_trigger_offset(len))) {
        ESP_LOGE(TAG, "Initial bitstream render failed");
        heap_caps_free(s_buf[0]);
        heap_caps_free(s_buf[1]);
        s_buf[0] = nullptr;
        s_buf[1] = nullptr;
        return false;
    }

    // Reset telemetry and ISR state.
    s_hw_fault = false;
    s_prev_tail_cycles = 0;
    s_pass_period_cycles = 0;
    s_pass_count = 0;
    s_missed_control_updates = 0;
    s_fault_count = rs.timing_faults;
    s_clamped_segments = rs.clamped_segments;
    s_render_us = 0;
    s_ctl_us = 0;
    s_commit_margin_us = 0;
    s_copies = copies;
    s_buf_len = (uint32_t)len;
    s_step_count = ds->size;
    s_req_cycle_us = (float)rs.cycle_samples / (float)DMA_SAMPLES_PER_US;
    s_tail_desc[1] = nullptr;

    s_dma_active.store(true, std::memory_order_release);
    g_system_state.signal_state.store(SignalState::RUNNING,
                                      std::memory_order_release);

    if (xTaskCreatePinnedToCore(dma_control_task, "sig_dma", 6144, NULL, 10,
                                &s_dma_task, CORE_1) != pdPASS) {
        ESP_LOGE(TAG, "Failed to create DMA control task");
        g_system_state.signal_state.store(SignalState::IDLE,
                                          std::memory_order_release);
        s_dma_active.store(false, std::memory_order_release);
        heap_caps_free(s_buf[0]);
        heap_caps_free(s_buf[1]);
        s_buf[0] = nullptr;
        s_buf[1] = nullptr;
        return false;
    }

    ESP_LOGI(TAG,
             "DMA engine started: cycle=%.1f us, copies=%lu, buffer=%u bytes",
             (double)s_req_cycle_us, (unsigned long)copies, (unsigned)len);
    return true;
}

void signal_dma_get_timing_core(uint32_t *passes, float *requested_cycle_us,
                                float *measured_cycle_us,
                                uint32_t *missed_control_updates,
                                uint32_t *timing_faults) {
    const uint32_t copies = s_copies != 0 ? s_copies : 1;
    if (passes != nullptr) {
        *passes = s_pass_count;
    }
    if (requested_cycle_us != nullptr) {
        *requested_cycle_us = s_req_cycle_us;
    }
    if (measured_cycle_us != nullptr) {
        *measured_cycle_us =
            (float)s_pass_period_cycles / (float)(CYCLES_PER_US * copies);
    }
    if (missed_control_updates != nullptr) {
        *missed_control_updates = s_missed_control_updates;
    }
    if (timing_faults != nullptr) {
        *timing_faults = s_fault_count;
    }
}

std::string signal_dma_timing_fields_json(void) {
    char json[256];
    snprintf(json, sizeof(json),
             "\"render\":%lu,\"ctl\":%lu,\"margin\":%ld,"
             "\"tf\":%lu,\"cl\":%lu,\"copies\":%lu,\"buf\":%lu,"
             "\"trim_up\":%ld,\"trim_down\":%ld,\"steps\":%lu",
             (unsigned long)s_render_us, (unsigned long)s_ctl_us,
             (long)s_commit_margin_us, (unsigned long)s_fault_count,
             (unsigned long)s_clamped_segments, (unsigned long)s_copies,
             (unsigned long)s_buf_len, (long)g_dma_edge_trim_up_samples,
             (long)g_dma_edge_trim_down_samples,
             (unsigned long)s_step_count);
    return std::string(json);
}
