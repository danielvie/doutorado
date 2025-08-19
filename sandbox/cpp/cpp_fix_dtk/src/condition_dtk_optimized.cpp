#include "condition_dtk_optimized.h"

// Optimized version 1: Use pre-allocated workspace to avoid heap allocation
void condition_dtk_signal_optimized(const uint32_t* time_us, size_t time_us_len, const float time_constraint_us, int32_t* dtk_us, size_t dtk_len, float* workspace) {
    
    // Use workspace instead of vector allocations
    // workspace needs to be at least 2 * (dtk_len + 2) floats
    float* ts_us_ref = workspace;
    float* ts_us = workspace + (dtk_len + 2);
    
    size_t ts_us_len = time_us_len + 1;

    // Inline sum computation to avoid lambda overhead
    uint32_t time_sum = 0;
    for (size_t i = 0; i < time_us_len; i++) {
        time_sum += time_us[i];
    }

    // Create ts_us_ref - avoid std::round for performance
    for (size_t i = 0; i <= dtk_len + 1; i++) {
        ts_us_ref[i] = 0.0f;
    }
    ts_us_ref[dtk_len + 1] = (float)time_sum;  // Remove std::round for speed
    
    for (size_t i = 0; i < dtk_len; i++) {
        ts_us_ref[i + 1] = ts_us_ref[i] + (float)time_us[i];
    }

    // Normalize dtk to the cycle range - inline sum computation
    int32_t dtk_us_sum = 0;
    for (size_t i = 0; i < dtk_len; i++) {
        dtk_us_sum += dtk_us[i];
    }

    if (dtk_us_sum > ts_us_ref[ts_us_len - 1]) {
        float normalization_factor = ts_us_ref[ts_us_len - 1] / (float)dtk_us_sum;
        for (size_t i = 0; i < dtk_len; i++) {
            dtk_us[i] = (int32_t)((float)dtk_us[i] * normalization_factor);
        }
    }

    // Copy ts_us_ref to ts_us and adjust with dtk_us in single loop
    for (size_t i = 0; i < ts_us_len; i++) {
        ts_us[i] = ts_us_ref[i];
        if (i > 0 && i <= dtk_len) {
            ts_us[i] += (float)dtk_us[i - 1];
        }
    }

    // Impose time constraint for ts_us
    for (size_t i = 0; i < ts_us_len - 2; i++) {
        if (ts_us[i + 1] - ts_us[i] < time_constraint_us) {
            ts_us[i + 1] = ts_us[i] + time_constraint_us;
        }
    }
    
    // Adjust final time
    float ts_us_end = ts_us[ts_us_len - 1];
    if (ts_us[ts_us_len - 2] > ts_us_end) {
        float adjustment_factor = (ts_us_end - time_constraint_us * (float)dtk_len) / ts_us[ts_us_len - 2];
        for (size_t i = 0; i < ts_us_len - 1; i++) {
            ts_us[i] *= adjustment_factor;
        }
    }

    // Impose time constraint again
    for (size_t i = 0; i < ts_us_len - 1; i++) {
        if (ts_us[i + 1] - ts_us[i] < time_constraint_us) {
            ts_us[i + 1] = ts_us[i] + time_constraint_us;
        }
    }

    // Calculate final dtk_us values
    for (size_t i = 0; i < dtk_len; i++) {
        dtk_us[i] = (int32_t)(ts_us[i + 1] - ts_us_ref[i + 1]);
    }
}
