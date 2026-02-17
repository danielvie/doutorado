#include "control.h"

// =====================================================================
// Test
// =====================================================================

struct TestData {
    float an3;
    float an5;
    float an6;
    uint32_t N;
    uint32_t p;
};

void set_test_values(TestData &td, DataSet &ds) {
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
    ds.gain_k.rows = 5;
    ds.gain_k.cols = 3;
    ds.gain_k.size = 15;
    ds.gain_k.is_valid = true;

    ds.gain_k.values[0] = -0.0023f;
    ds.gain_k.values[1] = 0.0023f;
    ds.gain_k.values[2] = -0.0283f;
    ds.gain_k.values[3] = -0.0045f;
    ds.gain_k.values[4] = -0.0023f;
    ds.gain_k.values[5] = 0.0285f;
    ds.gain_k.values[6] = -0.0046f;
    ds.gain_k.values[7] = -0.0091f;
    ds.gain_k.values[8] = -0.0564f;
    ds.gain_k.values[9] = 0.0023f;
    ds.gain_k.values[10] = -0.0022f;
    ds.gain_k.values[11] = 0.0299f;
    ds.gain_k.values[12] = 0.0046f;
    ds.gain_k.values[13] = 0.0023f;
    ds.gain_k.values[14] = -0.0296f;

    td.an3 = -0.0077f;
    td.an5 = 0.0073f;
    td.an6 = 0.0337f;

    td.N = ds.size;
    td.p = td.N - 1;
}

int main() {
    printf("====== CONTROL COMPUTATION TEST ======\n\n");

    // -----------------------------------------------------------------
    // 1. Build test DataSet
    // -----------------------------------------------------------------
    TestData td = {};
    DataSet ds = {};

    set_test_values(td, ds);

    // -----------------------------------------------------------------
    // 2. Simulated ADC readings
    // -----------------------------------------------------------------
    float an3 = td.an3;
    float an5 = td.an5;
    float an6 = td.an6;

    const uint32_t N = td.N;
    const uint32_t p = td.p;

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
