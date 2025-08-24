#ifndef MATRIX_MATH_H
#define MATRIX_MATH_H

#include <Arduino.h>
#include <vector>

#define MAX_MATRIX_ELEMENTS 100

struct MatrixData {
    float values[MAX_MATRIX_ELEMENTS];
    uint16_t size;
    uint16_t rows, cols;
    bool is_valid;
};

bool matrix_isvalid(MatrixData& M);
bool matrix_multiply_vector3(MatrixData& M, float x1, float x2, float x3, float* result);
void matrix_print(MatrixData& M);
void matrix_test();

#endif // MATRIX_MATH_H
