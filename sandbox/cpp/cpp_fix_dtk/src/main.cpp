#include <iostream>
#include <vector>
#include <numeric>
#include <string>
#include <chrono>
#include <memory>

#include "helper.h"
#include "condition_dtk.h"
#include "condition_dtk_optimized.h"

int main_condition_dtk(std::vector<uint32_t>& time_us, std::vector<int32_t>& dtk_us, float& time_constraint_us) {
    print_vector(dtk_us, "dtk_us: ");

    print_vector(time_us, "time_us_u: ");
    print_vector(dtk_us, "dtk_us_i: ");

    auto clock_ini = std::chrono::high_resolution_clock::now();

    condition_dtk_signal(time_us, time_constraint_us, dtk_us.data(), dtk_us.size());
    auto clock_end = std::chrono::high_resolution_clock::now();

    print_vector(dtk_us, "dtk_us_i_new: ");
    
    auto duration_us = std::chrono::duration_cast<std::chrono::microseconds>(clock_end - clock_ini).count();
    printf("duration: %lld us\n", duration_us);

    return 1;
}

void test_performance_comparison() {
    // Test data
    std::vector<uint32_t> time_us = {47, 47, 47, 47, 47, 47};
    float time_constraint_us = 10.0f;
    std::vector<int32_t> dtk_us_original = {-17906, 18065, -32241, -85331, 9210};
    std::vector<int32_t> dtk_us_optimized = dtk_us_original;
    std::vector<int32_t> dtk_us_fixed = dtk_us_original;
    
    const int num_iterations = 10000;  // Increased for better measurement
    
    std::cout << "Performance Comparison (ESP32 optimizations)\n";
    std::cout << "============================================\n";
    std::cout << "Running " << num_iterations << " iterations each...\n\n";
    
    // Test original version
    auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < num_iterations; i++) {
        dtk_us_original = {-17906, 18065, -32241, -85331, 9210}; // Reset
        condition_dtk_signal(time_us, time_constraint_us, dtk_us_original.data(), dtk_us_original.size());
    }
    auto end = std::chrono::high_resolution_clock::now();
    auto duration_original = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
    
    // Test optimized version with workspace
    size_t workspace_size = 2 * (dtk_us_optimized.size() + 2);
    std::unique_ptr<float[]> workspace(new float[workspace_size]);
    
    start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < num_iterations; i++) {
        dtk_us_optimized = {-17906, 18065, -32241, -85331, 9210}; // Reset
        condition_dtk_signal_optimized(time_us.data(), time_us.size(), time_constraint_us, 
                                     dtk_us_optimized.data(), dtk_us_optimized.size(), workspace.get());
    }
    end = std::chrono::high_resolution_clock::now();
    auto duration_optimized = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
    
    // Test fixed-size version
    start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < num_iterations; i++) {
        dtk_us_fixed = {-17906, 18065, -32241, -85331, 9210}; // Reset
        condition_dtk_signal_fixed<10>(time_us.data(), time_us.size(), time_constraint_us, 
                                     dtk_us_fixed.data(), dtk_us_fixed.size());
    }
    end = std::chrono::high_resolution_clock::now();
    auto duration_fixed = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
    
    // Display results
    std::cout << "Original version:     " << duration_original << " μs total, " 
              << (double)duration_original / num_iterations << " μs per call\n";
    std::cout << "Optimized version:    " << duration_optimized << " μs total, " 
              << (double)duration_optimized / num_iterations << " μs per call\n";
    std::cout << "Fixed-size version:   " << duration_fixed << " μs total, " 
              << (double)duration_fixed / num_iterations << " μs per call\n";
    
    double speedup_optimized = (double)duration_original / duration_optimized;
    double speedup_fixed = (double)duration_original / duration_fixed;
    
    std::cout << "\nSpeedup (optimized):  " << speedup_optimized << "x\n";
    std::cout << "Speedup (fixed-size): " << speedup_fixed << "x\n";
    
    // Verify results are the same
    std::cout << "\nResult verification:\n";
    print_vector(dtk_us_original, "Original:  ");
    print_vector(dtk_us_optimized, "Optimized: ");
    print_vector(dtk_us_fixed, "Fixed:     ");
    
    bool results_match = (dtk_us_original == dtk_us_optimized) && (dtk_us_original == dtk_us_fixed);
    std::cout << "Results match: " << (results_match ? "YES" : "NO") << "\n";
}

// Forward declaration
void test_performance_comparison();

int main() {

    // time_vec          : [47,47,47,47,47,47,];
    // time_constraint_us: 10.0;
    // control_dtk_us    : [-17244,17403,-31591,-85987,25442,];
    // control_dtk_us    : [-37,64,27,-9,-3,];

    // test values alpha: 0.5
    std::vector<uint32_t> time_us = {47,47,47,47,47,47};
    float time_constraint_us = 10.0;
    // std::vector<int32_t> dtk_us = {-17244,17403,-31591,-85987,25442};

    std::vector<int32_t> dtk_us = {-17906,18065,-32241,-85331,9210};

    std::cout << "=== Original Function Test ===\n";
    main_condition_dtk(time_us, dtk_us, time_constraint_us);
    
    std::cout << "\n=== Performance Comparison ===\n";
    test_performance_comparison();

    return 0;
}
