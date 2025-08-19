#include "helper.h"

float vector_sum(const std::vector<float>& vec) {
    float sum = std::accumulate(vec.begin(), vec.end(), 0.0f);
    return sum;
}

void vector_create_ts(const std::vector<float>& time_us, std::vector<float>& result) {
    size_t time_us_len = time_us.size();
    result.resize(time_us_len+1, 0.0);
    for (int i=0; i < time_us_len; i++) {
        result[i+1] = result[i] + time_us[i];
    }
}