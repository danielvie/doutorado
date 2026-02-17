#include "control.h"

static bool matrix_multiply_vector3(const MatrixData &M,
                                    float x1, float x2, float x3,
                                    float *result) {
    const float *d = M.values;
    for (int i = 0; i < M.rows; ++i) {
        result[i] = d[i * M.cols + 0] * x1
                  + d[i * M.cols + 1] * x2
                  + d[i * M.cols + 2] * x3;
    }
    return true;
}

static void condition_dtk(float *dtk_us, uint32_t p,
                           const uint32_t *time_durations) {
    float alpha = 1.0f;
    const int32_t min_gap = CONTROL_MIN_GAP_US;

    for (uint32_t i = 0; i <= p; i++) {
        float gc;

        if (i == 0) {
            gc = dtk_us[0];
        } else if (i < p) {
            gc = dtk_us[i] - dtk_us[i - 1];
        } else {
            gc = -dtk_us[p - 1];
        }

        if (gc < 0.0f) {
            float gap_ref = (float)time_durations[i];
            float limit   = ((float)min_gap - gap_ref) / gc;
            if (limit < alpha) {
                alpha = limit;
            }
        }
    }

    if (alpha < 0.0f) alpha = 0.0f;
    if (alpha > 1.0f) alpha = 1.0f;

    printf("  [condition_dtk] alpha = %.6f\n", alpha);

    for (uint32_t j = 0; j < p; j++) {
        dtk_us[j] *= alpha;
    }
}

void compute_duration_corrections(const uint32_t *time_durations,
                                          const float *dtk_us,
                                          int32_t *corrections,
                                          uint32_t p, uint32_t N) {
    for (uint32_t i = 0; i < N; i++) {
        float delta_i;

        if (i == 0) {
            delta_i = dtk_us[0];
        } else if (i < p) {
            delta_i = dtk_us[i] - dtk_us[i - 1];
        } else {
            delta_i = -dtk_us[p - 1];
        }

        int32_t correction     = (int32_t)roundf(delta_i);
        int32_t final_duration = (int32_t)time_durations[i] + correction;

        if (final_duration < 1) {
            correction = 1 - (int32_t)time_durations[i];
        }

        corrections[i] = correction;
    }
}

bool compute_control_correction(DataSet *dataset,
                                        float an3, float an5, float an6,
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

    printf("%13s","errors:");
    printf("  e1=%.6f  e2=%.6f  e3=%.6f\n", e1, e2, e3);

    // 2. Compute dtk = K * e
    matrix_multiply_vector3(dataset->gain_k, e1, e2, e3, dtk_us);

    printf("%13s", "K*e (raw):");
    for (uint32_t j = 0; j < p; j++) printf("%14.6f", dtk_us[j]);
    printf("\n");

    // 3. Negate: dtk = -K * e
    for (uint32_t j = 0; j < p; j++) {
        dtk_us[j] = -dtk_us[j];
    }

    printf("%13s", "-K*e:");
    for (uint32_t j = 0; j < p; j++) printf("%14.6f", dtk_us[j]);
    printf("\n");

    // 4. Condition dtk
    condition_dtk(dtk_us, p, dataset->time_durations);

    // 5. Store for telemetry
    for (uint32_t j = 0; j < p && j < MAX_SIGNAL_SIZE; j++) {
        dataset->time_us_diff[j] = (int32_t)roundf(dtk_us[j]);
    }

    return true;
}