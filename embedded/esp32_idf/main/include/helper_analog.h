
#pragma once

#include "esp_log.h"
#include "esp_adc/adc_oneshot.h"
#include <string>

// ADC Configuration Constants
#define ADC_MAX 4095.0      // 12-bit ADC maximum value (2^12 - 1)
#define VOLTAGE_MAX 3.3     // Maximum voltage reference (3.3V)

enum class AnalogPort {
    AN1 = 1,    // ADC1_CHANNEL_3 (GPIO 39)
    AN2 = 2,    // ADC1_CHANNEL_5 (GPIO 33)
    AN3 = 3,    // ADC1_CHANNEL_4 (GPIO 32)
    AN4 = 4,    // ADC1_CHANNEL_7 (GPIO 35)
    AN5 = 5,    // ADC1_CHANNEL_6 (GPIO 34)
    AN6 = 6     // ADC1_CHANNEL_0 (GPIO 36)
};

struct AnalogRuntimeStatus {
    uint32_t seq;
    bool valid;
    uint64_t timestamp_us;
    uint32_t age_us;
    uint32_t target_triples_per_cycle;
    uint32_t measured_triples_per_second;
    uint32_t raw_an3;
    uint32_t raw_an5;
    uint32_t raw_an6;
    float calibrated_an3;
    float calibrated_an5;
    float calibrated_an6;
    uint32_t latency_min_us;
    uint32_t latency_avg_us;
    uint32_t latency_p95_us;
    uint32_t latency_max_us;
    uint32_t overflow_count;
    uint32_t miss_count;
    uint32_t consecutive_misses;
    uint32_t fault_code;
    uint32_t acquisition_mode;
    uint32_t samples_read;
    uint32_t samples_rejected;
    uint32_t channel_order_anomalies;
    uint32_t partial_triples;
    uint32_t frame_drops;
    uint32_t pool_flushes;
    bool calibration_lut_ready;
};

struct AnalogControlSnapshot {
    uint32_t seq;
    uint32_t age_us;
    float an3;
    float an5;
    float an6;
};

#define ANALOG_FAULT_NONE 0
#define ANALOG_FAULT_REPEATED_MISS 1
#define ANALOG_FAULT_STALE_SAMPLE 2
#define ANALOG_FAULT_MISSING_TRIPLE 3
#define ANALOG_FAULT_DMA_OVERFLOW 4
#define ANALOG_FAULT_CALIBRATION_UNAVAILABLE 5
#define ANALOG_FAULT_SNAPSHOT_CONTENTION 6

void analog_init();
float analog_read_port(AnalogPort port);
bool analog_read_port_sample(AnalogPort port, uint32_t* raw, float* calibrated);
float analog_calibrate_raw(uint32_t raw);
float analog_calibrate_raw_lut(uint32_t raw);

// Latency tracking for performance monitoring
void analog_record_latency(uint32_t us);
void analog_record_overflow();
void analog_record_miss(uint32_t fault_code);
void analog_get_latency_stats(uint32_t* min, uint32_t* max, uint32_t* avg);
void analog_publish_triple(uint32_t raw_an3, float calibrated_an3,
                           uint32_t raw_an5, float calibrated_an5,
                           uint32_t raw_an6, float calibrated_an6,
                           uint64_t sample_timestamp_us,
                           bool valid);
void analog_get_status(AnalogRuntimeStatus* status);
uint32_t analog_get_consecutive_misses(void);
// Smallest measurement age the acquisition pipeline can deliver (frame
// accumulation + scheduling margin); control-age budgets below this value
// would reject every sample regardless of signal timing.
uint32_t analog_min_snapshot_age_us(void);
bool analog_read_control_snapshot(AnalogControlSnapshot* snapshot,
                                  uint32_t last_seq,
                                  uint32_t max_age_us);
std::string analog_get_dma_debug_json();
void analog_acquisition_task(void* arg);
