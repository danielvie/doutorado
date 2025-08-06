#pragma once

#include <vector>
#include <numeric>
#include <iostream>

float vector_sum(const std::vector<float>& vec);

template <typename T>
void vector_print(const std::vector<T>& V, const std::string name) {
    std::cout << name << ": ";
    for (auto el : V) {
        std::cout << el << ", ";
    }
    std::cout << "\n";
}