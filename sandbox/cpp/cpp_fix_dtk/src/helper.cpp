#include "helper.h"

float vector_sum(const std::vector<float>& vec) {
    float sum = std::accumulate(vec.begin(), vec.end(), 0.0f);
    return sum;
}
