#include "conditioner.hpp"
#include <algorithm>
#include <stdexcept>

#if defined(_MSC_VER)
#define NOINLINE __declspec(noinline)
#elif defined(__GNUC__) || defined(__clang__)
#define NOINLINE __attribute__((noinline))
#else
#define NOINLINE
#endif

template <typename T> static T beta_arithmetic(const Input<T>& in) {
    T beta = T(1);
    T previous = T(0);
    for (std::size_t i = 0; i < intervals; ++i) {
        const T current = i < offsets ? in.raw[i] : T(0);
        const T change = current - previous;
        const T margin = (in.nominal[i + 1] - in.nominal[i]) - in.bound;
        if (change < T(0)) beta = std::min(beta, margin / -change);
        previous = current;
    }
    return std::min(T(1), std::max(T(0), beta));
}

template <typename T> static Result<T> condition(const Input<T>& in, T tolerance) {
    // Checks remain enabled in optimized builds. Like the MATLAB function,
    // this assumes finite inputs; no extra finite-input validation is timed.
    for (std::size_t i = 0; i < intervals; ++i) {
        if (!(in.nominal[i + 1] - in.nominal[i] - in.bound >= -tolerance))
            throw std::runtime_error("Nominal schedule violates dwell bound");
    }
    Result<T> out;
    out.beta = beta_arithmetic(in);
    std::array<T, intervals + 1> boundaries = in.nominal;
    for (std::size_t j = 0; j < offsets; ++j) {
        out.applied[j] = out.beta * in.raw[j];
        boundaries[j + 1] += out.applied[j];
    }
    for (std::size_t i = 0; i < intervals; ++i) {
        out.dwell[i] = boundaries[i + 1] - boundaries[i];
        if (!(out.dwell[i] >= in.bound - tolerance))
            throw std::runtime_error("Applied schedule violates dwell bound");
    }
    return out;
}

NOINLINE double beta_double(const Input<double>& in) { return beta_arithmetic(in); }
NOINLINE float beta_float(const Input<float>& in) { return beta_arithmetic(in); }
// Double uses seconds, matching MATLAB. Float uses microseconds to resemble
// the firmware's arithmetic units, but does not include timer-tick rounding.
NOINLINE Result<double> conditioner_double(const Input<double>& in) {
    return condition(in, 1e-12);
}
NOINLINE Result<float> conditioner_float(const Input<float>& in) {
    return condition(in, 1e-4f);
}
