#include "signal_controller.h"
#include "helper_datasetter.h"
#include "control_action.h"
#include "soc/io_mux_reg.h"
#include "hal/gpio_ll.h"
#include <cstdio>

static const char *TAG = "SIG_CTRL";
static constexpr uint32_t CYCLES_PER_US = 240;
static constexpr uint32_t MIN_ACTIVE_HOLD_CYCLES = CYCLES_PER_US;
static constexpr uint32_t MIN_MAINTENANCE_PERIOD_CYCLES = 50 * CYCLES_PER_US;
static constexpr uint32_t SHORT_PATTERN_BATCH_CYCLES = 256;

// ---------------------------------------------------------------------------
// HARDWARE CONFIGURATION
// ---------------------------------------------------------------------------
const uint32_t MASK_U1_LOW  = (1U << PIN_U1_LOW);
const uint32_t MASK_U1_HIGH = (1U << PIN_U1_HIGH);
const uint32_t MASK_U2_LOW  = (1U << PIN_U2_LOW);
const uint32_t MASK_U2_HIGH = (1U << PIN_U2_HIGH);
const uint32_t MASK_U3_LOW  = (1U << PIN_U3_LOW);
const uint32_t MASK_U3_HIGH = (1U << PIN_U3_HIGH);

const uint32_t MASK_OUT_SIG = (1U << PIN_OUT_SIG);

static TaskHandle_t s_signal_task_handle = NULL;

struct SignalTimingSample {
    uint32_t expected_cycles = 0;
    uint32_t requested_period_cycles = 0;
    uint32_t scheduled_period_cycles = 0;
    uint32_t measured_period_cycles = 0;
    uint32_t dead_time_cycles = 0;
    uint32_t step_count = 0;
    uint32_t overrun_count = 0;
    uint32_t timing_fault_count = 0;
    uint32_t clamped_segment_count = 0;
    uint32_t maintenance_skipped_count = 0;
    int32_t correction_sum_us = 0;
};

static volatile uint32_t s_timing_sample_count = 0;
static volatile uint32_t s_timing_playback_cycles = 0;
static volatile uint32_t s_timing_playback_min_cycles = 0;
static volatile uint32_t s_timing_playback_max_cycles = 0;
static volatile uint32_t s_timing_playback_avg_cycles = 0;
static volatile uint32_t s_timing_loop_cycles = 0;
static volatile uint32_t s_timing_expected_cycles = 0;
static volatile uint32_t s_timing_requested_period_cycles = 0;
static volatile uint32_t s_timing_scheduled_period_cycles = 0;
static volatile uint32_t s_timing_measured_period_cycles = 0;
static volatile uint32_t s_timing_dead_time_cycles = 0;
static volatile uint32_t s_timing_step_count = 0;
static volatile uint32_t s_timing_overrun_count = 0;
static volatile uint32_t s_timing_fault_count = 0;
static volatile uint32_t s_timing_clamped_segment_count = 0;
static volatile uint32_t s_timing_maintenance_skipped_count = 0;
static volatile int32_t s_timing_correction_sum_us = 0;

static void update_signal_timing_snapshot(uint32_t playback_cycles,
                                          uint32_t loop_cycles,
                                          const SignalTimingSample &sample) {
    const uint32_t count = s_timing_sample_count + 1;
    s_timing_sample_count = count;
    s_timing_playback_cycles = playback_cycles;
    s_timing_loop_cycles = loop_cycles;
    s_timing_expected_cycles = sample.expected_cycles;
    s_timing_requested_period_cycles = sample.requested_period_cycles;
    s_timing_scheduled_period_cycles = sample.scheduled_period_cycles;
    s_timing_measured_period_cycles = sample.measured_period_cycles;
    s_timing_dead_time_cycles = sample.dead_time_cycles;
    s_timing_step_count = sample.step_count;
    s_timing_overrun_count += sample.overrun_count;
    s_timing_fault_count += sample.timing_fault_count;
    s_timing_clamped_segment_count += sample.clamped_segment_count;
    s_timing_maintenance_skipped_count += sample.maintenance_skipped_count;
    s_timing_correction_sum_us = sample.correction_sum_us;

    if (count == 1 || playback_cycles < s_timing_playback_min_cycles) {
        s_timing_playback_min_cycles = playback_cycles;
    }
    if (playback_cycles > s_timing_playback_max_cycles) {
        s_timing_playback_max_cycles = playback_cycles;
    }
    if (count == 1) {
        s_timing_playback_avg_cycles = playback_cycles;
    } else {
        s_timing_playback_avg_cycles =
            ((s_timing_playback_avg_cycles * 7U) + playback_cycles) / 8U;
    }
}

std::string signal_get_timing_snapshot_json() {
    const uint32_t sample_count = s_timing_sample_count;
    const uint32_t playback_cycles = s_timing_playback_cycles;
    const uint32_t playback_min_cycles = s_timing_playback_min_cycles;
    const uint32_t playback_max_cycles = s_timing_playback_max_cycles;
    const uint32_t playback_avg_cycles = s_timing_playback_avg_cycles;
    const uint32_t loop_cycles = s_timing_loop_cycles;
    const uint32_t expected_cycles = s_timing_expected_cycles;
    const uint32_t requested_period_cycles = s_timing_requested_period_cycles;
    const uint32_t scheduled_period_cycles = s_timing_scheduled_period_cycles;
    const uint32_t measured_period_cycles = s_timing_measured_period_cycles;
    const uint32_t dead_time_cycles = s_timing_dead_time_cycles;
    const uint32_t step_count = s_timing_step_count;
    const uint32_t overrun_count = s_timing_overrun_count;
    const uint32_t timing_fault_count = s_timing_fault_count;
    const uint32_t clamped_segment_count = s_timing_clamped_segment_count;
    const uint32_t maintenance_skipped_count = s_timing_maintenance_skipped_count;
    const int32_t correction_sum_us = s_timing_correction_sum_us;
    const int32_t overhead_cycles =
        (int32_t)playback_cycles - (int32_t)expected_cycles;

    char json[320];
    snprintf(json, sizeof(json),
             "{\"s\":%lu,"
             "\"pb\":%.2f,\"pmin\":%.2f,\"pmax\":%.2f,\"pavg\":%.2f,"
             "\"loop\":%.2f,\"exp\":%.2f,"
             "\"req\":%.2f,\"sch\":%.2f,\"meas\":%.2f,"
             "\"oh\":%.2f,\"dt\":%.2f,"
             "\"ov\":%lu,\"tf\":%lu,\"cl\":%lu,\"ms\":%lu,"
             "\"corr\":%ld,\"steps\":%lu}",
             sample_count,
             (double)playback_cycles / CYCLES_PER_US,
             (double)playback_min_cycles / CYCLES_PER_US,
             (double)playback_max_cycles / CYCLES_PER_US,
             (double)playback_avg_cycles / CYCLES_PER_US,
             (double)loop_cycles / CYCLES_PER_US,
             (double)expected_cycles / CYCLES_PER_US,
             (double)requested_period_cycles / CYCLES_PER_US,
             (double)scheduled_period_cycles / CYCLES_PER_US,
             (double)measured_period_cycles / CYCLES_PER_US,
             (double)overhead_cycles / CYCLES_PER_US,
             (double)dead_time_cycles / CYCLES_PER_US,
             overrun_count, timing_fault_count,
             clamped_segment_count, maintenance_skipped_count,
             correction_sum_us, step_count);
    return std::string(json);
}


// ---------------------------------------------------------------------------
// DOUBLE BUFFERING DATA
// ---------------------------------------------------------------------------

DataSet g_dataset_a;
DataSet g_dataset_b;

volatile uint32_t g_cycle_count = 0;
volatile uint32_t g_cycle_nrun = 10000;

// Track which set is currently active in the loop
std::atomic<SignalSet> g_active_set(SignalSet::SET_A);

// Flag to tell the loop that the OTHER set has new data and we should swap
std::atomic<bool> g_ds_update_pending(false);

// delay -> cycle 1/240mhz = 1/240 ~= 4.166 ns
// volatile uint32_t g_dead_time_cycles_up = 215;
// volatile uint32_t g_dead_time_cycles_down = 215;

volatile uint32_t g_dead_time_cycles_up = 215 + 215;
volatile uint32_t g_dead_time_cycles_down = 215 + 215;


/**
 * @brief Pre-calculates register masks and timing data for a signal pattern.
 * 
 * This function translates high-level signal modes into raw hardware masks.
 * By doing this on Core 0 (during pattern updates), we eliminate all conditional 
 * logic and bitwise operations from the high-speed execution loop on Core 1.
 */
void signal_precompute_steps(DataSet *ds) {
    if (ds->size == 0) return;

    // Track state transitions between segments.
    // To handle continuous looping, we seed the "previous" state with the last segment.
    uint32_t last_d6 = ds->modes_d6[ds->size - 1] ? 1 : 0;
    uint32_t last_d5 = ds->modes_d5[ds->size - 1] ? 1 : 0;
    uint32_t last_d4 = ds->modes_d4[ds->size - 1] ? 1 : 0;

    uint32_t total_us = 0;
    for (uint32_t i = 0; i < ds->size; i++) {
        uint32_t d6 = ds->modes_d6[i] ? 1 : 0;
        uint32_t d5 = ds->modes_d5[i] ? 1 : 0;
        uint32_t d4 = ds->modes_d4[i] ? 1 : 0;

        // Detect which GPIOs are changing state to apply dead-time
        bool change_6 = (d6 != last_d6);
        bool change_5 = (d5 != last_d5);
        bool change_4 = (d4 != last_d4);

        // clear_mask: Bits to set to 0 before the transition (to prevent shoot-through)
        uint32_t clear_mask = 0;
        if (change_6) clear_mask |= (MASK_U1_LOW | MASK_U1_HIGH);
        if (change_5) clear_mask |= (MASK_U2_LOW | MASK_U2_HIGH);
        if (change_4) clear_mask |= (MASK_U3_LOW | MASK_U3_HIGH);

        ds->steps[i].clear_mask = clear_mask;

        // set_mask: Bits to set to 1 for the target state
        ds->steps[i].set_mask = (d6 ? MASK_U1_HIGH : MASK_U1_LOW)
                              | (d5 ? MASK_U2_HIGH : MASK_U2_LOW)
                              | (d4 ? MASK_U3_HIGH : MASK_U3_LOW);

        // clr_mask: Bits to set to 0 for the target state
        ds->steps[i].clr_mask = (d6 ? MASK_U1_LOW  : MASK_U1_HIGH)
                              | (d5 ? MASK_U2_LOW  : MASK_U2_HIGH)
                              | (d4 ? MASK_U3_LOW  : MASK_U3_HIGH);
        
        // Determine if this is a rising edge (turn-on) vs falling edge for dead-time tuning
        bool is_rising = (change_6 && d6) || (change_5 && d5) || (change_4 && d4);
        ds->steps[i].dead_time = is_rising ? g_dead_time_cycles_up : g_dead_time_cycles_down;
        ds->steps[i].duration_us = ds->time_durations[i];
        ds->steps[i].duration_cycles = ds->steps[i].duration_us * CYCLES_PER_US;

        total_us += ds->steps[i].duration_us;

        last_d6 = d6;
        last_d5 = d5;
        last_d4 = d4;
    }

    // Safety Check: Avoid masking interrupts on Core 1 for more than 10ms.
    // Extremely long patterns could stall cross-core communication or hardware watchdogs.
    if (total_us > 10000) {
        ESP_LOGW(TAG, "LATENCY WARNING: Total pattern duration (%lu us) exceeds 10ms threshold!", total_us);
    }
}

// Helper to populate a default pattern (so datasets are never empty/invalid)
static void signal_init_default_dataset(DataSet &ds) {
    ds.time_durations[0] = 10;
    ds.time_durations[1] = 20;
    ds.time_durations[2] = 10;
    ds.time_durations[3] = 20;

    // Mode 7 (111)
    ds.modes_d6[0] = 1;
    ds.modes_d5[0] = 1;
    ds.modes_d4[0] = 1;
    // Mode 0 (000)
    ds.modes_d6[1] = 0;
    ds.modes_d5[1] = 0;
    ds.modes_d4[1] = 0;
    // Mode 7 (111)
    ds.modes_d6[2] = 1;
    ds.modes_d5[2] = 1;
    ds.modes_d4[2] = 1;
    // Mode 0 (000)
    ds.modes_d6[3] = 0;
    ds.modes_d5[3] = 0;
    ds.modes_d4[3] = 0;

    ds.size = 4;
    ds.alpha = NAN;
    signal_precompute_steps(&ds);
}

void signal_controller_init() {
    // 1. Configure GPIOs
    gpio_config_t io_conf = {};
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << PIN_U1_LOW) | (1ULL << PIN_U2_LOW) |
                           (1ULL << PIN_U3_LOW) | (1ULL << PIN_U1_HIGH) |
                           (1ULL << PIN_U2_HIGH) | (1ULL << PIN_U3_HIGH);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&io_conf);

    // Force IO_MUX back to GPIO matrix for PIN_U1_LOW (GPIO23).
    // The SPI flash driver claims GPIO23 at boot via the IO_MUX; this
    // re-routes it through the GPIO matrix so out_w1ts/out_w1tc work on it.
    gpio_ll_func_sel(&GPIO, PIN_U1_LOW, PIN_FUNC_GPIO);
    gpio_set_direction(PIN_U1_LOW, GPIO_MODE_OUTPUT);

    // Initialize LOW
    gpio_set_level(PIN_U1_LOW, 0);
    gpio_set_level(PIN_U2_LOW, 0);
    gpio_set_level(PIN_U3_LOW, 0);
    gpio_set_level(PIN_U1_HIGH, 0);
    gpio_set_level(PIN_U2_HIGH, 0);
    gpio_set_level(PIN_U3_HIGH, 0);
    gpio_set_level(PIN_OUT_SIG, 0);

    // 2. Populate Default Pattern into Set A and Set B
    signal_init_default_dataset(g_dataset_a);
    signal_init_default_dataset(g_dataset_b);

    // Ensure Set A is active initially
    g_active_set = SignalSet::SET_A;
    g_ds_update_pending = false;

    ESP_LOGI(TAG, "Signal Controller Initialized. Default Pattern Size: %d",
             g_dataset_a.size);
}

// ---------------------------------------------------------------------------
// DATA UPDATE LOGIC (Called from BLE Task)
// ---------------------------------------------------------------------------
void signal_update_from_string(const std::string &message) {

    // 1. Determine which dataset is INACTIVE (Safe to write to)
    DataSet *target_dataset = nullptr;
    SignalSet target_signalset;

    // We read the volatile variable once.
    // If Set A is active, we write to Set B.
    if (g_active_set == SignalSet::SET_A) {
        target_dataset = &g_dataset_b;
        target_signalset = SignalSet::SET_B;
    } else {
        target_dataset = &g_dataset_a;
        target_signalset = SignalSet::SET_A;
    }

    // 2. Parse the signal pattern payload
    std::vector<uint32_t> times;
    std::vector<uint32_t> modes;

    if (parse_signal(message, times, modes) != 1) {
        ESP_LOGE(TAG, "Failed to parse signal string");
        return;
    }

    // 3. Copy to Fixed Size Array
    size_t count = times.size();
    if (count > MAX_SIGNAL_SIZE) {
        ESP_LOGW(TAG, "Signal truncated! %d > %d", count, MAX_SIGNAL_SIZE);
        count = MAX_SIGNAL_SIZE;
    }

    for (size_t i = 0; i < count; i++) {
        target_dataset->time_durations[i] = times[i];
        uint32_t m = modes[i];
        target_dataset->modes_d4[i] = (m & 1) ? 1 : 0;
        target_dataset->modes_d5[i] = (m & 2) ? 1 : 0;
        target_dataset->modes_d6[i] = (m & 4) ? 1 : 0;
    }
    target_dataset->size = (uint8_t)count;
    target_dataset->alpha = NAN;

    // Pre-compute steps before requesting swap
    signal_precompute_steps(target_dataset);

    ESP_LOGI(TAG, "Parsed %d segments into %s. Requesting swap...",
             target_dataset->size,
             (target_signalset == SignalSet::SET_A ? "Set A" : "Set B"));

    // mark upadte pending
    g_ds_update_pending = true;
}

// ---------------------------------------------------------------------------
// CONTINUOUS LOOP TASK (High Priority)
// ---------------------------------------------------------------------------
struct SignalLoopContext {
    const DataSet *dataset = &g_dataset_a;
    int32_t current_correction[MAX_SIGNAL_SIZE];
    float dtk_buffer[MAX_SIGNAL_SIZE];
};

static bool signal_is_running() {
    return g_system_state.signal_state.load(std::memory_order_acquire) ==
           SignalState::RUNNING;
}

static void reset_control_corrections(SignalLoopContext &ctx) {
    for (int i = 0; i < MAX_SIGNAL_SIZE; ++i) {
        ctx.current_correction[i] = 0;
        ctx.dtk_buffer[i] = 0.0f;
    }
}

static void apply_pending_dataset_swap(SignalLoopContext &ctx) {
    if (!g_ds_update_pending.load(std::memory_order_acquire)) {
        return;
    }

    // The BLE task writes the inactive buffer, then sets this flag. Swap only
    // between complete pattern cycles so the playback loop never sees tearing.
    if (g_active_set.load(std::memory_order_relaxed) == SignalSet::SET_A) {
        ctx.dataset = &g_dataset_b;
        g_active_set.store(SignalSet::SET_B, std::memory_order_relaxed);
    } else {
        ctx.dataset = &g_dataset_a;
        g_active_set.store(SignalSet::SET_A, std::memory_order_relaxed);
    }

    g_ds_update_pending.store(false, std::memory_order_release);
    reset_control_corrections(ctx);
}

static void update_control_corrections(SignalLoopContext &ctx) {
    if (!g_control_enabled.load(std::memory_order_acquire) ||
        !g_adc_fresh.load(std::memory_order_acquire)) {
        return;
    }

    g_adc_fresh.store(false, std::memory_order_release);
    if (!ctx.dataset->gain_k.is_valid || ctx.dataset->size <= 1) {
        return;
    }

    const uint32_t N = ctx.dataset->size;
    const uint32_t p = N - 1;
    float an3 = g_adc_an3.load(std::memory_order_acquire);
    float an5 = g_adc_an5.load(std::memory_order_acquire);
    float an6 = g_adc_an6.load(std::memory_order_acquire);

    float e1 = an3 - ctx.dataset->target[0];
    float e2 = an5 - ctx.dataset->target[1];
    float e3 = an6 - ctx.dataset->target[2];

    uint32_t t0 = esp_cpu_get_cycle_count();
    const float *k_ptr = ctx.dataset->gain_k.values;
    const int cols = ctx.dataset->gain_k.cols;

    for (uint32_t j = 0; j < p; j++) {
        ctx.dtk_buffer[j] = -(k_ptr[j * cols + 0] * e1 +
                              k_ptr[j * cols + 1] * e2 +
                              k_ptr[j * cols + 2] * e3);
    }

    uint32_t t1 = esp_cpu_get_cycle_count();
    g_log_duration.matrix_multiply_us = (t1 - t0) / 240;

    condition_dtk(ctx.dtk_buffer, p, ctx.dataset->time_durations);
    compute_duration_corrections(ctx.dataset->time_durations, ctx.dtk_buffer,
                                 ctx.current_correction, p, N);
}

static inline void wait_until_cycle(uint32_t deadline) {
    while ((int32_t)(esp_cpu_get_cycle_count() - deadline) < 0) {
    }
}

static void execute_signal_pattern(const SignalLoopContext &ctx,
                                   SignalTimingSample &timing,
                                   uint32_t repeat_count) {
    // Keep the interrupt-disabled block limited to GPIO writes and exact delays.
    // No logging, allocation, parsing, or semaphore calls belong in this helper.
    portDISABLE_INTERRUPTS();

    uint8_t sz = ctx.dataset->size;
    timing = {};
    uint32_t pattern_start = esp_cpu_get_cycle_count();
    uint32_t next_edge = pattern_start;

    for (uint32_t repeat = 0; repeat < repeat_count; ++repeat) {
        for (int i = 0; i < sz; i++) {
            const SignalStep &step = ctx.dataset->steps[i];
            uint32_t cycles = step.duration_cycles;
            uint32_t dead_time = step.clear_mask ? step.dead_time : 0;
            if (repeat == 0) {
                timing.step_count++;
                timing.requested_period_cycles += step.duration_cycles;
            }

            if (g_control_enabled.load(std::memory_order_acquire)) {
                int32_t corrected = (int32_t)step.duration_us + ctx.current_correction[i];
                if (corrected < 1) corrected = 1;
                cycles = (uint32_t)corrected * CYCLES_PER_US;
                if (repeat == 0) {
                    timing.correction_sum_us += ctx.current_correction[i];
                }
            }

            const uint32_t minimum_cycles = dead_time + MIN_ACTIVE_HOLD_CYCLES;
            if (cycles < minimum_cycles) {
                cycles = minimum_cycles;
                if (repeat == 0) {
                    timing.timing_fault_count++;
                    timing.clamped_segment_count++;
                }
            }

            next_edge += cycles;
            if (repeat == 0) {
                timing.expected_cycles += cycles;
                timing.scheduled_period_cycles += cycles;
            }

            if (step.clear_mask) {
                GPIO.out_w1tc = step.clear_mask;
                helper_delay_cycles(dead_time);
                if (repeat == 0) {
                    timing.dead_time_cycles += dead_time;
                }
            }

            GPIO.out_w1tc = step.clr_mask;
            GPIO.out_w1ts = step.set_mask;

            uint32_t now = esp_cpu_get_cycle_count();
            if ((int32_t)(now - next_edge) > 0) {
                timing.overrun_count++;
            } else {
                wait_until_cycle(next_edge);
            }
        }
    }

    timing.measured_period_cycles =
        (esp_cpu_get_cycle_count() - pattern_start) / repeat_count;
    portENABLE_INTERRUPTS();
}

static void trigger_periodic_analog_read() {
    if (g_system_state.ble_an_read_state.load(std::memory_order_acquire) ==
        BLEAnalogReadState::DISABLED) {
        return;
    }

    g_cycle_count = (g_cycle_count + 1) % g_cycle_nrun;
    if (g_cycle_count == 0) {
        g_system_state.ble_an_read_state.store(BLEAnalogReadState::READING,
                                               std::memory_order_release);
        xSemaphoreGive(sem_analog_read_trigger);
    }
}

static uint32_t get_nominal_pattern_cycles(const SignalLoopContext &ctx) {
    uint32_t cycles = 0;
    uint8_t sz = ctx.dataset->size;
    for (int i = 0; i < sz; ++i) {
        cycles += ctx.dataset->steps[i].duration_cycles;
    }
    return cycles;
}

static void stop_signal_outputs() {
    portENABLE_INTERRUPTS();

    gpio_set_level(PIN_U1_LOW, 0);
    gpio_set_level(PIN_U2_LOW, 0);
    gpio_set_level(PIN_U3_LOW, 0);
    gpio_set_level(PIN_U1_HIGH, 0);
    gpio_set_level(PIN_U2_HIGH, 0);
    gpio_set_level(PIN_U3_HIGH, 0);
}

static void signal_loop_task(void *arg) {
    ESP_LOGI(TAG, "Continuous Signal Task Started on Core %d",
             xPortGetCoreID());

    static SignalLoopContext ctx;
    ctx.dataset = &g_dataset_a;
    reset_control_corrections(ctx);

    led_on();

    while (signal_is_running()) {
        uint32_t loop_start = esp_cpu_get_cycle_count();
        apply_pending_dataset_swap(ctx);
        update_control_corrections(ctx);
        SignalTimingSample timing;
        uint32_t playback_start = esp_cpu_get_cycle_count();
        const uint32_t nominal_cycles = get_nominal_pattern_cycles(ctx);
        const uint32_t repeat_count =
            nominal_cycles < MIN_MAINTENANCE_PERIOD_CYCLES
                ? SHORT_PATTERN_BATCH_CYCLES
                : 1;
        execute_signal_pattern(ctx, timing, repeat_count);
        uint32_t playback_cycles =
            (esp_cpu_get_cycle_count() - playback_start) / repeat_count;
        if (timing.scheduled_period_cycles >= MIN_MAINTENANCE_PERIOD_CYCLES) {
            trigger_periodic_analog_read();
        } else {
            timing.maintenance_skipped_count++;
        }
        uint32_t loop_cycles = esp_cpu_get_cycle_count() - loop_start;
        update_signal_timing_snapshot(playback_cycles, loop_cycles, timing);
    }

    stop_signal_outputs();

    led_off();

    s_signal_task_handle = NULL;
    vTaskDelete(NULL);
}

void signal_start_continuous() {
    if (g_system_state.signal_state.load(std::memory_order_acquire) == SignalState::RUNNING ||
        s_signal_task_handle != NULL) {
        ESP_LOGW(TAG, "Signal already running!");
        return;
    }

    if (g_dataset_a.size == 0) {
        ESP_LOGE(TAG, "Pattern empty, cannot start");
        return;
    }

    g_system_state.signal_state.store(SignalState::RUNNING, std::memory_order_release);

    // Pin to Core 1 (APP_CPU)
    xTaskCreatePinnedToCore(signal_loop_task, "sig_loop", 4096, NULL, 10,
                            &s_signal_task_handle, CORE_1);
}

void signal_stop() {
    if (g_system_state.signal_state == SignalState::IDLE) {
        ESP_LOGW(TAG, "Signal is not running");
        return;
    }

    ESP_LOGI(TAG, "Stopping Signal...");

    // updating signal when stop
    g_system_state.signal_state.store(SignalState::IDLE, std::memory_order_release);
    if (g_system_state.ble_an_read_state != BLEAnalogReadState::DISABLED) {
        g_system_state.ble_an_read_state = BLEAnalogReadState::IDLE;
    }
}

DataSet *get_dataset_active(void) {
    DataSet *dataset =
        (g_active_set == SignalSet::SET_A) ? &g_dataset_a : &g_dataset_b;
    return dataset;
}

// Placeholder for interface compatibility
void signal_execute_sequence(const uint16_t *durations, const uint8_t *modes,
                             int segment_count, int repeats) {}

void signal_set_alpha(float alpha) {
    DataSet *dataset;

    // We always update the INACTIVE set first to avoid tearing in the loop
    if (g_active_set == SignalSet::SET_A) {
        dataset = &g_dataset_b;
    } else {
        dataset = &g_dataset_a;
    }

    ESP_LOGI(TAG, "Initializing system with alpha=%.2f", alpha);
    helper_set_dataset_from_alpha(dataset, alpha);
    signal_precompute_steps(dataset);
    g_ds_update_pending.store(true, std::memory_order_release);
}
