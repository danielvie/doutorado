// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the
// MIT license.

#include "helper_matrix.h"

const char *TAG_MATRIX = "HELPER_MATRIX";

bool matrix_isvalid(MatrixData &M) {
    // rows -> m
    // cols -> n
    // values -> matrix(:)

    if (M.rows <= 0 || M.cols <= 0) {
        return false;
    }
    if (M.size != static_cast<size_t>(M.rows * M.cols)) {
        return false;
    }

    return true;
}

bool matrix_multiply_vector3(const MatrixData &M, float x1, float x2, float x3,
                             float *result) {
    // Cache data pointer to avoid repeated vector access overhead
    const float *data_ptr = M.values;

    // Use row-major indexing consistent with matrix_print(): row * M.cols + col
    for (int i = 0; i < M.rows; ++i) {
        result[i] = data_ptr[i * M.cols + 0] * x1 + // matrix[i][0] * x1
                    data_ptr[i * M.cols + 1] * x2 + // matrix[i][1] * x2
                    data_ptr[i * M.cols + 2] * x3;  // matrix[i][2] * x3
    }
    return true;
}

void matrix_print(MatrixData &M) {
    if (!matrix_isvalid(M)) {
        ESP_LOGW(TAG_MATRIX, "Matrix is not valid!!");
        return;
    }

    ESP_LOGI(TAG_MATRIX, "Matrix (%dx%d):\n", M.rows, M.cols);
    for (int i = 0; i < M.rows; ++i) {
        for (int j = 0; j < M.cols; ++j) {
            ESP_LOGI(TAG_MATRIX, "%.6f\t", M.values[i * M.cols + j]);
        }
        ESP_LOGI(TAG_MATRIX, "");
    }
}

void matrix_test() {
    auto msg = std::make_unique<NoteData>(1024);
    note_add_text(*msg, "\n=== MATRIX MULTIPLY TESTS ===\n");

    // note_buffer_add_text_f

    // Test 1: Identity matrix multiplication
    note_add_text(*msg, "\nTest 1: 3x3 Identity matrix * [1, 2, 3]\n");
    MatrixData identity = {
        .values = {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0},
        .size = 9,
        .rows = 3,
        .cols = 3,
        .is_valid = true};
    float result1[3];
    matrix_multiply_vector3(identity, 1.0, 2.0, 3.0, result1);
    note_add_text(*msg, "Expected: [1.0, 2.0, 3.0]\n");
    note_add_text(*msg, "Got:      [%.3f, %.3f, %.3f]\n\n", result1[0],
                  result1[1], result1[2]);

    // Test 2: Simple 2x3 matrix
    note_add_text(*msg, "\nTest 2: 2x3 matrix * [1, -1, 2]\n");
    MatrixData mat2x3 = {.values = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0},
                         .size = 6,
                         .rows = 2,
                         .cols = 3,
                         .is_valid = true};
    float result2[2];
    matrix_multiply_vector3(mat2x3, 1.0, -1.0, 2.0, result2);
    note_add_text(*msg, "Expected: [5.0, 11.0]\n");
    note_add_text(*msg, "Got:      [%.3f, %.3f]\n\n", result2[0], result2[1]);

    // Test 3: Single row matrix (1x3)
    note_add_text(*msg, "\nTest 3: 1x3 matrix * [2, 3, 4]\n");
    MatrixData mat1x3 = {.values = {0.5, 1.5, -2.0},
                         .size = 3,
                         .rows = 1,
                         .cols = 3,
                         .is_valid = true};
    float result3[1];
    matrix_multiply_vector3(mat1x3, 2.0, 3.0, 4.0, result3);
    note_add_text(*msg, "Expected: [-2.5]\n");
    note_add_text(*msg, "Got:      [%.3f]\n\n", result3[0]);

    // Test 4: Larger matrix (4x3)
    note_add_text(*msg, "\nTest 4: 4x3 matrix * [1, 0, -1]\n");
    MatrixData mat4x3 = {
        .values = {1.0, 0.0, 1.0,   // Row 1: 1*1 + 0*0 + 1*(-1) = 0
                   0.0, 2.0, 0.0,   // Row 2: 0*1 + 2*0 + 0*(-1) = 0
                   1.0, 1.0, 1.0,   // Row 3: 1*1 + 1*0 + 1*(-1) = 0
                   2.0, -1.0, 3.0}, // Row 4: 2*1 + (-1)*0 + 3*(-1) = -1
        .size = 12,
        .rows = 4,
        .cols = 3,
        .is_valid = true};
    float result4[4];
    matrix_multiply_vector3(mat4x3, 1.0, 0.0, -1.0, result4);
    note_add_text(*msg, "Expected: [0.0, 0.0, 0.0, -1.0]\n");
    note_add_text(*msg, "Got:      [%.3f, %.3f, %.3f, %.3f]\n\n", result4[0],
                  result4[1], result4[2], result4[3]);

    // Test 5: Fractional values
    MatrixData matFrac = {.values = {10.0, 20.0, 30.0, 1.0, -2.0, 5.0},
                          .size = 6,
                          .rows = 2,
                          .cols = 3,
                          .is_valid = true};
    float result5[2];
    matrix_multiply_vector3(matFrac, 0.1, 0.2, 0.3, result5);
    note_add_text(*msg, "Expected: [14.0, 1.2]\n");
    note_add_text(*msg, "Got:      [%.3f, %.3f]\n", result5[0], result5[1]);

    note_add_text(*msg, "\n=== MATRIX MULTIPLY TESTS COMPLETE ===");

    ESP_LOGI(TAG_MATRIX, "%s", msg->buffer);
}
