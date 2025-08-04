#include <iostream>
#include <vector>
#include <numeric>
#include <string>

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

Result fix_dtk(const std::vector<float>& time_us, const float& time_constraint_us, std::vector<float>& dtk_us) {
    
    
    vector_print(time_us, "time_us");
    vector_print(dtk_us, "dtk_us");

    std::cout << "time_constraint_us: ";
    std::cout << time_constraint_us << "\n";

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
    
    vector_print(dtk_us, "dtk_us: ");
    vector_print(ts_us, "ts_us: ");


    return Result::OK;
}


int main() {

    std::vector<float> time_us = {84, 9, 84, 9, 84, 9};
    std::vector<float> dtk_us = {4146.18386384488, 4783.98329645644, -4771.28079764979, 5826.11363501824,-5782.47667405956};
    float time_constraint_us = 3;


    auto err = fix_dtk(time_us, time_constraint_us, dtk_us);

    if (err == Result::FAIL) {
        std::cout << "deu ruim!\n";
        return 0;
    }

    std::cout << "hello you\n";

    return 0;
}
