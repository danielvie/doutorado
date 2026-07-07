#include "helper_analog.h"
#include <atomic>
#include <cstdint>
#include <cstring>
#include <cstdio>

#include "helper_common.h"
#include "signal_engine_dma.h"
#include "esp_adc/adc_continuous.h"
#include "esp_cpu.h"
#include "esp_rom_sys.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "soc/soc_caps.h"

#define LATENCY_WINDOW_SIZE 128
#define ANALOG_TARGET_TRIPLES_PER_CYCLE 4
#define ANALOG_ADC_MAX_CODE 4095
#define ADC_CONTINUOUS_FRAME_TRIPLES 4
#define ADC_CONTINUOUS_FRAME_SIZE (SOC_ADC_DIGI_RESULT_BYTES * 3 * ADC_CONTINUOUS_FRAME_TRIPLES)
#define ADC_CONTINUOUS_STORE_FRAMES 2
#define ADC_CONTINUOUS_STORE_SIZE (ADC_CONTINUOUS_FRAME_SIZE * ADC_CONTINUOUS_STORE_FRAMES)
// Yield periodically so the analog task does not starve IDLE0 and trip WDT.
#define ADC_CONTINUOUS_FRAMES_PER_IDLE_DELAY 32
// DMA can deliver channel groups unevenly; per-channel queues let us rebuild
// complete AN3/AN5/AN6 triples without trusting sample order.
#define ANALOG_DMA_CHANNEL_QUEUE_SIZE 64
// Seqlock retry bounds. The control point must never spin unbounded on Core 1
// waiting for the Core-0 writer; giving up is a recoverable missed update.
#define ANALOG_CONTROL_SEQLOCK_RETRIES 32
#define ANALOG_STATUS_SEQLOCK_RETRIES 256

#if (SOC_ADC_DIGI_RESULT_BYTES == 2)
#define ADC_CONTINUOUS_OUTPUT_FORMAT ADC_DIGI_OUTPUT_FORMAT_TYPE1
#define ADC_CONTINUOUS_GET_CHANNEL(sample) ((sample)->type1.channel)
#define ADC_CONTINUOUS_GET_DATA(sample) ((sample)->type1.data)
#else
#define ADC_CONTINUOUS_OUTPUT_FORMAT ADC_DIGI_OUTPUT_FORMAT_TYPE2
#define ADC_CONTINUOUS_GET_CHANNEL(sample) ((sample)->type2.channel)
#define ADC_CONTINUOUS_GET_DATA(sample) ((sample)->type2.data)
#endif

static uint32_t s_latency_buffer[LATENCY_WINDOW_SIZE] = {0};
static std::atomic<size_t> s_latency_index(0);

struct AnalogSnapshotStorage {
    std::atomic<bool> valid{false};
    std::atomic<uint64_t> timestamp_us{0};
    std::atomic<uint32_t> raw_an3{0};
    std::atomic<uint32_t> raw_an5{0};
    std::atomic<uint32_t> raw_an6{0};
    std::atomic<float> calibrated_an3{0.0f};
    std::atomic<float> calibrated_an5{0.0f};
    std::atomic<float> calibrated_an6{0.0f};
};

struct AnalogSnapshotCopy {
    bool valid = false;
    uint64_t timestamp_us = 0;
    uint32_t raw_an3 = 0;
    uint32_t raw_an5 = 0;
    uint32_t raw_an6 = 0;
    float calibrated_an3 = 0.0f;
    float calibrated_an5 = 0.0f;
    float calibrated_an6 = 0.0f;
};

static std::atomic<uint32_t> s_snapshot_seq(0);
static AnalogSnapshotStorage s_snapshot;
static std::atomic<uint32_t> s_measured_triples_per_second(0);
static std::atomic<uint32_t> s_rate_window_triples(0);
static std::atomic<uint64_t> s_rate_window_start_us(0);
static std::atomic<uint32_t> s_overflow_count(0);
static std::atomic<uint32_t> s_miss_count(0);
static std::atomic<uint32_t> s_consecutive_misses(0);
static std::atomic<uint32_t> s_miss_stale_count(0);
static std::atomic<uint32_t> s_miss_contention_count(0);
static std::atomic<uint32_t> s_miss_missing_count(0);
static std::atomic<uint32_t> s_fault_code(0);
static std::atomic<uint32_t> s_samples_read(0);
static std::atomic<uint32_t> s_samples_rejected(0);
static std::atomic<uint32_t> s_channel_order_anomalies(0);
static std::atomic<uint32_t> s_partial_triples(0);
static std::atomic<uint32_t> s_frame_drops(0);
static std::atomic<uint32_t> s_pool_flushes(0);
static std::atomic<uint32_t> s_dma_channel_counts[8];
static std::atomic<uint32_t> s_dma_channel_last_raw[8];
static std::atomic<uint32_t> s_frame_ts_fallbacks(0);
static std::atomic<uint32_t> s_control_age_budget_us(0);
// Age of snapshots the control point actually consumed, current run only
// (D1/D2). Written by the Core-1 control point, reset at session start.
static std::atomic<uint32_t> s_age_used_max_us(0);
static std::atomic<uint32_t> s_age_used_count(0);
static std::atomic<uint32_t> s_age_used_over_budget_count(0);
// Cadence-correlation counters, current run only (reset with age-used stats).
// s_control_trigger_count: control-point snapshot reads (Core 1).
// s_publish_count: valid triples published by acquisition (Core 0). Comparing
// the two over the measurement window shows whether publishing keeps up with
// the control trigger cadence, i.e. whether stale reads are a supply problem.
static std::atomic<uint32_t> s_control_trigger_count(0);
static std::atomic<uint32_t> s_publish_count(0);
// Single-reader hand-off for the continuous driver. The driver's ring buffer
// tolerates exactly one drainer; when the DMA signal engine runs, Core 1
// drains at the control point (freshest possible measurement, immune to
// Core-0 BLE bursts), otherwise the Core-0 acquisition task drains as before
// (CPU engine, stopped-state telemetry). The token is only granted by the
// acquisition task after the driver is started, and only reclaimed after the
// Core-1 drain acknowledges it is not mid-read (s_control_drain_busy).
// seq_cst on both flags: the grant/reclaim handshake is a Dekker-style
// store/load pair between cores.
static std::atomic<bool> s_adc_reader_core1(false);
static std::atomic<bool> s_control_drain_busy(false);
static std::atomic<uint32_t> s_control_drain_max_us(0);
// Stage probes: cycle sums/max per pipeline stage, current run only. One
// writer per stage (Core-1 control path during a run), so relaxed atomics.
// 32-bit cycle sums overflow after ~18 s of *accumulated* stage time; probes
// are reset at session start, far inside that bound.
static std::atomic<uint32_t> s_probe_count[ANALOG_PROBE_STAGE_COUNT];
static std::atomic<uint32_t> s_probe_sum_cycles[ANALOG_PROBE_STAGE_COUNT];
static std::atomic<uint32_t> s_probe_max_cycles[ANALOG_PROBE_STAGE_COUNT];
static std::atomic<bool> s_calibration_lut_ready(false);
static float s_calibration_lut[ANALOG_ADC_MAX_CODE + 1] = {0.0f};

static adc_continuous_handle_t s_adc_continuous_handle = NULL;
static bool s_adc_continuous_started = false;
static uint32_t s_adc_continuous_sample_hz = 0;
static uint32_t s_adc_continuous_frames_since_delay = 0;
static TaskHandle_t s_analog_acquisition_task = nullptr;

static void analog_publish_compat(uint32_t raw_an3, float an3,
                                  uint32_t raw_an5, float an5,
                                  uint32_t raw_an6, float an6,
                                  uint64_t sample_timestamp_us,
                                  bool valid);

// The driver runs with flush_pool = 1: it silently discards stale frame data to
// keep the freshest samples, so a per-conv-done ISR timestamp ring desyncs from
// the frames actually read (the dropped frames' timestamps have no matching
// data) and inflates measurement age. Instead the acquisition task stamps each
// frame at read time; because it wakes on this notification and drains
// immediately, read time tracks the freshest frame's completion, and a real
// Core-0 scheduling gap still surfaces as an equally old snapshot downstream.
static bool IRAM_ATTR analog_on_conv_done(adc_continuous_handle_t handle,
                                          const adc_continuous_evt_data_t* edata,
                                          void* user_data) {
    BaseType_t hpw = pdFALSE;
    TaskHandle_t task = s_analog_acquisition_task;
    if (task != nullptr) {
        vTaskNotifyGiveFromISR(task, &hpw);
    }
    return hpw == pdTRUE;
}

void analog_probe_record(AnalogProbeStage stage, uint32_t cycles) {
    if (stage >= ANALOG_PROBE_STAGE_COUNT) {
        return;
    }
    s_probe_count[stage].fetch_add(1, std::memory_order_relaxed);
    s_probe_sum_cycles[stage].fetch_add(cycles, std::memory_order_relaxed);
    if (cycles > s_probe_max_cycles[stage].load(std::memory_order_relaxed)) {
        s_probe_max_cycles[stage].store(cycles, std::memory_order_relaxed);
    }
}

void analog_probe_reset(void) {
    for (int i = 0; i < ANALOG_PROBE_STAGE_COUNT; ++i) {
        s_probe_count[i].store(0, std::memory_order_relaxed);
        s_probe_sum_cycles[i].store(0, std::memory_order_relaxed);
        s_probe_max_cycles[i].store(0, std::memory_order_relaxed);
    }
}

void analog_probe_get(AnalogProbeStage stage, uint32_t* count,
                      uint32_t* avg_ns, uint32_t* max_ns) {
    uint32_t n = 0, avg = 0, max = 0;
    if (stage < ANALOG_PROBE_STAGE_COUNT) {
        n = s_probe_count[stage].load(std::memory_order_relaxed);
        uint32_t sum = s_probe_sum_cycles[stage].load(std::memory_order_relaxed);
        uint32_t mx = s_probe_max_cycles[stage].load(std::memory_order_relaxed);
        uint32_t ticks_per_us = esp_rom_get_cpu_ticks_per_us();
        if (ticks_per_us == 0) {
            ticks_per_us = 240;
        }
        if (n > 0) {
            avg = (uint32_t)(((uint64_t)sum * 1000ULL) / ((uint64_t)ticks_per_us * n));
        }
        max = (uint32_t)(((uint64_t)mx * 1000ULL) / ticks_per_us);
    }
    if (count != nullptr) *count = n;
    if (avg_ns != nullptr) *avg_ns = avg;
    if (max_ns != nullptr) *max_ns = max;
}

void analog_record_latency(uint32_t us) {
    // Lock-free increment and wrap
    size_t idx = s_latency_index.fetch_add(1, std::memory_order_relaxed) % LATENCY_WINDOW_SIZE;
    s_latency_buffer[idx] = us;
}

void analog_record_overflow() {
    s_overflow_count.fetch_add(1, std::memory_order_acq_rel);
    s_fault_code.store(ANALOG_FAULT_DMA_OVERFLOW, std::memory_order_release);
}

void analog_record_miss(uint32_t fault_code) {
    uint32_t misses = s_consecutive_misses.fetch_add(1, std::memory_order_acq_rel) + 1;
    s_miss_count.fetch_add(1, std::memory_order_acq_rel);
    if (fault_code == ANALOG_FAULT_STALE_SAMPLE) {
        s_miss_stale_count.fetch_add(1, std::memory_order_acq_rel);
    } else if (fault_code == ANALOG_FAULT_SNAPSHOT_CONTENTION) {
        s_miss_contention_count.fetch_add(1, std::memory_order_acq_rel);
    } else if (fault_code == ANALOG_FAULT_MISSING_TRIPLE) {
        s_miss_missing_count.fetch_add(1, std::memory_order_acq_rel);
    }
    s_fault_code.store(misses >= 3 ? ANALOG_FAULT_REPEATED_MISS : fault_code,
                       std::memory_order_release);
}

void analog_get_latency_stats(uint32_t* min, uint32_t* max, uint32_t* avg) {
    uint32_t current_min = 0xFFFFFFFF;
    uint32_t current_max = 0;
    uint64_t sum = 0;
    uint32_t count = 0;

    // Scan the window (On-demand math)
    for (int i = 0; i < LATENCY_WINDOW_SIZE; i++) {
        uint32_t val = s_latency_buffer[i];
        if (val == 0) continue; // Skip uninitialized slots
        
        if (val < current_min) current_min = val;
        if (val > current_max) current_max = val;
        sum += val;
        count++;
    }

    if (count > 0) {
        *min = current_min;
        *max = current_max;
        *avg = (uint32_t)(sum / count);
    } else {
        *min = 0; *max = 0; *avg = 0;
    }
}

static uint32_t analog_latency_p95() {
    uint32_t values[LATENCY_WINDOW_SIZE];
    uint32_t count = 0;

    for (int i = 0; i < LATENCY_WINDOW_SIZE; i++) {
        uint32_t val = s_latency_buffer[i];
        if (val != 0) {
            values[count++] = val;
        }
    }

    if (count == 0) {
        return 0;
    }

    for (uint32_t i = 1; i < count; i++) {
        uint32_t value = values[i];
        int j = i - 1;
        while (j >= 0 && values[j] > value) {
            values[j + 1] = values[j];
            j--;
        }
        values[j + 1] = value;
    }

    uint32_t index = ((count * 95) + 99) / 100;
    if (index == 0) {
        index = 1;
    }
    return values[index - 1];
}

// Report rate over a full window; per-sample deltas are too noisy for
// judging DMA stability from the dashboard.
static void analog_rate_record_triples(uint64_t now_us, uint32_t n) {
    uint64_t window_start = s_rate_window_start_us.load(std::memory_order_acquire);
    if (window_start == 0) {
        s_rate_window_start_us.store(now_us, std::memory_order_release);
        s_rate_window_triples.store(0, std::memory_order_release);
    } else {
        uint32_t triples = s_rate_window_triples.fetch_add(n, std::memory_order_acq_rel) + n;
        uint64_t elapsed_us = now_us - window_start;
        if (elapsed_us >= 1000000ULL) {
            s_measured_triples_per_second.store(
                (uint32_t)((triples * 1000000ULL) / elapsed_us),
                std::memory_order_release);
            s_rate_window_triples.store(0, std::memory_order_release);
            s_rate_window_start_us.store(now_us, std::memory_order_release);
        }
    }
}

static void analog_rate_record_triple(uint64_t now_us) {
    analog_rate_record_triples(now_us, 1);
}

void analog_publish_triple(uint32_t raw_an3, float calibrated_an3,
                           uint32_t raw_an5, float calibrated_an5,
                           uint32_t raw_an6, float calibrated_an6,
                           uint64_t sample_timestamp_us,
                           bool valid) {
    uint64_t now_us = (uint64_t)esp_timer_get_time();
    if (valid) {
        analog_rate_record_triple(now_us);
        s_publish_count.fetch_add(1, std::memory_order_acq_rel);
    }
    // The snapshot carries the conversion time, not the publish time, so
    // measurement-age checks reflect when the signal was actually sampled.
    if (sample_timestamp_us == 0 || sample_timestamp_us > now_us) {
        sample_timestamp_us = now_us;
    }

    // Odd seq marks "writer active"; even seq below marks a coherent snapshot.
    // Single-writer at all times (the reader-token hand-off guarantees the
    // Core-1 drain and the Core-0 acquisition task never publish
    // concurrently), so plain load/store with the canonical seqlock fences
    // replaces two atomic RMW retry loops.
    uint32_t seq = s_snapshot_seq.load(std::memory_order_relaxed);
    s_snapshot_seq.store(seq + 1, std::memory_order_relaxed);
    std::atomic_thread_fence(std::memory_order_release);
    s_snapshot.raw_an3.store(raw_an3, std::memory_order_relaxed);
    s_snapshot.raw_an5.store(raw_an5, std::memory_order_relaxed);
    s_snapshot.raw_an6.store(raw_an6, std::memory_order_relaxed);
    s_snapshot.calibrated_an3.store(calibrated_an3, std::memory_order_relaxed);
    s_snapshot.calibrated_an5.store(calibrated_an5, std::memory_order_relaxed);
    s_snapshot.calibrated_an6.store(calibrated_an6, std::memory_order_relaxed);
    s_snapshot.timestamp_us.store(sample_timestamp_us, std::memory_order_relaxed);
    s_snapshot.valid.store(valid, std::memory_order_relaxed);

    if (!valid) {
        analog_record_miss(ANALOG_FAULT_MISSING_TRIPLE);
    }

    s_snapshot_seq.store(seq + 2, std::memory_order_release);
}

// Bounded seqlock read. Returns false if a coherent snapshot could not be
// captured within max_attempts; callers must treat that as "no data" instead
// of spinning, so a preempted Core-0 writer can never stall the Core-1
// control point indefinitely.
static bool IRAM_ATTR analog_snapshot_try_read(AnalogSnapshotCopy* out,
                                               uint32_t* seq_out,
                                               uint32_t max_attempts) {
    for (uint32_t attempt = 0; attempt < max_attempts; ++attempt) {
        uint32_t seq_start = s_snapshot_seq.load(std::memory_order_acquire);
        if ((seq_start & 1U) != 0) {
            continue;
        }
        out->valid = s_snapshot.valid.load(std::memory_order_relaxed);
        out->timestamp_us = s_snapshot.timestamp_us.load(std::memory_order_relaxed);
        out->raw_an3 = s_snapshot.raw_an3.load(std::memory_order_relaxed);
        out->raw_an5 = s_snapshot.raw_an5.load(std::memory_order_relaxed);
        out->raw_an6 = s_snapshot.raw_an6.load(std::memory_order_relaxed);
        out->calibrated_an3 = s_snapshot.calibrated_an3.load(std::memory_order_relaxed);
        out->calibrated_an5 = s_snapshot.calibrated_an5.load(std::memory_order_relaxed);
        out->calibrated_an6 = s_snapshot.calibrated_an6.load(std::memory_order_relaxed);
        uint32_t seq_end = s_snapshot_seq.load(std::memory_order_acquire);
        if (seq_start == seq_end && (seq_end & 1U) == 0) {
            *seq_out = seq_end;
            return true;
        }
    }
    return false;
}

void analog_get_status(AnalogRuntimeStatus* status) {
    if (status == nullptr) {
        return;
    }

    uint32_t min_us, max_us, avg_us;
    analog_get_latency_stats(&min_us, &max_us, &avg_us);

    AnalogSnapshotCopy snapshot = {};
    uint32_t seq_end = 0;
    if (!analog_snapshot_try_read(&snapshot, &seq_end, ANALOG_STATUS_SEQLOCK_RETRIES)) {
        snapshot = {};
        seq_end = s_snapshot_seq.load(std::memory_order_acquire);
    }

    uint64_t timestamp_us = snapshot.timestamp_us;
    uint64_t now_us = (uint64_t)esp_timer_get_time();
    uint64_t age_us = (timestamp_us > 0 && now_us >= timestamp_us) ? now_us - timestamp_us : 0;

    std::memset(status, 0, sizeof(*status));
    status->seq = seq_end / 2U;
    status->valid = snapshot.valid;
    status->timestamp_us = timestamp_us;
    status->age_us = (age_us > UINT32_MAX) ? UINT32_MAX : (uint32_t)age_us;
    status->target_triples_per_cycle = ANALOG_TARGET_TRIPLES_PER_CYCLE;
    status->measured_triples_per_second = s_measured_triples_per_second.load(std::memory_order_acquire);
    status->raw_an3 = snapshot.raw_an3;
    status->raw_an5 = snapshot.raw_an5;
    status->raw_an6 = snapshot.raw_an6;
    status->calibrated_an3 = snapshot.calibrated_an3;
    status->calibrated_an5 = snapshot.calibrated_an5;
    status->calibrated_an6 = snapshot.calibrated_an6;
    status->latency_min_us = min_us;
    status->latency_avg_us = avg_us;
    status->latency_p95_us = analog_latency_p95();
    status->latency_max_us = max_us;
    status->overflow_count = s_overflow_count.load(std::memory_order_acquire);
    status->miss_count = s_miss_count.load(std::memory_order_acquire);
    status->consecutive_misses = s_consecutive_misses.load(std::memory_order_acquire);
    status->miss_stale_count = s_miss_stale_count.load(std::memory_order_acquire);
    status->miss_contention_count =
        s_miss_contention_count.load(std::memory_order_acquire);
    status->miss_missing_count = s_miss_missing_count.load(std::memory_order_acquire);
    status->fault_code = s_fault_code.load(std::memory_order_acquire);
    status->acquisition_mode = g_analog_acquisition_mode;
    status->samples_read = s_samples_read.load(std::memory_order_acquire);
    status->samples_rejected = s_samples_rejected.load(std::memory_order_acquire);
    status->channel_order_anomalies = s_channel_order_anomalies.load(std::memory_order_acquire);
    status->partial_triples = s_partial_triples.load(std::memory_order_acquire);
    status->frame_drops = s_frame_drops.load(std::memory_order_acquire);
    status->pool_flushes = s_pool_flushes.load(std::memory_order_acquire);
    status->calibration_lut_ready = s_calibration_lut_ready.load(std::memory_order_acquire);
    status->min_snapshot_age_us = analog_min_snapshot_age_us();
    // Report the budget as enforced at the control point: the signal loop's
    // dataset-derived budget clamped to the pipeline floor.
    uint32_t budget_us = s_control_age_budget_us.load(std::memory_order_acquire);
    status->control_max_age_us =
        (budget_us > status->min_snapshot_age_us) ? budget_us : status->min_snapshot_age_us;
    status->frame_ts_fallbacks = s_frame_ts_fallbacks.load(std::memory_order_acquire);
    status->age_used_max_us = s_age_used_max_us.load(std::memory_order_acquire);
    status->age_used_count = s_age_used_count.load(std::memory_order_acquire);
    status->age_used_over_budget_count =
        s_age_used_over_budget_count.load(std::memory_order_acquire);
    status->control_trigger_count = s_control_trigger_count.load(std::memory_order_acquire);
    status->publish_count = s_publish_count.load(std::memory_order_acquire);
    status->control_drain_max_us = s_control_drain_max_us.load(std::memory_order_acquire);
}

uint32_t analog_get_consecutive_misses(void) {
    return s_consecutive_misses.load(std::memory_order_acquire);
}

// The consecutive-miss counter is otherwise only cleared by a valid snapshot
// publish; without this, a latched count >= 3 makes the controller's
// auto-disable trip on the first read after re-enabling control.
void analog_clear_consecutive_misses(void) {
    s_consecutive_misses.store(0, std::memory_order_release);
}

void analog_report_control_age_budget(uint32_t max_age_us) {
    s_control_age_budget_us.store(max_age_us, std::memory_order_release);
}

void analog_reset_age_used(void) {
    s_age_used_max_us.store(0, std::memory_order_release);
    s_age_used_count.store(0, std::memory_order_release);
    s_age_used_over_budget_count.store(0, std::memory_order_release);
    s_control_trigger_count.store(0, std::memory_order_release);
    s_publish_count.store(0, std::memory_order_release);
    s_control_drain_max_us.store(0, std::memory_order_release);
}

uint32_t analog_min_snapshot_age_us(void) {
    if (g_analog_acquisition_mode != ANALOG_ACQ_MODE_CONTINUOUS) {
        // Oneshot publishes one triple per acquisition period; anything
        // fresher than two periods is physically unavailable.
        return g_analog_acquisition_period_us * 2;
    }
    uint32_t sample_hz = s_adc_continuous_sample_hz != 0 ? s_adc_continuous_sample_hz
                                                         : g_analog_continuous_sample_hz;
    if (sample_hz == 0) {
        return 0;
    }
    // One full DMA frame of accumulation plus 50% scheduling margin.
    uint32_t frame_us = (uint32_t)(((uint64_t)ADC_CONTINUOUS_FRAME_TRIPLES * 3 * 1000000ULL) / sample_hz);
    return frame_us + frame_us / 2;
}

// Control-point read path: seqlock snapshot only. Latency statistics and the
// p95 sort stay on the telemetry path (analog_get_status) so this cannot eat
// into the maintenance interval between signal cycles.
bool IRAM_ATTR analog_read_control_snapshot(AnalogControlSnapshot* snapshot,
                                            uint32_t last_seq,
                                            uint32_t max_age_us) {
    if (snapshot == nullptr) {
        return false;
    }
    s_control_trigger_count.fetch_add(1, std::memory_order_acq_rel);

    if (!s_calibration_lut_ready.load(std::memory_order_acquire)) {
        analog_record_miss(ANALOG_FAULT_CALIBRATION_UNAVAILABLE);
        return false;
    }

    AnalogSnapshotCopy copy = {};
    uint32_t seq_raw = 0;
    if (!analog_snapshot_try_read(&copy, &seq_raw, ANALOG_CONTROL_SEQLOCK_RETRIES)) {
        analog_record_miss(ANALOG_FAULT_SNAPSHOT_CONTENTION);
        return false;
    }
    if (!copy.valid) {
        analog_record_miss(ANALOG_FAULT_MISSING_TRIPLE);
        return false;
    }

    uint64_t now_us = (uint64_t)esp_timer_get_time();
    uint64_t age_us = (copy.timestamp_us > 0 && now_us >= copy.timestamp_us)
                          ? now_us - copy.timestamp_us
                          : 0;

    // The caller passes the signal cycle window as the age budget, but the
    // pipeline cannot deliver samples fresher than one DMA frame; clamp so
    // short cycles do not reject every sample structurally.
    uint32_t min_age_us = analog_min_snapshot_age_us();
    uint64_t effective_max_age_us = (max_age_us > min_age_us) ? max_age_us : min_age_us;

    // Control must act on a new sample inside the current timing budget; stale
    // or repeated ADC data can drive corrections in the wrong direction.
    uint32_t seq = seq_raw / 2U;
    const bool dry_run = g_control_dry_run.load(std::memory_order_acquire);

    // A repeated seq means no new sample arrived; there is nothing to compute
    // even in dry-run, so it is always a miss.
    if (seq == last_seq) {
        analog_record_miss(ANALOG_FAULT_STALE_SAMPLE);
        return false;
    }

    // Over-budget age is a hard reject for live control (stale feedback is
    // dangerous). In compute-only (dry-run) mode we accept the new-but-stale
    // sample so the read/compute path can be observed; the excess age surfaces
    // via age_used_max_us (which will exceed control_max_age_us on purpose).
    if (age_us > effective_max_age_us && !dry_run) {
        analog_record_miss(ANALOG_FAULT_STALE_SAMPLE);
        return false;
    }

    snapshot->seq = seq;
    snapshot->age_us = (age_us > UINT32_MAX) ? UINT32_MAX : (uint32_t)age_us;
    snapshot->an3 = copy.calibrated_an3;
    snapshot->an5 = copy.calibrated_an5;
    snapshot->an6 = copy.calibrated_an6;

    // Accepted-only "age used" statistics: the control point is the single
    // writer, so plain load/compare/store is race-free.
    if (snapshot->age_us > s_age_used_max_us.load(std::memory_order_relaxed)) {
        s_age_used_max_us.store(snapshot->age_us, std::memory_order_release);
    }
    if (age_us > effective_max_age_us) {
        s_age_used_over_budget_count.fetch_add(1, std::memory_order_acq_rel);
    }
    s_age_used_count.fetch_add(1, std::memory_order_acq_rel);
    s_consecutive_misses.store(0, std::memory_order_release);
    s_fault_code.store(0, std::memory_order_release);
    return true;
}

std::string analog_get_dma_debug_json() {
    char json[512];
    std::snprintf(json, sizeof(json),
                  "{\"c0\":%lu,\"r0\":%lu,"
                  "\"c1\":%lu,\"r1\":%lu,"
                  "\"c2\":%lu,\"r2\":%lu,"
                  "\"c3\":%lu,\"r3\":%lu,"
                  "\"c4\":%lu,\"r4\":%lu,"
                  "\"c5\":%lu,\"r5\":%lu,"
                  "\"c6\":%lu,\"r6\":%lu,"
                  "\"c7\":%lu,\"r7\":%lu,"
                  "\"samples\":%lu,\"anomalies\":%lu,\"partials\":%lu}",
                  s_dma_channel_counts[0].load(std::memory_order_acquire),
                  s_dma_channel_last_raw[0].load(std::memory_order_acquire),
                  s_dma_channel_counts[1].load(std::memory_order_acquire),
                  s_dma_channel_last_raw[1].load(std::memory_order_acquire),
                  s_dma_channel_counts[2].load(std::memory_order_acquire),
                  s_dma_channel_last_raw[2].load(std::memory_order_acquire),
                  s_dma_channel_counts[3].load(std::memory_order_acquire),
                  s_dma_channel_last_raw[3].load(std::memory_order_acquire),
                  s_dma_channel_counts[4].load(std::memory_order_acquire),
                  s_dma_channel_last_raw[4].load(std::memory_order_acquire),
                  s_dma_channel_counts[5].load(std::memory_order_acquire),
                  s_dma_channel_last_raw[5].load(std::memory_order_acquire),
                  s_dma_channel_counts[6].load(std::memory_order_acquire),
                  s_dma_channel_last_raw[6].load(std::memory_order_acquire),
                  s_dma_channel_counts[7].load(std::memory_order_acquire),
                  s_dma_channel_last_raw[7].load(std::memory_order_acquire),
                  s_samples_read.load(std::memory_order_acquire),
                  s_channel_order_anomalies.load(std::memory_order_acquire),
                  s_partial_triples.load(std::memory_order_acquire));
    return std::string(json);
}


// handle for the ADC unit
static adc_oneshot_unit_handle_t adc1_handle = NULL;
static const char* TAG_COMMON = "HELPER_COMMON";
static float esp32_calibration(float value);

static void analog_oneshot_deinit() {
    if (adc1_handle == NULL) {
        return;
    }
    // ESP-IDF does not allow oneshot and continuous drivers to own ADC1 at the
    // same time, so mode changes must release the old driver first.
    adc_oneshot_del_unit(adc1_handle);
    adc1_handle = NULL;
}

void analog_init() {
    if (adc1_handle != NULL) {
        return;
    }
    
    ESP_LOGI(TAG_COMMON, "Initializing Analog Ports (ADC1)...");
    
    // init adc unit 1
    adc_oneshot_unit_init_cfg_t init_config1 = {
        .unit_id = ADC_UNIT_1,
        .clk_src = ADC_RTC_CLK_SRC_DEFAULT,
        .ulp_mode = ADC_ULP_MODE_DISABLE,
    };
    ESP_ERROR_CHECK(adc_oneshot_new_unit(&init_config1, &adc1_handle));
    
    // configure channels
    adc_oneshot_chan_cfg_t config = {
        .atten = ADC_ATTEN_DB_12,
        .bitwidth = ADC_BITWIDTH_DEFAULT,
    };
    
    // map channels
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_3, &config)); // AN1
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_5, &config)); // AN2
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_4, &config)); // AN3
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_7, &config)); // AN4
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_6, &config)); // AN5
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_0, &config)); // AN6

    for (uint32_t raw = 0; raw <= ANALOG_ADC_MAX_CODE; ++raw) {
        float voltage = ((float)raw / ADC_MAX) * VOLTAGE_MAX;
        s_calibration_lut[raw] = esp32_calibration(voltage);
    }
    s_calibration_lut_ready.store(true, std::memory_order_release);
    
    ESP_LOGI(TAG_COMMON, "Analog Ports Initialized.");
}

float calib_from[] = {0.00, 0.07, 0.17, 0.26, 0.36, 0.46, 0.56, 0.66, 0.76, 0.86, 0.96, 1.06, 1.16, 1.27, 1.37, 1.46, 1.56, 1.67, 1.76, 1.86, 1.96, 2.06, 2.16, 2.27, 2.37, 2.49, 2.61, 2.75, 2.90, 3.07, 3.26, 3.30, 3.30};
float calib_to[] = {0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00, 1.10, 1.20, 1.30, 1.40, 1.50, 1.60, 1.70, 1.80, 1.90, 2.00, 2.10, 2.20, 2.30, 2.40, 2.50, 2.60, 2.70, 2.80, 2.90, 3.00, 3.10, 3.20, 3.30};
int calib_numel = sizeof(calib_from) / sizeof(calib_from[0]);

static float esp32_calibration(float value) {


    // lower boundary
    if (value <= calib_from[0]) {
        return calib_to[0];
    }

    // higher boundary
    if (value >= calib_from[calib_numel - 1]) {
        return calib_to[calib_numel - 1];
    }

    // find the lookup interval
    for (int i = 0; i < calib_numel - 1; ++i) {
        if (value >= calib_from[i] && value <= calib_from[i + 1]) {
            float x1 = calib_from[i];
            float y1 = calib_to[i];
            float x2 = calib_from[i + 1];
            float y2 = calib_to[i + 1];

            // perform a linear interpolation
            if (x2 == x1) {
                return y1;
            }

            return y1 + (value - x1) * (y2 - y1) / (x2 - x1);
        }
    }

    // edge cases protection
    return calib_to[calib_numel - 1];
}

float analog_calibrate_raw(uint32_t raw) {
    float voltage = ((float)raw / ADC_MAX) * VOLTAGE_MAX;
    return esp32_calibration(voltage);
}

float analog_calibrate_raw_lut(uint32_t raw) {
    if (raw > ANALOG_ADC_MAX_CODE) {
        raw = ANALOG_ADC_MAX_CODE;
    }
    if (!s_calibration_lut_ready.load(std::memory_order_acquire)) {
        return analog_calibrate_raw(raw);
    }
    return s_calibration_lut[raw];
}

static bool analog_port_to_channel(AnalogPort port, adc_channel_t* channel) {
    if (channel == nullptr) {
        return false;
    }

    switch (port) {
        case AnalogPort::AN1: *channel = ADC_CHANNEL_3; return true;
        case AnalogPort::AN2: *channel = ADC_CHANNEL_5; return true;
        case AnalogPort::AN3: *channel = ADC_CHANNEL_4; return true;
        case AnalogPort::AN4: *channel = ADC_CHANNEL_7; return true;
        case AnalogPort::AN5: *channel = ADC_CHANNEL_6; return true;
        case AnalogPort::AN6: *channel = ADC_CHANNEL_0; return true;
        default:
            return false;
    }
}

bool analog_read_port_sample(AnalogPort port, uint32_t* raw, float* calibrated) {
    if (adc1_handle == NULL) {
        ESP_LOGE(TAG_COMMON, "ADC not initialized! Call analog_init().");
        if (raw != nullptr) *raw = 0;
        if (calibrated != nullptr) *calibrated = -99.0f;
        return false;
    }
    
    adc_channel_t channel;
    if (!analog_port_to_channel(port, &channel)) {
        ESP_LOGW(TAG_COMMON, "Invalid Analog Port requested");
        if (raw != nullptr) *raw = 0;
        if (calibrated != nullptr) *calibrated = -99.0f;
        return false;
    }
    
    // read raw value
    int raw_val = 0;
    if (adc_oneshot_read(adc1_handle, channel, &raw_val) == ESP_OK) {
        if (raw != nullptr) *raw = (uint32_t)raw_val;
        if (calibrated != nullptr) *calibrated = analog_calibrate_raw((uint32_t)raw_val);
        return true;
    } else {
        ESP_LOGE(TAG_COMMON, "Failed to read ADC channel %d", channel);
        if (raw != nullptr) *raw = 0;
        if (calibrated != nullptr) *calibrated = -99.0f;
        return false;
    }
}

float analog_read_port(AnalogPort port) {
    float calibrated = -99.0f;
    analog_read_port_sample(port, nullptr, &calibrated);
    return calibrated;
}

static void analog_publish_compat(uint32_t raw_an3, float an3,
                                  uint32_t raw_an5, float an5,
                                  uint32_t raw_an6, float an6,
                                  uint64_t sample_timestamp_us,
                                  bool valid) {
    analog_publish_triple(raw_an3, an3, raw_an5, an5, raw_an6, an6,
                          sample_timestamp_us, valid);

    g_adc_an3.store(an3, std::memory_order_release);
    g_adc_an5.store(an5, std::memory_order_release);
    g_adc_an6.store(an6, std::memory_order_release);
    g_adc_fresh.store(valid, std::memory_order_release);
    g_system_state.ble_an_read_state.store(BLEAnalogReadState::IDLE, std::memory_order_release);
}

static void analog_continuous_stop() {
    if (s_adc_continuous_handle == NULL) {
        s_adc_continuous_started = false;
        s_adc_continuous_sample_hz = 0;
        return;
    }

    if (s_adc_continuous_started) {
        adc_continuous_stop(s_adc_continuous_handle);
        s_adc_continuous_started = false;
    }

    adc_continuous_deinit(s_adc_continuous_handle);
    s_adc_continuous_handle = NULL;
    s_adc_continuous_sample_hz = 0;
    s_adc_continuous_frames_since_delay = 0;
}

static bool analog_continuous_start(uint32_t sample_hz) {
    if (s_adc_continuous_started && s_adc_continuous_sample_hz == sample_hz) {
        return true;
    }

    analog_oneshot_deinit();
    analog_continuous_stop();

    adc_continuous_handle_cfg_t handle_config = {};
    handle_config.max_store_buf_size = ADC_CONTINUOUS_STORE_SIZE;
    handle_config.conv_frame_size = ADC_CONTINUOUS_FRAME_SIZE;
    // Prefer fresh data over backlog; old samples are worse than dropped ones
    // for closed-loop correction.
    handle_config.flags.flush_pool = 1;

    esp_err_t ret = adc_continuous_new_handle(&handle_config, &s_adc_continuous_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG_COMMON, "ADC continuous handle init failed: %s", esp_err_to_name(ret));
        s_adc_continuous_handle = NULL;
        return false;
    }

    // Hardware channels 4, 6, 0 are the board AN3, AN5, AN6 feedback inputs.
    adc_digi_pattern_config_t pattern[3] = {};
    pattern[0].atten = ADC_ATTEN_DB_12;
    pattern[0].channel = ADC_CHANNEL_4;
    pattern[0].unit = ADC_UNIT_1;
    pattern[0].bit_width = SOC_ADC_DIGI_MAX_BITWIDTH;
    pattern[1].atten = ADC_ATTEN_DB_12;
    pattern[1].channel = ADC_CHANNEL_6;
    pattern[1].unit = ADC_UNIT_1;
    pattern[1].bit_width = SOC_ADC_DIGI_MAX_BITWIDTH;
    pattern[2].atten = ADC_ATTEN_DB_12;
    pattern[2].channel = ADC_CHANNEL_0;
    pattern[2].unit = ADC_UNIT_1;
    pattern[2].bit_width = SOC_ADC_DIGI_MAX_BITWIDTH;

    adc_continuous_config_t adc_config = {};
    adc_config.pattern_num = 3;
    adc_config.adc_pattern = pattern;
    adc_config.sample_freq_hz = sample_hz;
    adc_config.conv_mode = ADC_CONV_SINGLE_UNIT_1;
    adc_config.format = ADC_CONTINUOUS_OUTPUT_FORMAT;

    ret = adc_continuous_config(s_adc_continuous_handle, &adc_config);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG_COMMON, "ADC continuous config failed: %s", esp_err_to_name(ret));
        analog_continuous_stop();
        return false;
    }

    // Frame timestamps come from the conversion-done ISR so measurement age
    // reflects sampling time, not acquisition-task scheduling.
    adc_continuous_evt_cbs_t evt_cbs = {};
    evt_cbs.on_conv_done = analog_on_conv_done;
    ret = adc_continuous_register_event_callbacks(s_adc_continuous_handle, &evt_cbs, NULL);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG_COMMON, "ADC continuous callback registration failed: %s", esp_err_to_name(ret));
        analog_continuous_stop();
        return false;
    }

    ret = adc_continuous_start(s_adc_continuous_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG_COMMON, "ADC continuous start failed: %s", esp_err_to_name(ret));
        analog_continuous_stop();
        return false;
    }

    s_adc_continuous_started = true;
    s_adc_continuous_sample_hz = sample_hz;
    ESP_LOGI(TAG_COMMON, "ADC continuous started at %lu samples/s", sample_hz);
    return true;
}

struct AnalogTripleAccumulator {
    uint32_t raw[3][ANALOG_DMA_CHANNEL_QUEUE_SIZE] = {};
    uint64_t ts_us[3][ANALOG_DMA_CHANNEL_QUEUE_SIZE] = {};
    uint8_t head[3] = {};
    uint8_t tail[3] = {};
    uint8_t count[3] = {};
};

static void analog_reset_partial_triple(AnalogTripleAccumulator* acc) {
    for (uint32_t i = 0; i < 3; ++i) {
        acc->head[i] = 0;
        acc->tail[i] = 0;
        acc->count[i] = 0;
    }
}

static bool analog_channel_to_queue_index(uint32_t channel, uint32_t* index) {
    switch (channel) {
    case ADC_CHANNEL_4:
        *index = 0;
        return true;
    case ADC_CHANNEL_6:
        *index = 1;
        return true;
    case ADC_CHANNEL_0:
        *index = 2;
        return true;
    default:
        return false;
    }
}

static void analog_queue_push(AnalogTripleAccumulator* acc, uint32_t index,
                              uint32_t raw, uint64_t ts_us) {
    if (acc->count[index] == ANALOG_DMA_CHANNEL_QUEUE_SIZE) {
        // Channel imbalance means the queues no longer describe the same
        // conversion rounds; pairing them would feed the gain matrix samples
        // taken far apart as if simultaneous. Flush everything and restart
        // triple assembly from coherent data.
        analog_reset_partial_triple(acc);
        s_channel_order_anomalies.fetch_add(1, std::memory_order_acq_rel);
        s_partial_triples.fetch_add(1, std::memory_order_acq_rel);
    }

    acc->raw[index][acc->tail[index]] = raw;
    acc->ts_us[index][acc->tail[index]] = ts_us;
    acc->tail[index] = (acc->tail[index] + 1) % ANALOG_DMA_CHANNEL_QUEUE_SIZE;
    acc->count[index]++;
}

static uint32_t analog_queue_pop(AnalogTripleAccumulator* acc, uint32_t index,
                                 uint64_t* ts_us) {
    uint32_t raw = acc->raw[index][acc->head[index]];
    *ts_us = acc->ts_us[index][acc->head[index]];
    acc->head[index] = (acc->head[index] + 1) % ANALOG_DMA_CHANNEL_QUEUE_SIZE;
    acc->count[index]--;
    return raw;
}

// Drains all complete triples but publishes only the newest one: the control
// point only ever consumes the latest snapshot, so writing every triple is
// wasted seqlock traffic. Skipped triples still count toward the rate metric.
static void analog_publish_queued_triples(AnalogTripleAccumulator* acc) {
    bool have_triple = false;
    uint32_t raw_an3 = 0, raw_an5 = 0, raw_an6 = 0;
    uint64_t triple_ts_us = 0;

    uint32_t assemble_start = esp_cpu_get_cycle_count();
    // Only the newest complete triple is consumed; discard the older ones by
    // advancing the queue heads in O(1) instead of popping them one by one
    // (each pop carried an esp_timer read + rate-window atomics).
    uint8_t complete = acc->count[0];
    if (acc->count[1] < complete) complete = acc->count[1];
    if (acc->count[2] < complete) complete = acc->count[2];
    if (complete > 0) {
        if (complete > 1) {
            uint8_t skip = complete - 1;
            for (uint32_t q = 0; q < 3; ++q) {
                acc->head[q] = (acc->head[q] + skip) % ANALOG_DMA_CHANNEL_QUEUE_SIZE;
                acc->count[q] -= skip;
            }
            // Skipped triples still count toward the rate metric, in one shot.
            analog_rate_record_triples((uint64_t)esp_timer_get_time(), skip);
        }
        uint64_t ts_an3, ts_an5, ts_an6;
        raw_an3 = analog_queue_pop(acc, 0, &ts_an3);
        raw_an5 = analog_queue_pop(acc, 1, &ts_an5);
        raw_an6 = analog_queue_pop(acc, 2, &ts_an6);
        // Oldest of the three: the conservative age for the assembled triple.
        triple_ts_us = ts_an3;
        if (ts_an5 < triple_ts_us) triple_ts_us = ts_an5;
        if (ts_an6 < triple_ts_us) triple_ts_us = ts_an6;
        have_triple = true;
    }
    uint32_t assemble_end = esp_cpu_get_cycle_count();
    analog_probe_record(ANALOG_PROBE_ASSEMBLE, assemble_end - assemble_start);

    if (have_triple) {
        uint32_t calib_start = assemble_end;
        float an3 = analog_calibrate_raw_lut(raw_an3);
        float an5 = analog_calibrate_raw_lut(raw_an5);
        float an6 = analog_calibrate_raw_lut(raw_an6);
        uint32_t calib_end = esp_cpu_get_cycle_count();
        analog_probe_record(ANALOG_PROBE_CALIB, calib_end - calib_start);

        analog_publish_compat(raw_an3, an3, raw_an5, an5, raw_an6, an6,
                              triple_ts_us, true);
        analog_probe_record(ANALOG_PROBE_PUBLISH,
                            esp_cpu_get_cycle_count() - calib_end);
    }
}

static void analog_oneshot_step() {
    analog_init();

    float an3, an5, an6;
    uint32_t raw_an3, raw_an5, raw_an6;

    // Timestamp before the first conversion: the oldest plausible sample time
    // for the triple, so measurement age is never underestimated.
    uint64_t sample_ts_us = (uint64_t)esp_timer_get_time();
    uint32_t start = esp_cpu_get_cycle_count();
    bool valid = analog_read_port_sample(AnalogPort::AN3, &raw_an3, &an3);
    valid = analog_read_port_sample(AnalogPort::AN5, &raw_an5, &an5) && valid;
    valid = analog_read_port_sample(AnalogPort::AN6, &raw_an6, &an6) && valid;
    uint32_t end = esp_cpu_get_cycle_count();
    analog_record_latency((end - start) / esp_rom_get_cpu_ticks_per_us());
    analog_publish_compat(raw_an3, an3, raw_an5, an5, raw_an6, an6, sample_ts_us, valid);

    uint32_t period_us = g_analog_acquisition_period_us;
    if (period_us >= 1000) {
        vTaskDelay(pdMS_TO_TICKS((period_us + 999) / 1000));
    } else if (period_us > 0) {
        esp_rom_delay_us(period_us);
    } else {
        taskYIELD();
    }
}

// Reads and folds one DMA frame into the accumulator. Returns:
//   1  a frame was consumed
//   0  no frame ready (driver drained)
//  -1  read error; accumulator already reset
static int analog_continuous_read_frame(AnalogTripleAccumulator* acc, uint32_t sample_hz) {
    uint8_t frame[ADC_CONTINUOUS_FRAME_SIZE];
    uint32_t out_len = 0;
    uint32_t start = esp_cpu_get_cycle_count();
    esp_err_t ret = adc_continuous_read(s_adc_continuous_handle, frame, sizeof(frame), &out_len, 0);
    uint32_t end = esp_cpu_get_cycle_count();
    // Probe every driver call, including the final empty read that terminates
    // a drain: that "check for more" cost is part of the pipeline too.
    analog_probe_record(ANALOG_PROBE_ADC_READ, end - start);

    if (ret == ESP_ERR_TIMEOUT) {
        return 0;
    }
    if (ret != ESP_OK) {
        analog_record_overflow();
        s_frame_drops.fetch_add(1, std::memory_order_acq_rel);
        analog_reset_partial_triple(acc);
        if (ret == ESP_ERR_INVALID_STATE) {
            s_pool_flushes.fetch_add(1, std::memory_order_acq_rel);
            adc_continuous_flush_pool(s_adc_continuous_handle);
        } else {
            ESP_LOGW(TAG_COMMON, "ADC continuous read failed: %s", esp_err_to_name(ret));
        }
        return -1;
    }

    analog_record_latency((end - start) / esp_rom_get_cpu_ticks_per_us());
    if (out_len % SOC_ADC_DIGI_RESULT_BYTES != 0) {
        s_samples_rejected.fetch_add(1, std::memory_order_acq_rel);
    }

    // Read time is the frame-completion time: the task wakes on the conv-done
    // notification and drains the freshest frames immediately, so this tracks
    // when the samples were taken without depending on an ISR timestamp ring
    // (which desyncs under the driver's flush_pool).
    uint64_t frame_ts_us = (uint64_t)esp_timer_get_time();
    uint32_t total_samples = out_len / SOC_ADC_DIGI_RESULT_BYTES;

    uint32_t parse_start = esp_cpu_get_cycle_count();
    // Backdate additively: one divide per frame instead of a software 64-bit
    // divide per sample (the dominant parse cost before optimization). At
    // 250 kS/s the step is exactly 4 µs; for non-integer rates the sub-µs
    // rounding drift across a 12-sample frame is negligible.
    uint32_t step_us = (sample_hz > 0) ? (1000000U / sample_hz) : 0;
    uint64_t sample_ts_us = frame_ts_us;
    if (total_samples > 0) {
        sample_ts_us -= (uint64_t)step_us * (total_samples - 1);
    }
    // Statistics accumulate in locals; one atomic commit per frame replaces
    // four atomic RMWs per sample.
    uint32_t local_channel_counts[8] = {0};
    uint32_t local_channel_last[8] = {0};
    uint32_t local_read = 0;
    uint32_t local_rejected = 0;

    for (uint32_t i = 0; i + SOC_ADC_DIGI_RESULT_BYTES <= out_len;
         i += SOC_ADC_DIGI_RESULT_BYTES, sample_ts_us += step_us) {
        adc_digi_output_data_t* sample = reinterpret_cast<adc_digi_output_data_t*>(&frame[i]);
        uint32_t channel = ADC_CONTINUOUS_GET_CHANNEL(sample);
        uint32_t raw = ADC_CONTINUOUS_GET_DATA(sample);
        local_read++;
        if (channel < 8) {
            local_channel_counts[channel]++;
            local_channel_last[channel] = raw;
        }
        uint32_t index;
        if (!analog_channel_to_queue_index(channel, &index)) {
            local_rejected++;
            continue;
        }
        analog_queue_push(acc, index, raw, sample_ts_us);
    }

    s_samples_read.fetch_add(local_read, std::memory_order_relaxed);
    if (local_rejected != 0) {
        s_samples_rejected.fetch_add(local_rejected, std::memory_order_relaxed);
    }
    for (uint32_t ch = 0; ch < 8; ++ch) {
        if (local_channel_counts[ch] != 0) {
            s_dma_channel_counts[ch].fetch_add(local_channel_counts[ch],
                                               std::memory_order_relaxed);
            s_dma_channel_last_raw[ch].store(local_channel_last[ch],
                                             std::memory_order_relaxed);
        }
    }
    analog_probe_record(ANALOG_PROBE_PARSE,
                        esp_cpu_get_cycle_count() - parse_start);
    return 1;
}

// Accumulator for the Core-1 control-point drain. Static (too large for the
// control task stack) and touched only while Core 1 holds the reader token,
// except the reset the acquisition task performs before granting it.
static AnalogTripleAccumulator s_control_acc;
// The driver keeps at most a couple of frames (flush_pool discards backlog);
// the cap only bounds the drain if the driver misbehaves. WDT is off on
// Core 1, so this loop must be provably finite.
#define ANALOG_CONTROL_DRAIN_MAX_FRAMES 8

void analog_control_drain_publish(void) {
    // Dekker-style handshake with the reclaim path: publish "busy", then
    // re-check the token. If the reclaim won the race we back off before
    // touching the driver; if we won, the reclaim spins on busy until the
    // drain below completes.
    if (!s_adc_reader_core1.load(std::memory_order_seq_cst)) {
        return;
    }
    s_control_drain_busy.store(true, std::memory_order_seq_cst);
    if (!s_adc_reader_core1.load(std::memory_order_seq_cst)) {
        s_control_drain_busy.store(false, std::memory_order_release);
        return;
    }

    uint32_t t0 = esp_cpu_get_cycle_count();
    // Stable while the token is held: the acquisition task never restarts the
    // driver (or applies a sample-rate change) until it reclaims the reader.
    uint32_t sample_hz = s_adc_continuous_sample_hz;
    bool consumed = false;
    for (int i = 0; i < ANALOG_CONTROL_DRAIN_MAX_FRAMES; ++i) {
        if (analog_continuous_read_frame(&s_control_acc, sample_hz) != 1) {
            break;  // drained or read error (error path already resynced)
        }
        consumed = true;
    }
    if (consumed) {
        analog_publish_queued_triples(&s_control_acc);
    }
    uint32_t drain_us =
        (esp_cpu_get_cycle_count() - t0) / esp_rom_get_cpu_ticks_per_us();
    if (drain_us > s_control_drain_max_us.load(std::memory_order_relaxed)) {
        s_control_drain_max_us.store(drain_us, std::memory_order_release);
    }

    s_control_drain_busy.store(false, std::memory_order_release);
}

static void analog_continuous_step(AnalogTripleAccumulator* acc) {
    uint32_t sample_hz = g_analog_continuous_sample_hz;
    if (!analog_continuous_start(sample_hz)) {
        analog_record_overflow();
        g_analog_acquisition_mode = ANALOG_ACQ_MODE_ONESHOT;
        analog_reset_partial_triple(acc);
        vTaskDelay(pdMS_TO_TICKS(100));
        return;
    }

    // Clear-on-take (pdTRUE): one wake drains every queued frame, so the
    // accumulated per-frame notifications collapse into a single pass instead
    // of one spin per frame.
    if (ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(20)) == 0) {
        return;
    }

    // Drain the whole driver backlog before publishing. Reading one frame per
    // notify lets frames (and thus measurement age) pile up whenever this
    // Core-0 task is scheduled in bursts; draining keeps the published triple
    // pinned to the newest sample the DMA has delivered.
    bool consumed = false;
    for (;;) {
        int rc = analog_continuous_read_frame(acc, sample_hz);
        if (rc == 1) {
            consumed = true;
            continue;
        }
        break;  // 0 = drained, -1 = error (state already resynced)
    }

    if (consumed) {
        analog_publish_queued_triples(acc);
    }

    if (g_control_enabled.load(std::memory_order_acquire)) {
        taskYIELD();
        return;
    }

    s_adc_continuous_frames_since_delay++;
    if (s_adc_continuous_frames_since_delay >= ADC_CONTINUOUS_FRAMES_PER_IDLE_DELAY) {
        s_adc_continuous_frames_since_delay = 0;
        vTaskDelay(1);
    } else {
        taskYIELD();
    }
}

void analog_acquisition_task(void* arg) {
    ESP_LOGI(TAG_COMMON, "Analog Background Acquisition Task Started");
    s_analog_acquisition_task = xTaskGetCurrentTaskHandle();
    // Static: the per-channel timestamp queues are too large for the 4 KB
    // task stack, and only one acquisition task ever exists.
    static AnalogTripleAccumulator acc;

    for (;;) {
        // While the DMA signal engine runs (continuous mode), Core 1 drains
        // the ADC inline at its control point; this task only keeps the
        // driver alive and stays off the ring buffer (single-reader rule).
        const bool core1_owns =
            g_analog_acquisition_mode == ANALOG_ACQ_MODE_CONTINUOUS &&
            signal_dma_engine_is_active();

        if (core1_owns) {
            if (!s_adc_reader_core1.load(std::memory_order_relaxed)) {
                // Grant path: start the driver from this Core-0 context (pins
                // the ADC ISR to Core 0, away from the signal loop), clear any
                // stale partial triples from a previous run, then hand over.
                if (!analog_continuous_start(g_analog_continuous_sample_hz)) {
                    analog_record_overflow();
                    g_analog_acquisition_mode = ANALOG_ACQ_MODE_ONESHOT;
                    vTaskDelay(pdMS_TO_TICKS(100));
                    continue;
                }
                analog_reset_partial_triple(&s_control_acc);
                s_adc_reader_core1.store(true, std::memory_order_seq_cst);
            }
            // Sample-rate changes are deliberately not applied while Core 1
            // holds the reader: restarting the driver under an active drain
            // would race. They take effect on the next signal start.
            vTaskDelay(pdMS_TO_TICKS(10));
            continue;
        }

        if (s_adc_reader_core1.load(std::memory_order_relaxed)) {
            // Reclaim path: engine stopped (or mode changed). Revoke the
            // token, then wait out a possibly in-flight Core-1 drain (µs
            // scale) before touching the driver from this core again.
            s_adc_reader_core1.store(false, std::memory_order_seq_cst);
            while (s_control_drain_busy.load(std::memory_order_seq_cst)) {
                vTaskDelay(1);
            }
            analog_reset_partial_triple(&acc);
        }

        if (g_analog_acquisition_mode == ANALOG_ACQ_MODE_CONTINUOUS) {
            analog_continuous_step(&acc);
        } else {
            analog_continuous_stop();
            analog_reset_partial_triple(&acc);
            analog_oneshot_step();
        }
    }
}
