#pragma once

#include <vector>
#include <numeric>
#include <cmath>

// Optimized version with stack allocation
void condition_dtk_signal_optimized(const uint32_t* time_us, size_t time_us_len, const float time_constraint_us, int32_t* dtk_us, size_t dtk_len, float* workspace);