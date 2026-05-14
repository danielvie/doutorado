#include "helper_analog.h"
#include <atomic>
#include <cstdint>
#include <cstring>
#include <cstdio>

#include "helper_common.h"
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
#define ADC_CONTINUOUS_FRAME_TRIPLES 16
#define ADC_CONTINUOUS_FRAME_SIZE (SOC_ADC_DIGI_RESULT_BYTES * 3 * ADC_CONTINUOUS_FRAME_TRIPLES)
#define ADC_CONTINUOUS_STORE_SIZE (ADC_CONTINUOUS_FRAME_SIZE * 4)
#define ADC_CONTINUOUS_FRAMES_PER_IDLE_DELAY 32
#define ANALOG_DMA_CHANNEL_QUEUE_SIZE 64

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
static std::atomic<uint32_t> s_fault_code(0);
static std::atomic<uint32_t> s_samples_read(0);
static std::atomic<uint32_t> s_samples_rejected(0);
static std::atomic<uint32_t> s_channel_order_anomalies(0);
static std::atomic<uint32_t> s_partial_triples(0);
static std::atomic<uint32_t> s_frame_drops(0);
static std::atomic<uint32_t> s_pool_flushes(0);
static std::atomic<uint32_t> s_dma_channel_counts[8];
static std::atomic<uint32_t> s_dma_channel_last_raw[8];
static std::atomic<bool> s_calibration_lut_ready(false);
static float s_calibration_lut[ANALOG_ADC_MAX_CODE + 1] = {0.0f};

static adc_continuous_handle_t s_adc_continuous_handle = NULL;
static bool s_adc_continuous_started = false;
static uint32_t s_adc_continuous_sample_hz = 0;
static uint32_t s_adc_continuous_frames_since_delay = 0;

static void analog_publish_compat(uint32_t raw_an3, float an3,
                                  uint32_t raw_an5, float an5,
                                  uint32_t raw_an6, float an6,
                                  bool valid);

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

void analog_publish_triple(uint32_t raw_an3, float calibrated_an3,
                           uint32_t raw_an5, float calibrated_an5,
                           uint32_t raw_an6, float calibrated_an6,
                           bool valid) {
    uint64_t now_us = (uint64_t)esp_timer_get_time();
    if (valid) {
        uint64_t window_start = s_rate_window_start_us.load(std::memory_order_acquire);
        if (window_start == 0) {
            s_rate_window_start_us.store(now_us, std::memory_order_release);
            s_rate_window_triples.store(0, std::memory_order_release);
        } else {
            uint32_t triples = s_rate_window_triples.fetch_add(1, std::memory_order_acq_rel) + 1;
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

    s_snapshot_seq.fetch_add(1, std::memory_order_acq_rel);
    s_snapshot.raw_an3.store(raw_an3, std::memory_order_relaxed);
    s_snapshot.raw_an5.store(raw_an5, std::memory_order_relaxed);
    s_snapshot.raw_an6.store(raw_an6, std::memory_order_relaxed);
    s_snapshot.calibrated_an3.store(calibrated_an3, std::memory_order_relaxed);
    s_snapshot.calibrated_an5.store(calibrated_an5, std::memory_order_relaxed);
    s_snapshot.calibrated_an6.store(calibrated_an6, std::memory_order_relaxed);
    s_snapshot.timestamp_us.store(now_us, std::memory_order_relaxed);
    s_snapshot.valid.store(valid, std::memory_order_relaxed);

    if (valid) {
        s_consecutive_misses.store(0, std::memory_order_release);
        s_fault_code.store(0, std::memory_order_release);
    } else {
        analog_record_miss(ANALOG_FAULT_MISSING_TRIPLE);
    }

    s_snapshot_seq.fetch_add(1, std::memory_order_acq_rel);
}

void analog_get_status(AnalogRuntimeStatus* status) {
    if (status == nullptr) {
        return;
    }

    uint32_t min_us, max_us, avg_us;
    analog_get_latency_stats(&min_us, &max_us, &avg_us);

    AnalogSnapshotCopy snapshot = {};
    uint32_t seq_start = 0;
    uint32_t seq_end = 0;
    for (;;) {
        seq_start = s_snapshot_seq.load(std::memory_order_acquire);
        if ((seq_start & 1U) != 0) {
            continue;
        }
        snapshot.valid = s_snapshot.valid.load(std::memory_order_relaxed);
        snapshot.timestamp_us = s_snapshot.timestamp_us.load(std::memory_order_relaxed);
        snapshot.raw_an3 = s_snapshot.raw_an3.load(std::memory_order_relaxed);
        snapshot.raw_an5 = s_snapshot.raw_an5.load(std::memory_order_relaxed);
        snapshot.raw_an6 = s_snapshot.raw_an6.load(std::memory_order_relaxed);
        snapshot.calibrated_an3 = s_snapshot.calibrated_an3.load(std::memory_order_relaxed);
        snapshot.calibrated_an5 = s_snapshot.calibrated_an5.load(std::memory_order_relaxed);
        snapshot.calibrated_an6 = s_snapshot.calibrated_an6.load(std::memory_order_relaxed);
        seq_end = s_snapshot_seq.load(std::memory_order_acquire);
        if (seq_start == seq_end && (seq_end & 1U) == 0) {
            break;
        }
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
    status->fault_code = s_fault_code.load(std::memory_order_acquire);
    status->acquisition_mode = g_analog_acquisition_mode;
    status->samples_read = s_samples_read.load(std::memory_order_acquire);
    status->samples_rejected = s_samples_rejected.load(std::memory_order_acquire);
    status->channel_order_anomalies = s_channel_order_anomalies.load(std::memory_order_acquire);
    status->partial_triples = s_partial_triples.load(std::memory_order_acquire);
    status->frame_drops = s_frame_drops.load(std::memory_order_acquire);
    status->pool_flushes = s_pool_flushes.load(std::memory_order_acquire);
    status->calibration_lut_ready = s_calibration_lut_ready.load(std::memory_order_acquire);
}

bool analog_read_control_snapshot(AnalogControlSnapshot* snapshot,
                                  uint32_t last_seq,
                                  uint32_t max_age_us) {
    if (snapshot == nullptr) {
        return false;
    }

    AnalogRuntimeStatus status;
    analog_get_status(&status);
    if (!status.valid || !status.calibration_lut_ready) {
        analog_record_miss(status.calibration_lut_ready
                               ? ANALOG_FAULT_MISSING_TRIPLE
                               : ANALOG_FAULT_CALIBRATION_UNAVAILABLE);
        return false;
    }
    if (status.seq == last_seq || status.age_us > max_age_us) {
        analog_record_miss(ANALOG_FAULT_STALE_SAMPLE);
        return false;
    }

    snapshot->seq = status.seq;
    snapshot->age_us = status.age_us;
    snapshot->an3 = status.calibrated_an3;
    snapshot->an5 = status.calibrated_an5;
    snapshot->an6 = status.calibrated_an6;
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
                                  bool valid) {
    analog_publish_triple(raw_an3, an3, raw_an5, an5, raw_an6, an6, valid);

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
    handle_config.flags.flush_pool = 1;

    esp_err_t ret = adc_continuous_new_handle(&handle_config, &s_adc_continuous_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG_COMMON, "ADC continuous handle init failed: %s", esp_err_to_name(ret));
        s_adc_continuous_handle = NULL;
        return false;
    }

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

static void analog_queue_push(AnalogTripleAccumulator* acc, uint32_t index, uint32_t raw) {
    if (acc->count[index] == ANALOG_DMA_CHANNEL_QUEUE_SIZE) {
        acc->head[index] = (acc->head[index] + 1) % ANALOG_DMA_CHANNEL_QUEUE_SIZE;
        acc->count[index]--;
        s_channel_order_anomalies.fetch_add(1, std::memory_order_acq_rel);
        s_partial_triples.fetch_add(1, std::memory_order_acq_rel);
    }

    acc->raw[index][acc->tail[index]] = raw;
    acc->tail[index] = (acc->tail[index] + 1) % ANALOG_DMA_CHANNEL_QUEUE_SIZE;
    acc->count[index]++;
}

static uint32_t analog_queue_pop(AnalogTripleAccumulator* acc, uint32_t index) {
    uint32_t raw = acc->raw[index][acc->head[index]];
    acc->head[index] = (acc->head[index] + 1) % ANALOG_DMA_CHANNEL_QUEUE_SIZE;
    acc->count[index]--;
    return raw;
}

static void analog_publish_queued_triples(AnalogTripleAccumulator* acc) {
    while (acc->count[0] > 0 && acc->count[1] > 0 && acc->count[2] > 0) {
        uint32_t raw_an3 = analog_queue_pop(acc, 0);
        uint32_t raw_an5 = analog_queue_pop(acc, 1);
        uint32_t raw_an6 = analog_queue_pop(acc, 2);
        analog_publish_compat(raw_an3, analog_calibrate_raw_lut(raw_an3),
                              raw_an5, analog_calibrate_raw_lut(raw_an5),
                              raw_an6, analog_calibrate_raw_lut(raw_an6),
                              true);
    }
}

static void analog_continuous_accept_sample(AnalogTripleAccumulator* acc, uint32_t channel, uint32_t raw) {
    s_samples_read.fetch_add(1, std::memory_order_acq_rel);
    if (channel < 8) {
        s_dma_channel_counts[channel].fetch_add(1, std::memory_order_acq_rel);
        s_dma_channel_last_raw[channel].store(raw, std::memory_order_release);
    }

    uint32_t index;
    if (!analog_channel_to_queue_index(channel, &index)) {
        s_samples_rejected.fetch_add(1, std::memory_order_acq_rel);
        return;
    }

    analog_queue_push(acc, index, raw);
    analog_publish_queued_triples(acc);
}

static void analog_oneshot_step() {
    analog_init();

    float an3, an5, an6;
    uint32_t raw_an3, raw_an5, raw_an6;

    uint32_t start = esp_cpu_get_cycle_count();
    bool valid = analog_read_port_sample(AnalogPort::AN3, &raw_an3, &an3);
    valid = analog_read_port_sample(AnalogPort::AN5, &raw_an5, &an5) && valid;
    valid = analog_read_port_sample(AnalogPort::AN6, &raw_an6, &an6) && valid;
    uint32_t end = esp_cpu_get_cycle_count();
    analog_record_latency((end - start) / esp_rom_get_cpu_ticks_per_us());
    analog_publish_compat(raw_an3, an3, raw_an5, an5, raw_an6, an6, valid);

    uint32_t period_us = g_analog_acquisition_period_us;
    if (period_us >= 1000) {
        vTaskDelay(pdMS_TO_TICKS((period_us + 999) / 1000));
    } else if (period_us > 0) {
        esp_rom_delay_us(period_us);
    } else {
        taskYIELD();
    }
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

    uint8_t frame[ADC_CONTINUOUS_FRAME_SIZE];
    uint32_t out_len = 0;
    uint32_t start = esp_cpu_get_cycle_count();
    esp_err_t ret = adc_continuous_read(s_adc_continuous_handle, frame, sizeof(frame), &out_len, 20);
    uint32_t end = esp_cpu_get_cycle_count();

    if (ret == ESP_ERR_TIMEOUT) {
        return;
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
        return;
    }

    analog_record_latency((end - start) / esp_rom_get_cpu_ticks_per_us());
    if (out_len % SOC_ADC_DIGI_RESULT_BYTES != 0) {
        s_samples_rejected.fetch_add(1, std::memory_order_acq_rel);
    }
    for (uint32_t i = 0; i + SOC_ADC_DIGI_RESULT_BYTES <= out_len; i += SOC_ADC_DIGI_RESULT_BYTES) {
        adc_digi_output_data_t* sample = reinterpret_cast<adc_digi_output_data_t*>(&frame[i]);
        analog_continuous_accept_sample(acc, ADC_CONTINUOUS_GET_CHANNEL(sample), ADC_CONTINUOUS_GET_DATA(sample));
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
    AnalogTripleAccumulator acc;

    for (;;) {
        if (g_analog_acquisition_mode == ANALOG_ACQ_MODE_CONTINUOUS) {
            analog_continuous_step(&acc);
        } else {
            analog_continuous_stop();
            analog_reset_partial_triple(&acc);
            analog_oneshot_step();
        }
    }
}
