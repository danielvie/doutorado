/**
 * Standalone test for the control computation pipeline.
 *
 * Reproduces the ESP32 control logic on the host PC so you can
 * verify results without flashing the board.
 *
 * Build:
 *   mkdir build && cd build && cmake .. && cmake --build .
 * Run:
 *   ./control_test        (Linux/macOS)
 *   .\control_test.exe    (Windows)
 */

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>

// =====================================================================
// Replicated types & constants (mirror of the ESP32 project)
// =====================================================================

#define MAX_SIGNAL_SIZE   100
#define MAX_MATRIX_ELEMENTS 100

#define CONTROL_MIN_GAP_US 3
#define CONTROL_MAX_DTK   (MAX_SIGNAL_SIZE - 1)

struct MatrixData {
    float    values[MAX_MATRIX_ELEMENTS];
    uint16_t size;
    uint16_t rows, cols;
    bool     is_valid;
};

struct DataSet {
    uint32_t   time_durations[MAX_SIGNAL_SIZE];
    uint32_t   modes_d4[MAX_SIGNAL_SIZE];
    uint32_t   modes_d5[MAX_SIGNAL_SIZE];
    uint32_t   modes_d6[MAX_SIGNAL_SIZE];
    uint32_t   size;
    int32_t    time_us_diff[MAX_SIGNAL_SIZE];
    float      target[3];
    MatrixData gain_k;
};

// =====================================================================
// Replicated functions (no ESP-IDF dependencies)
// =====================================================================

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

static void compute_duration_corrections(const uint32_t *time_durations,
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

static bool compute_control_correction(DataSet *dataset,
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

    printf("  errors:  e1=%.6f  e2=%.6f  e3=%.6f\n", e1, e2, e3);

    // 2. Compute dtk = K * e
    matrix_multiply_vector3(dataset->gain_k, e1, e2, e3, dtk_us);

    printf("  K*e (raw):");
    for (uint32_t j = 0; j < p; j++) printf("  %.6f", dtk_us[j]);
    printf("\n");

    // 3. Negate: dtk = -K * e
    for (uint32_t j = 0; j < p; j++) {
        dtk_us[j] = -dtk_us[j];
    }

    printf("  -K*e:    ");
    for (uint32_t j = 0; j < p; j++) printf("  %.6f", dtk_us[j]);
    printf("\n");

    // 4. Condition dtk
    condition_dtk(dtk_us, p, dataset->time_durations);

    // 5. Store for telemetry
    for (uint32_t j = 0; j < p && j < MAX_SIGNAL_SIZE; j++) {
        dataset->time_us_diff[j] = (int32_t)roundf(dtk_us[j]);
    }

    return true;
}

// =====================================================================
// Test
// =====================================================================

int main() {
    printf("====== CONTROL COMPUTATION TEST ======\n\n");

    // -----------------------------------------------------------------
    // 1. Build test DataSet
    // -----------------------------------------------------------------
    DataSet ds = {};
    ds.size = 6;

    ds.time_durations[0] = 47;
    ds.time_durations[1] = 47;
    ds.time_durations[2] = 47;
    ds.time_durations[3] = 47;
    ds.time_durations[4] = 47;
    ds.time_durations[5] = 47;

    ds.target[0] = 1.6667f;
    ds.target[1] = 3.3367f;
    ds.target[2] = 0.0344f;

    // K (5×3)
    ds.gain_k.rows     = 5;
    ds.gain_k.cols     = 3;
    ds.gain_k.size     = 15;
    ds.gain_k.is_valid = true;

    ds.gain_k.values[0]  = -0.0023f;
    ds.gain_k.values[1]  =  0.0023f;
    ds.gain_k.values[2]  = -0.0283f;
    ds.gain_k.values[3]  = -0.0045f;
    ds.gain_k.values[4]  = -0.0023f;
    ds.gain_k.values[5]  =  0.0285f;
    ds.gain_k.values[6]  = -0.0046f;
    ds.gain_k.values[7]  = -0.0091f;
    ds.gain_k.values[8]  = -0.0564f;
    ds.gain_k.values[9]  =  0.0023f;
    ds.gain_k.values[10] = -0.0022f;
    ds.gain_k.values[11] =  0.0299f;
    ds.gain_k.values[12] =  0.0046f;
    ds.gain_k.values[13] =  0.0023f;
    ds.gain_k.values[14] = -0.0296f;

    // -----------------------------------------------------------------
    // 2. Simulated ADC readings
    // -----------------------------------------------------------------
    float an3 = -0.0077f;
    float an5 =  0.0073f;
    float an6 =  0.0337f;

    const uint32_t N = ds.size;
    const uint32_t p = N - 1;

    printf("Dataset:    size=%u, p=%u\n", N, p);
    printf("Durations:  [");
    for (uint32_t i = 0; i < N; i++) printf("%s%u", i ? ", " : "", ds.time_durations[i]);
    printf("]\n");
    printf("Targets:    [%.4f, %.4f, %.4f]\n", ds.target[0], ds.target[1], ds.target[2]);
    printf("ADC:        [%.4f, %.4f, %.4f]\n\n", an3, an5, an6);

    // -----------------------------------------------------------------
    // 3. Run control computation
    // -----------------------------------------------------------------
    float dtk[CONTROL_MAX_DTK] = {};

    printf("--- compute_control_correction ---\n");
    bool ok = compute_control_correction(&ds, an3, an5, an6, dtk);
    printf("Result: %s\n\n", ok ? "OK" : "SKIP");

    if (ok) {
        printf("--- dtk (conditioned) ---\n");
        for (uint32_t j = 0; j < p; j++) {
            printf("  dtk[%u] = %10.6f   (rounded: %d)\n",
                   j, dtk[j], ds.time_us_diff[j]);
        }

        // -------------------------------------------------------------
        // 4. Compute duration corrections
        // -------------------------------------------------------------
        int32_t corrections[MAX_SIGNAL_SIZE] = {};
        compute_duration_corrections(ds.time_durations, dtk, corrections, p, N);

        printf("\n--- Duration corrections ---\n");
        printf("  %4s  %6s  %6s  %6s\n", "seg", "base", "corr", "final");
        for (uint32_t i = 0; i < N; i++) {
            int32_t final_dur = (int32_t)ds.time_durations[i] + corrections[i];
            printf("  [%2u]  %6u  %+6d  %6d\n",
                   i, ds.time_durations[i], corrections[i], final_dur);
        }

        // Verify sum invariant: sum of corrections should be ~0
        int32_t sum_corr = 0;
        for (uint32_t i = 0; i < N; i++) sum_corr += corrections[i];
        printf("\n  Sum of corrections: %d (should be ~0)\n", sum_corr);
    }

    printf("\n====== TEST COMPLETE ======\n");
    return 0;
}
