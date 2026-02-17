#include "control.h"

// =====================================================================
// Test
// =====================================================================

struct DataAnalogRead {
    float an3;
    float an5;
    float an6;
};

void set_test_values(DataAnalogRead &an, DataSet &ds);

int main() {
    printf("====== CONTROL COMPUTATION TEST ======\n\n");

    // -----------------------------------------------------------------
    // 1. Build test DataSet
    // -----------------------------------------------------------------
    DataAnalogRead an = {};
    DataSet ds = {};

    set_test_values(an, ds);

    // -----------------------------------------------------------------
    // 2. Simulated ADC readings
    // -----------------------------------------------------------------
    float an3 = an.an3;
    float an5 = an.an5;
    float an6 = an.an6;

    const uint32_t N = ds.size;
    const uint32_t p = N - 1;

    printf("Dataset:    size=%u, p=%u\n", N, p);
    printf("Durations:  [");
    for (uint32_t i = 0; i < N; i++)
        printf("%s%u", i ? ", " : "", ds.time_durations[i]);
    printf("]\n");
    printf("Targets:    [%.4f, %.4f, %.4f]\n", ds.target[0], ds.target[1],
           ds.target[2]);
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
            printf("  dtk[%u] = %10.6f   (rounded: %d)\n", j, dtk[j],
                   ds.time_us_diff[j]);
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
            printf("  [%2u]  %6u  %+6d  %6d\n", i, ds.time_durations[i],
                   corrections[i], final_dur);
        }

        // Verify sum invariant: sum of corrections should be ~0
        int32_t sum_corr = 0;
        for (uint32_t i = 0; i < N; i++)
            sum_corr += corrections[i];
        printf("\n  Sum of corrections: %d (should be ~0)\n", sum_corr);
    }

    printf("\n====== TEST COMPLETE ======\n");
    return 0;
}

void set_test_values(DataAnalogRead &an, DataSet &ds) {

    // ============================================
    // C++ Test Values  (k = 10, log = run)
    // ============================================

    // --- time_durations ---
    ds.size = 6;
    ds.time_durations[0] = 37;
    ds.time_durations[1] = 56;
    ds.time_durations[2] = 37;
    ds.time_durations[3] = 56;
    ds.time_durations[4] = 37;
    ds.time_durations[5] = 56;

    // --- x_target ---
    ds.target[0] = 1.66448f;
    ds.target[1] = 3.3377f;
    ds.target[2] = 0.0548073f;

    // --- gain_k (K matrix, row-major) ---
    ds.gain_k.rows = 5;
    ds.gain_k.cols = 3;
    ds.gain_k.size = 15;
    ds.gain_k.is_valid = true;
    ds.gain_k.values[0] = 0.00142105f;
    ds.gain_k.values[1] = 0.00288248f;
    ds.gain_k.values[2] = 0.0284068f;
    ds.gain_k.values[3] = -0.00143276f;
    ds.gain_k.values[4] = -0.00290369f;
    ds.gain_k.values[5] = -0.0286929f;
    ds.gain_k.values[6] = -0.00284902f;
    ds.gain_k.values[7] = -0.00137942f;
    ds.gain_k.values[8] = 0.0285511f;
    ds.gain_k.values[9] = 0.00287031f;
    ds.gain_k.values[10] = 0.00139108f;
    ds.gain_k.values[11] = -0.0288429f;
    ds.gain_k.values[12] = 0.00284935f;
    ds.gain_k.values[13] = -0.0027968f;
    ds.gain_k.values[14] = 0.0579364f;

    // --- x (measured state) ---
    an.an3 = 0.0102315f;
    an.an5 = 0.0249179f;
    an.an6 = 0.0334794f;

    // --- Verification ---
    // Expected ek:       [-1.65425, -3.31278, -0.0213279]
    // Expected dtk_raw:  [0.0125057, -0.0126014, -0.00867377, 0.00874139,
    // -0.00331601] Expected dtk_cond: [2.63988e-05, -2.66012e-05,
    // -1.80676e-05, 1.82081e-05, -6.67325e-06]
}
