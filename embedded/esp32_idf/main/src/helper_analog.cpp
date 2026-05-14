#include "helper_analog.h"
#include <atomic>
#include <cstdint>
#include <cstring>

#include "esp_timer.h"

#define LATENCY_WINDOW_SIZE 128
#define ANALOG_TARGET_TRIPLES_PER_CYCLE 4
#define ANALOG_FAULT_REPEATED_MISS 1
static uint32_t s_latency_buffer[LATENCY_WINDOW_SIZE] = {0};
static std::atomic<size_t> s_latency_index(0);
static std::atomic<uint32_t> s_seq(0);
static std::atomic<bool> s_valid(false);
static std::atomic<uint64_t> s_timestamp_us(0);
static std::atomic<uint32_t> s_measured_triples_per_second(0);
static std::atomic<uint32_t> s_raw_an3(0);
static std::atomic<uint32_t> s_raw_an5(0);
static std::atomic<uint32_t> s_raw_an6(0);
static std::atomic<float> s_calibrated_an3(0.0f);
static std::atomic<float> s_calibrated_an5(0.0f);
static std::atomic<float> s_calibrated_an6(0.0f);
static std::atomic<uint32_t> s_overflow_count(0);
static std::atomic<uint32_t> s_miss_count(0);
static std::atomic<uint32_t> s_consecutive_misses(0);
static std::atomic<uint32_t> s_fault_code(0);

void analog_record_latency(uint32_t us) {
    // Lock-free increment and wrap
    size_t idx = s_latency_index.fetch_add(1, std::memory_order_relaxed) % LATENCY_WINDOW_SIZE;
    s_latency_buffer[idx] = us;
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
    uint64_t prev_us = s_timestamp_us.exchange(now_us, std::memory_order_acq_rel);

    if (prev_us > 0 && now_us > prev_us) {
        uint64_t delta_us = now_us - prev_us;
        s_measured_triples_per_second.store((uint32_t)(1000000ULL / delta_us), std::memory_order_release);
    }

    s_raw_an3.store(raw_an3, std::memory_order_release);
    s_raw_an5.store(raw_an5, std::memory_order_release);
    s_raw_an6.store(raw_an6, std::memory_order_release);
    s_calibrated_an3.store(calibrated_an3, std::memory_order_release);
    s_calibrated_an5.store(calibrated_an5, std::memory_order_release);
    s_calibrated_an6.store(calibrated_an6, std::memory_order_release);
    s_valid.store(valid, std::memory_order_release);

    if (valid) {
        s_consecutive_misses.store(0, std::memory_order_release);
        s_fault_code.store(0, std::memory_order_release);
    } else {
        uint32_t misses = s_consecutive_misses.fetch_add(1, std::memory_order_acq_rel) + 1;
        s_miss_count.fetch_add(1, std::memory_order_acq_rel);
        if (misses >= 3) {
            s_fault_code.store(ANALOG_FAULT_REPEATED_MISS, std::memory_order_release);
        }
    }

    s_seq.fetch_add(1, std::memory_order_acq_rel);
}

void analog_get_status(AnalogRuntimeStatus* status) {
    if (status == nullptr) {
        return;
    }

    uint32_t min_us, max_us, avg_us;
    analog_get_latency_stats(&min_us, &max_us, &avg_us);

    uint64_t timestamp_us = s_timestamp_us.load(std::memory_order_acquire);
    uint64_t now_us = (uint64_t)esp_timer_get_time();
    uint64_t age_us = (timestamp_us > 0 && now_us >= timestamp_us) ? now_us - timestamp_us : 0;

    std::memset(status, 0, sizeof(*status));
    status->seq = s_seq.load(std::memory_order_acquire);
    status->valid = s_valid.load(std::memory_order_acquire);
    status->timestamp_us = timestamp_us;
    status->age_us = (age_us > UINT32_MAX) ? UINT32_MAX : (uint32_t)age_us;
    status->target_triples_per_cycle = ANALOG_TARGET_TRIPLES_PER_CYCLE;
    status->measured_triples_per_second = s_measured_triples_per_second.load(std::memory_order_acquire);
    status->raw_an3 = s_raw_an3.load(std::memory_order_acquire);
    status->raw_an5 = s_raw_an5.load(std::memory_order_acquire);
    status->raw_an6 = s_raw_an6.load(std::memory_order_acquire);
    status->calibrated_an3 = s_calibrated_an3.load(std::memory_order_acquire);
    status->calibrated_an5 = s_calibrated_an5.load(std::memory_order_acquire);
    status->calibrated_an6 = s_calibrated_an6.load(std::memory_order_acquire);
    status->latency_min_us = min_us;
    status->latency_avg_us = avg_us;
    status->latency_p95_us = analog_latency_p95();
    status->latency_max_us = max_us;
    status->overflow_count = s_overflow_count.load(std::memory_order_acquire);
    status->miss_count = s_miss_count.load(std::memory_order_acquire);
    status->consecutive_misses = s_consecutive_misses.load(std::memory_order_acquire);
    status->fault_code = s_fault_code.load(std::memory_order_acquire);
}


// handle for the ADC unit
static adc_oneshot_unit_handle_t adc1_handle = NULL;
static const char* TAG_COMMON = "HELPER_COMMON";

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
    
    ESP_LOGI(TAG_COMMON, "Analog Ports Initialized.");
}

float calib_from[] = {0.00, 0.07, 0.17, 0.26, 0.36, 0.46, 0.56, 0.66, 0.76, 0.86, 0.96, 1.06, 1.16, 1.27, 1.37, 1.46, 1.56, 1.67, 1.76, 1.86, 1.96, 2.06, 2.16, 2.27, 2.37, 2.49, 2.61, 2.75, 2.90, 3.07, 3.26, 3.30, 3.30};
float calib_to[] = {0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00, 1.10, 1.20, 1.30, 1.40, 1.50, 1.60, 1.70, 1.80, 1.90, 2.00, 2.10, 2.20, 2.30, 2.40, 2.50, 2.60, 2.70, 2.80, 2.90, 3.00, 3.10, 3.20, 3.30};
int calib_numel = sizeof(calib_from) / sizeof(calib_from[0]);

float esp32_calibration(float value) {


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
        float voltage = ((float)raw_val/ADC_MAX)*VOLTAGE_MAX;
        voltage = esp32_calibration(voltage);
        if (raw != nullptr) *raw = (uint32_t)raw_val;
        if (calibrated != nullptr) *calibrated = voltage;
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
