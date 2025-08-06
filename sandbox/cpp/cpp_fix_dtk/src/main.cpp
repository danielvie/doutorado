#include <iostream>
#include <vector>
#include <numeric>
#include <string>
#include <chrono>

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

float vector_sum(const std::vector<float>& vec) {
    float sum = std::accumulate(vec.begin(), vec.end(), 0.0f);
    return sum;
}

void vector_print(const std::vector<float>& V, const std::string name) {
    std::cout << name << ": ";
    for (auto el : V) {
        std::cout << el << ", " ;
    }
    std::cout << "\n";
}

Result condition_dtk_signal(const std::vector<float>& time_us, const float& time_constraint_us, std::vector<float>& dtk_us) {
    
    size_t dtk_len   = dtk_us.size();
    size_t ts_us_len = time_us.size()+1;

    // create ts_us_ref
    std::vector<float> ts_us_ref(dtk_len + 2, 0.0);
    ts_us_ref[dtk_len+1] = std::round(vector_sum(time_us));
    
    for (int i=0; i < dtk_len; i++) {
        ts_us_ref[i+1] = ts_us_ref[i] + time_us[i];
    }

    // normalize dtk to the cycle range
    float dtk_us_sum = vector_sum(dtk_us);
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

float fix_dtk_proportion(const std::vector<float>& time_us, const float& time_constraint_us,const std::vector<float>& dtk_us) {
    
    // create ts_us_ref
    // std::vector<float> ts_us_ref(dtk_len + 2, 0.0);
    // ts_us_ref[dtk_len+1] = std::round(vector_sum(time_us));
    
    std::vector<float> ts_us;
    vector_create_ts(time_us, ts_us);

    vector_print(ts_us, "[] ts_us");

    // test proportion
    auto is_valid = [&ts_us, &dtk_us, &time_constraint_us](float k) {
        size_t ts_us_len = ts_us.size();
        size_t dtk_len = dtk_us.size();
        bool valid = (ts_us[1] + k*dtk_us[0]) - ts_us[0] > time_constraint_us;
        for (size_t i = 1; i < ts_us_len - 2; i++) {
            valid = valid && ((ts_us[i+1] + k*dtk_us[i]) - (ts_us[i] + k*dtk_us[i-1]) > time_constraint_us);
        }
        valid = valid && (ts_us[ts_us_len-1] - (ts_us[ts_us_len-2] + k*dtk_us[dtk_len-1]) > time_constraint_us);
        return valid;
    };
    
    // nominal, manter valores
    std::cout << "bla 1\n";
    if (is_valid(1.0)) {
        return 1.0;
    }
    std::cout << "bla 2\n";

    // binary search
    float a = 0.0;
    float b = 1.0;
    float x;
    float tol = 0.0001;
    
    for (int i = 0; i < 10; i++) {
        x = (a + b)/2;
        if (is_valid(x)) {
            std::cout << "[is valid] x: " << x << ", a: " << a << ", b: " << b << "\n";
            a = x;
        } else {
            std::cout << "[is NOT valid] x: " << x << ", a: " << a << ", b: " << b << "\n";
            b = x;
        }
        // exit condition
        if (fabs(b-a) < tol) {
            return a;
        }
    }
    
    return a;
}

int main_proportional(std::vector<float>& time_us, std::vector<float>& dtk_us, float& time_constraint_us) {

    auto res = fix_dtk_proportion(time_us, time_constraint_us, dtk_us);
    
    std::cout << "result: " << res << "\n";
    return 1;
}

int main_condition_dtk(std::vector<float>& time_us, std::vector<float>& dtk_us, float& time_constraint_us) {
    vector_print(dtk_us, "dtk_us: ");

    auto clock_ini = std::chrono::high_resolution_clock::now();
    auto err = condition_dtk_signal(time_us, time_constraint_us, dtk_us);
    auto clock_end = std::chrono::high_resolution_clock::now();

    vector_print(dtk_us, "dtk_us_new: ");

    if (err == Result::FAIL) {
        std::cout << "deu ruim!\n";
        return 0;
    }

    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(clock_end - clock_ini);
    std::cout << "duration: ";
    std::cout << duration.count() << " us\n";
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
