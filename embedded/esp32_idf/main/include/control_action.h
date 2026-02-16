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

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Minimum dwell time per switching segment (µs).
/// Must match the MATLAB config.c_time value (typically 3 µs).
#define CONTROL_MIN_GAP_US 3

/// Maximum number of control outputs (p = N_segments - 1)
#define CONTROL_MAX_DTK (MAX_SIGNAL_SIZE - 1)

// ---------------------------------------------------------------------------
// Control state flag (shared between cores)
// ---------------------------------------------------------------------------

/// Control starts OFF; enabled via BLE command "ctrl_on"
extern volatile bool g_control_enabled;

// ---------------------------------------------------------------------------
// ADC shared readings (written by Core 0, read by Core 1)
// ---------------------------------------------------------------------------

extern volatile float g_adc_an3;
extern volatile float g_adc_an5;
extern volatile float g_adc_an6;
extern volatile bool  g_adc_fresh; // true when new readings available

// ---------------------------------------------------------------------------
// Control API
// ---------------------------------------------------------------------------

/**
 * dataset   Active DataSet (modified in-place: time_durations updated)
 * an3       Measured voltage on AN3 (vC1) [V]
 * an5       Measured voltage on AN5 (vC2) [V]
 * an6       Measured voltage on AN6 (iL, via shunt) [V]
 */
static inline void control_action(DataSet *dataset, float an3, float an5, float an6) {
  const uint32_t N = dataset->size; // Number of segments
  const uint32_t p = N - 1;         // Number of controllable instants

  if (p == 0 || !dataset->gain_k.is_valid) {
    return; // Nothing to control
  }

  // -----------------------------------------------------------------------
  // 1. Compute error: e = x_measured - x_target
  // -----------------------------------------------------------------------
  float e1 = an3 - dataset->target[0]; // vC1 error
  float e2 = an5 - dataset->target[1]; // vC2 error
  float e3 = an6 - dataset->target[2]; // iL error

  // -----------------------------------------------------------------------
  // 2. Compute control: dtk = -K * e  (result in µs)
  //
  //    K is (p × 3), e is (3 × 1) → dtk is (p × 1)
  //    The gain K already maps to microseconds in the MATLAB export.
  // -----------------------------------------------------------------------
  float dtk_us[CONTROL_MAX_DTK];

  uint32_t t0 = esp_cpu_get_cycle_count();
  matrix_multiply_vector3(dataset->gain_k, e1, e2, e3, dtk_us);
  uint32_t t1 = esp_cpu_get_cycle_count();
  g_log_duration.matrix_multiply_us = (t1 - t0) / 240; // cycles → µs

  // Negate: dtk = -K * e
  for (uint32_t j = 0; j < p; j++) {
    dtk_us[j] = -dtk_us[j];
  }

  // -----------------------------------------------------------------------
  // 3. Constraint conditioning: scale dtk by alpha ∈ [0,1]
  //
  //    Ensures that after applying dtk, every switching interval
  //    remains ≥ CONTROL_MIN_GAP_US.
  //
  // -----------------------------------------------------------------------
  {
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
        float gap_ref = (float)dataset->time_durations[i];
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
    g_log_duration.dtk_condition = (t3 - t2) / 240; // cycles → µs
  }

  // -----------------------------------------------------------------------
  // 4. Apply dtk to time_durations[]
  //
  //    new_duration[i] = base_duration[i] + (dtk[i] - dtk[i-1])
  //    with dtk[-1] = dtk[N-1] = 0 (boundary conditions).
  // -----------------------------------------------------------------------
  {
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

      // Round to integer µs and apply
      int32_t new_duration =
          (int32_t)dataset->time_durations[i] + (int32_t)roundf(delta_i);

      // Safety clamp: duration must be at least 1 µs
      if (new_duration < 1)
        new_duration = 1;

      dataset->time_durations[i] = (uint32_t)new_duration;
    }

    uint32_t t5 = esp_cpu_get_cycle_count();
    g_log_duration.update_signal_with_dtk = (t5 - t4) / 240; // cycles → µs
  }

  // Store dtk for telemetry / debugging
  for (uint32_t j = 0; j < p && j < MAX_SIGNAL_SIZE; j++) {
    dataset->time_us_diff[j] = (int32_t)roundf(dtk_us[j]);
  }
}

#endif // CONTROL_ACTION_H
