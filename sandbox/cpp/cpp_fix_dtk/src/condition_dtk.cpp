#include "condition_dtk.h"

void condition_dtk_signal(const std::vector<uint32_t>& time_us, const float& time_constraint_us, int32_t* dtk_us, size_t dtk_len) {
    
    size_t ts_us_len = time_us.size()+1;

    auto compute_sum_u = [](const std::vector<uint32_t>& vec) -> uint32_t {
        return std::accumulate(vec.begin(), vec.end(), uint32_t(0));
    };

    auto compute_sum_array_i = [](const int32_t* vec, size_t dtk_len) -> int32_t {
        return std::accumulate(vec, vec + dtk_len, int32_t(0));
    };

    // create ts_us_ref
    std::vector<float> ts_us_ref(dtk_len + 2, 0.0);
    ts_us_ref[dtk_len+1] = std::round(compute_sum_u(time_us));
    
    for (int i=0; i < dtk_len; i++) {
        ts_us_ref[i+1] = ts_us_ref[i] + time_us[i];
    }

    // normalize dtk to the cycle range
    float dtk_us_sum = compute_sum_array_i(dtk_us, dtk_len);

    if (dtk_us_sum > ts_us_ref[ts_us_len-1]) {
        for (int i = 0; i < dtk_len; i++) {
            dtk_us[i] = dtk_us[i] / dtk_us_sum * ts_us_ref[ts_us_len - 1];
        }
    }

    // adjust ts_us with dtk_us
    std::vector<float> ts_us = ts_us_ref;
    for (size_t i = 0; i < dtk_len; i++) {
        ts_us[i+1] = ts_us[i+1] + dtk_us[i];
    }

    // impose time constraint for `ts_us`
    for (size_t i = 0; i < ts_us_len-2; i++) {
        if (ts_us[i+1] - ts_us[i] < time_constraint_us) {
            ts_us[i+1] = ts_us[i] + time_constraint_us;
        }
    }
    
    // adjust final time
    float ts_us_end = ts_us[ts_us_len - 1];
    if (ts_us[ts_us_len-2] > ts_us_end) {
        for (size_t i = 0; i < ts_us_len-1; i++) {
            ts_us[i] = ts_us[i]/ts_us[ts_us_len-2]*(ts_us_end - time_constraint_us*dtk_len);
        }
    }

    // impose time constraint for `ts_us`
    for (size_t i = 0; i < ts_us_len-1; i++) {
        if (ts_us[i+1] - ts_us[i] < time_constraint_us) {
            ts_us[i+1] = ts_us[i] + time_constraint_us;
        }
    }

    for (size_t i = 0; i < dtk_len; i++) {
        dtk_us[i] = ts_us[i+1] - ts_us_ref[i+1];
    }
}