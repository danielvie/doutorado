/**
 * @file control_action.h
 * @brief Proportional control law for multi-cell Buck-Boost converter (ESP32)
 *
 * Implements the closed-loop control action from the MATLAB simulation:
 *   dtk = -K * (x_measured - x_target)
 *
 * The control output dtk is a vector of time deviations (µs) applied to each
 * switching instant within the cycle. Before being applied, dtk is scaled by
 * a factor alpha ∈ [0, 1] to ensure no switching interval becomes shorter
 * than the minimum dwell time (min_gap).
 *
 * Theory:
 *   The converter has N segments per cycle, each with a duration
 * time_durations[i]. The proportional controller uses an LQR gain K (p×3, where
 * p = N-1) to compute time deviations dtk[j] for switching instants j = 1..N-1
 * (the first instant is fixed at t=0, and the last is the cycle end).
 *
 *   dtk[j] shifts the j-th switching instant: t'_j = t_j + dtk[j]
 *   This changes two adjacent durations:
 *     duration[j-1] += dtk[j]   (previous segment grows)
 *     duration[j]   -= dtk[j]   (current segment shrinks)
 *   But since dtk shifts cumulative times, the net effect on durations is:
 *     new_duration[i] = base_duration[i] + (dtk[i] - dtk[i-1])
 *   with dtk[0] = dtk[N] = 0.
 *
 * Mapping: u = K(p×3) × e(3×1) → dtk(p×1) → modifies time_durations[]
 *   u[0] → shifts switching instant 1 (boundary between segment 0 and 1)
 *   u[1] → shifts switching instant 2 (boundary between segment 1 and 2)
 *   ...
 *   u[p-1] → shifts switching instant p (boundary between segment p-1 and p)
 */

#ifndef CONTROL_ACTION_H
#define CONTROL_ACTION_H

#include <cmath>
#include <cstdint>


// Forward declarations (from existing codebase)
struct DataSet;
struct MatrixData;
struct LogDuration;

extern LogDuration g_log_duration;

bool matrix_multiply_vector3(MatrixData &M, float x1, float x2, float x3,
                             float *result);

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Minimum dwell time per switching segment (µs).
/// Must match the MATLAB config.c_time value (typically 3 µs).
#define CONTROL_MIN_GAP_US 3

/// Maximum number of control outputs (p = N_segments - 1)
#define CONTROL_MAX_DTK (MAX_SIGNAL_SIZE - 1)

// ---------------------------------------------------------------------------
// Control API
// ---------------------------------------------------------------------------

/**
 * @brief Execute one control action: read state, compute dtk, apply to signal.
 *
 * Call this once per control period (every g_cycle_nrun signal cycles).
 * It is safe to call with interrupts disabled — no allocation, no RTOS calls.
 *
 * @param dataset   Active DataSet (modified in-place: time_durations updated)
 * @param an3       Measured voltage on AN3 (vC1) [V]
 * @param an5       Measured voltage on AN5 (vC2) [V]
 * @param an6       Measured voltage on AN6 (iL, via shunt) [V]
 */
static inline void control_action(DataSet *dataset, float an3, float an5,
                                  float an6) {
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

  // K * e → dtk_raw (positive direction)
  // Then negate: dtk = -K*e
  matrix_multiply_vector3(dataset->gain_k, e1, e2, e3, dtk_us);

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
  //    Algorithm (from MATLAB Controllers.condition_dtk):
  //      Build augmented dtk: [0, dtk[0], ..., dtk[p-1], 0]
  //      gap_change[i] = dtk_aug[i+1] - dtk_aug[i]
  //      For each gap that shrinks (gap_change < 0):
  //        alpha ≤ (min_gap - gap_ref[i]) / gap_change[i]
  //      alpha = clamp(min(alphas), 0, 1)
  //      dtk = alpha * dtk
  // -----------------------------------------------------------------------
  {
    // The "gaps" are the current time_durations (which are the diffs of
    // cumulative switching times).
    float alpha = 1.0f;
    const int32_t min_gap = CONTROL_MIN_GAP_US;

    // dtk_aug = [0, dtk[0], ..., dtk[p-1], 0]  (size: N+1)
    // gap_change[i] = dtk_aug[i+1] - dtk_aug[i]  (size: N)
    // gap_ref[i] = time_durations[i]

    // Compute gap_change and find minimum alpha
    // gap_change[0] = dtk_aug[1] - dtk_aug[0] = dtk[0] - 0 = dtk[0]
    // gap_change[i] = dtk[i] - dtk[i-1]   for 1 <= i < p
    // gap_change[p] = 0 - dtk[p-1] = -dtk[p-1]

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
  }

  // -----------------------------------------------------------------------
  // 4. Apply dtk to time_durations[]
  //
  //    dtk[j] shifts the (j+1)-th cumulative switching instant.
  //    This affects two adjacent durations:
  //
  //      cumulative_time[0] = 0                 (fixed)
  //      cumulative_time[j] = sum(durations[0..j-1])
  //      cumulative_time'[j] = cumulative_time[j] + dtk[j-1]
  //
  //      new_duration[i] = cumulative_time'[i+1] - cumulative_time'[i]
  //                      = duration[i] + dtk[i] - dtk[i-1]
  //
  //    with dtk[-1] = dtk[N-1] = 0 (boundary conditions).
  // -----------------------------------------------------------------------
  {
    for (uint32_t i = 0; i < N; i++) {
      float delta_i;

      if (i == 0) {
        // First segment: only affected by dtk[0] (right boundary shifts)
        delta_i = dtk_us[0];
      } else if (i < p) {
        // Interior segments: affected by both boundaries
        delta_i = dtk_us[i] - dtk_us[i - 1];
      } else {
        // Last segment: only affected by dtk[p-1] (left boundary shifts)
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
  }

  // Store dtk for telemetry / debugging
  for (uint32_t j = 0; j < p && j < MAX_SIGNAL_SIZE; j++) {
    dataset->time_us_diff[j] = (int32_t)roundf(dtk_us[j]);
  }
}

// ---------------------------------------------------------------------------
// Integration point in signal_loop_task
// ---------------------------------------------------------------------------
//
// In the signal loop, call control_action at the START of a new cycle,
// every g_cycle_nrun cycles. The ADC reads should happen at the END of the
// PREVIOUS cycle (after the last segment) so the measurement is fresh.
//
// Example integration:
//
//   for (int i = 0; i < dataset->size; i++) {
//       // Apply pin states ...
//       // Wait for duration ...
//
//       // At the end of the last segment, read ADC
//       if (i == dataset->size - 1) {
//           float an3 = analog_read_port(AnalogPort::AN3);
//           float an5 = analog_read_port(AnalogPort::AN5);
//           float an6 = analog_read_port(AnalogPort::AN6);
//
//           // Trigger control every g_cycle_nrun cycles
//           g_cycle_count = (g_cycle_count + 1) % g_cycle_nrun;
//           if (g_cycle_count == 0) {
//               uint32_t t0 = esp_cpu_get_cycle_count();
//               control_action(dataset, an3, an5, an6);
//               uint32_t t1 = esp_cpu_get_cycle_count();
//               g_log_duration.matrix_multiply_us = (t1 - t0) / 240; //
//               cycles→µs
//           }
//       }
//   }
//

#endif // CONTROL_ACTION_H
