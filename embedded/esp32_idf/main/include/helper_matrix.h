// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the
// MIT license.

#ifndef MATRIX_MATH_H
#define MATRIX_MATH_H

#include "helper_note.h"

#include <memory>
#include <stdint.h>
#include <vector>

extern "C" {
#include "esp_log.h"
}

#define MAX_MATRIX_ELEMENTS 100

struct MatrixData {
    float values[MAX_MATRIX_ELEMENTS];
    uint16_t size;
    uint16_t rows, cols;
    bool is_valid;
};

extern "C" {

bool matrix_isvalid(MatrixData &M);
bool matrix_multiply_vector3(const MatrixData &M, float x1, float x2, float x3,
                             float *result);
void matrix_print(MatrixData &M);
void matrix_test();
}

#endif // MATRIX_MATH_H