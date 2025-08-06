#include <iostream>
#include <vector>
#include <numeric>
#include <string>
#include <chrono>

#include "helper.h"

// time_us =
//     84     9    84     9    84     9
//
// dtk_us
//     4146.18386384488          4783.98329645644         -4771.28079764979          5826.11363501824         -5782.47667405956
//
// time_constraint_us
//     3


enum class Result{
    OK,
    FAIL,
};

Result condition_dtk_signal_float(const std::vector<float>& time_us, const float& time_constraint_us, std::vector<float>& dtk_us) {
    
    size_t dtk_len   = dtk_us.size();
    size_t ts_us_len = time_us.size()+1;

    auto compute_sum = [](const std::vector<float>& vec) -> float {
        return std::accumulate(vec.begin(), vec.end(), 0.0f);
    };

    // create ts_us_ref
    std::vector<float> ts_us_ref(dtk_len + 2, 0.0);
    ts_us_ref[dtk_len+1] = std::round(compute_sum(time_us));
    
    for (int i=0; i < dtk_len; i++) {
        ts_us_ref[i+1] = ts_us_ref[i] + time_us[i];
    }

    // normalize dtk to the cycle range
    float dtk_us_sum = compute_sum(dtk_us);
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
    
    return Result::OK;
}

Result condition_dtk_signal(const std::vector<uint32_t>& time_us, const float& time_constraint_us, std::vector<int32_t>& dtk_us) {
    
    size_t dtk_len   = dtk_us.size();
    size_t ts_us_len = time_us.size()+1;

    auto compute_sum_u = [](const std::vector<uint32_t>& vec) -> uint32_t {
        return std::accumulate(vec.begin(), vec.end(), uint32_t(0));
    };

    auto compute_sum_i = [](const std::vector<int32_t>& vec) -> int32_t {
        return std::accumulate(vec.begin(), vec.end(), int32_t(0));
    };

    // create ts_us_ref
    std::vector<float> ts_us_ref(dtk_len + 2, 0.0);
    ts_us_ref[dtk_len+1] = std::round(compute_sum_u(time_us));
    
    for (int i=0; i < dtk_len; i++) {
        ts_us_ref[i+1] = ts_us_ref[i] + time_us[i];
    }

    // normalize dtk to the cycle range
    float dtk_us_sum = compute_sum_i(dtk_us);
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
    
    return Result::OK;
}


void vector_create_ts(const std::vector<float>& time_us, std::vector<float>& result) {
    size_t time_us_len = time_us.size();
    result.resize(time_us_len+1, 0.0);
    for (int i=0; i < time_us_len; i++) {
        result[i+1] = result[i] + time_us[i];
    }
}

int main_condition_dtk(std::vector<float>& time_us, std::vector<float>& dtk_us, float& time_constraint_us) {
    vector_print(dtk_us, "dtk_us: ");

    std::vector<uint32_t> time_us_u;
    std::vector<int32_t> dtk_us_i;
    

    time_us_u.resize(time_us.size(), 0);
    dtk_us_i.resize(dtk_us.size(), 0);


    for (size_t i = 0; i < time_us.size(); i++) {
        time_us_u[i] = (uint32_t)std::round(time_us[i]);
    }

    for (size_t i = 0; i < dtk_us.size(); i++) {
        dtk_us_i[i] = (int32_t)std::round(dtk_us[i]);
    }

    vector_print(time_us_u, "time_us_u: ");
    vector_print(dtk_us_i, "dtk_us_i: ");

    auto clock_ini = std::chrono::high_resolution_clock::now();
    auto err = condition_dtk_signal(time_us_u, time_constraint_us, dtk_us_i);
    auto clock_end = std::chrono::high_resolution_clock::now();

    vector_print(dtk_us_i, "dtk_us_i_new: ");

    if (err == Result::FAIL) {
        std::cout << "deu ruim!\n";
        return 0;
    }

    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(clock_end - clock_ini);
    std::cout << "duration: ";
    std::cout << duration.count() << " us\n";

    // 2**31-1=2147483647
    // 2**32-1=4294967295
    std::cout << "int32max: " << INT32_MAX << "\n";
    std::cout << "uint32max: " << UINT32_MAX << "\n";


    return 1;
}

int main() {

    // test values
    std::vector<float> time_us = {84, 9, 84, 9, 84, 9};
    std::vector<float> dtk_us = {4146.18386384488, 4783.98329645644, -4771.28079764979, 5826.11363501824,-5782.47667405956};
    float time_constraint_us = 3;

    main_condition_dtk(time_us, dtk_us, time_constraint_us);

    return 0;
}
