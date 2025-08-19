#pragma once

#include <vector>
#include <numeric>
#include <iostream>

float vector_sum(const std::vector<float>& vec);
void vector_create_ts(const std::vector<float>& time_us, std::vector<float>& result);

template <typename T>
void print_vector(const std::vector<T>& V, const std::string name) {
    std::cout << name << ": ";
    for (auto el : V) {
        std::cout << el << ", ";
    }
    std::cout << "\n";
}

template <typename T>
void print_array(const T* V, const size_t len, const std::string name) {
    std::cout << name << ": ";
    for (size_t i = 0; i < len; i++) {
        std::cout << V[i] << ", ";
    }
    std::cout << "\n";
}