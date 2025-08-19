#pragma once

#include <vector>
#include <numeric>
#include <cmath>

void condition_dtk_signal(const std::vector<uint32_t>& time_us, const float& time_constraint_us, int32_t* dtk_us, const size_t& dtk_len);
