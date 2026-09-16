#pragma once
#include <array>

// Fixed dimensions of the article, not the six-interval ESP32 lookup table.
constexpr std::size_t intervals = 9;
constexpr std::size_t offsets = intervals - 1;

template <typename T> struct Input {
    std::array<T, intervals + 1> nominal{};
    std::array<T, offsets> raw{};
    T bound{};
};
template <typename T> struct Result {
    std::array<T, offsets> applied{};
    T beta{};
    std::array<T, intervals> dwell{};
};

// Separate translation unit, no LTO. Calls cannot be folded into benchmark code.
double beta_double(const Input<double>& in);
float beta_float(const Input<float>& in);
Result<double> conditioner_double(const Input<double>& in);
Result<float> conditioner_float(const Input<float>& in);
