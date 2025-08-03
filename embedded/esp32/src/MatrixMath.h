#ifndef MATRIX_MATH_H
#define MATRIX_MATH_H

#include <Arduino.h>
#include <vector>
#include "signal_controller.h"

// bool matrix_multiply(int& rows_a, int& cols_a, std::vector<float>& values_a,
//                     int& rows_b, int& cols_b, std::vector<float>& values_b,
//                     std::vector<float>& result);


bool matrix_isvalid(MatrixData& M);
bool matrix_multiply_vector3(MatrixData& M, float x1, float x2, float x3, float* result);
void matrix_print(MatrixData& M);

// void matrix_scale(const int& m, const int& n, std::vector<float>& values, const float& scale_factor);

// void matrix_print(int m, int n, std::vector<float> values, const char* name);

// bool matrix_isvalid(int m, int n, std::vector<float> values);

#endif // MATRIX_MATH_H
