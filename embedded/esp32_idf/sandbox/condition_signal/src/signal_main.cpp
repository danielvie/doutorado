#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
#include <cassert>

template <typename T>
void print_vec(std::vector<T> v, std::string name) {
    std::cout << name << ": ";
    for (auto vi : v) {
        std::cout << vi << ", ";
    }
    std::cout << "\n";
}

void condition_dtk_signal(const std::vector<int32_t> &time_increment, const std::vector<float> &control_dtk, const int32_t min_gap, std::vector<float> &result_dtk) {
    
    const int N = time_increment.size() + 1;

    // time_reference: Reference array [N x 1]
    std::vector<float> time_reference(N, 0);
    for (int i = 0; i < N - 1; ++i) {
        time_reference[i+1] = time_reference[i] + (float)time_increment[i];
    }
    
    // create augmented control_dtk that aligns with time_reference
    std::vector<float> control_aug(N, 0);
    for (int i = 0; i < N-2; ++i) {
        control_aug[i+1] = control_dtk[i];
    }
    
    // calculate existing gaps in time_reference
    std::vector<float> gaps_time_ref(N-1, 0);
    for (int i = 0; i < N-1; ++i) {
        gaps_time_ref[i] = time_reference[i+1] - time_reference[i];
    }

    // calculate how control_dtk affects the gaps
    std::vector<float> gap_change(N-1, 0);
    for (int i = 0; i < N-1; ++i) {
        gap_change[i] = control_aug[i+1] - control_aug[i];
    }

    // we only care when gap_change is negative
    float alpha = 1.0;
    
    // find indice where control_dtk is trying to shrink the gap
    std::vector<size_t> shrinking_indices;
    for (int i = 0; i < N-1; ++i) {
        if (gap_change[i] < 0) {
            shrinking_indices.push_back(i);
        }
    }

    if (shrinking_indices.size() > 0) {
        size_t len = shrinking_indices.size();
        std::vector<float> max_possible_alphas(len, -99);
        for (int i = 0; i < shrinking_indices.size(); ++i) {
            size_t idx = shrinking_indices[i];

            float numerator = min_gap - gaps_time_ref[idx];
            float denominator = gap_change[idx];
            
            max_possible_alphas[i] = numerator / denominator;
        }

        // the strict limit is the minimum of all allowed alphas
        float limit = *std::min_element(max_possible_alphas.begin(), max_possible_alphas.end());
        
        // clamping alpha between 0 and 1
        alpha = std::max(0.0f, std::min(1.0f, limit));

        std::cout << "limit: " << limit << "\n";
        std::cout << "alpha: " << alpha << "\n";

        print_vec(max_possible_alphas, "max_possible_alphas");
    }
    
    // apply conditioned control
    result_dtk.resize(control_dtk.size());
    
    for (int i = 0; i < control_dtk.size(); ++i) {
        result_dtk[i] = alpha*control_aug[i+1];
    }
}


int main() {
    // condition_dtk_signal(time_us, dtk_us, time_constraint_us);
    // 
    // input ->
    // time_us :: [47, 47, 47, 47, 47, 47]
    // dtk_us  :: [2969.65062490875, -14081.3405522658, -39834.0974666549, -2508.37642982644, 14235.9449774684]
    // time_constraint_us :: 3
    //
    // output ->
    // dtk_us :: [5.07381124010755, -24.0587439379551, -68.0587439379551, -4.28569893620577, 24.3228940921126]
    //
    
    std::vector<int32_t> time_us = {47, 47, 47, 47, 47, 47};
    std::vector<float> dtk_us = {2969.65062490875, -14081.3405522658, -39834.0974666549, -2508.37642982644, 14235.9449774684};
    int32_t time_constraint_us = 3;
    
    std::vector<float> result_dtk;
    
    condition_dtk_signal(time_us, dtk_us, time_constraint_us, result_dtk);

    return 0;
}
