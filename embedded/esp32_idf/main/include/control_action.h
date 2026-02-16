/**
 * Implements the closed-loop control action from the MATLAB simulation:
 *   dtk = -K * (x_measured - x_target)
 */

#ifndef CONTROL_ACTION_H
#define CONTROL_ACTION_H

#include "esp_cpu.h"
#include "helper_common.h"
#include "helper_matrix.h"
#include "signal_controller.h"

#include <cmath>
#include <cstdint>

// Configuration
#define CONTROL_MIN_GAP_US 3 // Minimum dwell time per switching segment (µs)
#define CONTROL_MAX_DTK (MAX_SIGNAL_SIZE - 1)

// Control state flag (shared between cores)
extern volatile bool g_control_enabled;

// ADC shared readings
extern volatile float g_adc_an3;
extern volatile float g_adc_an5;
extern volatile float g_adc_an6;
extern volatile bool g_adc_fresh;

// Control API

// Conditions dtk values to ensure minimum gap constraints
static inline void condition_dtk(float *dtk_us, uint32_t p,
                                 const uint32_t *time_durations) {
    float alpha = 1.0f;
    const int32_t min_gap = CONTROL_MIN_GAP_US;

    uint32_t t2 = esp_cpu_get_cycle_count();

    for (uint32_t i = 0; i <= p; i++) {
        float gc; // gap_change[i]

        if (i == 0) {
            gc = dtk_us[0];
        } else if (i < p) {
            gc = dtk_us[i] - dtk_us[i - 1];
        } else {
            gc = -dtk_us[p - 1];
        }

        // Only constrain when the gap is shrinking (gc < 0)
        if (gc < 0.0f) {
            float gap_ref = (float)time_durations[i];
            float limit = ((float)min_gap - gap_ref) / gc;
            if (limit < alpha) {
                alpha = limit;
            }
        }
    }

    // Clamp alpha to [0, 1]
    if (alpha < 0.0f)
        alpha = 0.0f;
    if (alpha > 1.0f)
        alpha = 1.0f;

    // Scale dtk
    for (uint32_t j = 0; j < p; j++) {
        dtk_us[j] *= alpha;
    }

    uint32_t t3 = esp_cpu_get_cycle_count();
    g_log_duration.dtk_condition = (t3 - t2) / 240;
}

// Updates time durations based on dtk values
static inline void update_time_durations(DataSet *dataset, const float *dtk_us,
                                         uint32_t p, uint32_t N) {
    uint32_t t4 = esp_cpu_get_cycle_count();

    for (uint32_t i = 0; i < N; i++) {
        float delta_i;

        if (i == 0) {
            delta_i = dtk_us[0];
        } else if (i < p) {
            delta_i = dtk_us[i] - dtk_us[i - 1];
        } else {
            delta_i = -dtk_us[p - 1];
        }

        int32_t new_duration =
            (int32_t)dataset->time_durations[i] + (int32_t)roundf(delta_i);

        if (new_duration < 1)
            new_duration = 1;

        dataset->time_durations[i] = (uint32_t)new_duration;
    }

    uint32_t t5 = esp_cpu_get_cycle_count();
    g_log_duration.update_signal_with_dtk = (t5 - t4) / 240;
}

static inline bool compute_control_correction(DataSet *dataset, float an3,
                                              float an5, float an6,
                                              float *dtk_us) {
    const uint32_t N = dataset->size;
    const uint32_t p = N - 1;

    if (p == 0 || !dataset->gain_k.is_valid) {
        return false;
    }

    // 1. Compute error
    float e1 = an3 - dataset->target[0];
    float e2 = an5 - dataset->target[1];
    float e3 = an6 - dataset->target[2];

    // 2. Compute control: dtk = -K * e
    uint32_t t0 = esp_cpu_get_cycle_count();
    matrix_multiply_vector3(dataset->gain_k, e1, e2, e3, dtk_us);
    uint32_t t1 = esp_cpu_get_cycle_count();
    g_log_duration.matrix_multiply_us = (t1 - t0) / 240;

    // Negate: dtk = -K * e
    for (uint32_t j = 0; j < p; j++) {
        dtk_us[j] = -dtk_us[j];
    }

    // 3. Condition dtk
    condition_dtk(dtk_us, p, dataset->time_durations);

    // Store dtk for telemetry
    for (uint32_t j = 0; j < p && j < MAX_SIGNAL_SIZE; j++) {
        dataset->time_us_diff[j] = (int32_t)roundf(dtk_us[j]);
    }

    return true;
}

#endif // CONTROL_ACTION_H
