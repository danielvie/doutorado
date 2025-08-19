#include <iostream>
#include <vector>
#include <numeric>
#include <string>
#include <chrono>

#include "helper.h"
#include "condition_dtk.h"

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


    main_condition_dtk(time_us, dtk_us, time_constraint_us);

    return 0;
}
