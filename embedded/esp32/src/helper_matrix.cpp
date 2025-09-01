#include "helper_matrix.h"

bool matrix_isvalid(MatrixData &M)
{
    // rows -> m
    // cols -> n
    // values -> matrix(:)

    if (M.rows <= 0 || M.cols <= 0)
    {
        return false;
    }
    if (M.size != static_cast<size_t>(M.rows * M.cols))
    {
        return false;
    }

    return true;
}

bool matrix_multiply_vector3(MatrixData &M, float x1, float x2, float x3, float *result)
{
    // Cache data pointer to avoid repeated vector access overhead
    const float *data_ptr = M.values;

    // Use row-major indexing consistent with matrix_print(): row * M.cols + col
    for (int i = 0; i < M.rows; ++i)
    {
        result[i] = data_ptr[i * M.cols + 0] * x1 + // matrix[i][0] * x1
                    data_ptr[i * M.cols + 1] * x2 + // matrix[i][1] * x2
                    data_ptr[i * M.cols + 2] * x3;  // matrix[i][2] * x3
    }
    return true;
}

void matrix_print(MatrixData &M)
{
    if (!matrix_isvalid(M))
    {
        helper::println("Matrix is not valid!!");
        return;
    }

    helper::printf("Matrix (%dx%d):\n", M.rows, M.cols);
    for (int i = 0; i < M.rows; ++i)
    {
        for (int j = 0; j < M.cols; ++j)
        {
            helper::printf("%.6f\t", M.values[i * M.cols + j]);
        }
        helper::println("");
    }
}

void matrix_test()
{
    helper::println("=== MATRIX MULTIPLY TESTS ===");

    // Test 1: Identity matrix multiplication
    helper::println("\nTest 1: 3x3 Identity matrix * [1, 2, 3]");
    MatrixData identity = {
        .values = {1.0, 0.0, 0.0,
                   0.0, 1.0, 0.0,
                   0.0, 0.0, 1.0},
        .rows = 3,
        .cols = 3,
        .is_valid = true};
    float result1[3];
    matrix_multiply_vector3(identity, 1.0, 2.0, 3.0, result1);
    helper::printf("Expected: [1.0, 2.0, 3.0]\n");
    helper::printf("Got:      [%.3f, %.3f, %.3f]\n", result1[0], result1[1], result1[2]);

    // Test 2: Simple 2x3 matrix
    helper::println("\nTest 2: 2x3 matrix * [1, -1, 2]");
    MatrixData mat2x3 = {
        .values = {1.0, 2.0, 3.0,  // Row 1: 1*1 + 2*(-1) + 3*2 = 1 - 2 + 6 = 5
                   4.0, 5.0, 6.0}, // Row 2: 4*1 + 5*(-1) + 6*2 = 4 - 5 + 12 = 11
        .rows = 2,
        .cols = 3,
        .is_valid = true};
    float result2[2];
    matrix_multiply_vector3(mat2x3, 1.0, -1.0, 2.0, result2);
    helper::printf("Expected: [5.0, 11.0]\n");
    helper::printf("Got:      [%.3f, %.3f]\n", result2[0], result2[1]);

    // Test 3: Single row matrix (1x3)
    helper::println("\nTest 3: 1x3 matrix * [2, 3, 4]");
    MatrixData mat1x3 = {
        .values = {0.5, 1.5, -2.0}, // 0.5*2 + 1.5*3 + (-2.0)*4 = 1 + 4.5 - 8 = -2.5
        .rows = 1,
        .cols = 3,
        .is_valid = true};
    float result3[1];
    matrix_multiply_vector3(mat1x3, 2.0, 3.0, 4.0, result3);
    helper::printf("Expected: [-2.5]\n");
    helper::printf("Got:      [%.3f]\n", result3[0]);

    // Test 4: Larger matrix (4x3)
    helper::println("\nTest 4: 4x3 matrix * [1, 0, -1]");
    MatrixData mat4x3 = {
        .values = {1.0, 0.0, 1.0,   // Row 1: 1*1 + 0*0 + 1*(-1) = 0
                   0.0, 2.0, 0.0,   // Row 2: 0*1 + 2*0 + 0*(-1) = 0
                   1.0, 1.0, 1.0,   // Row 3: 1*1 + 1*0 + 1*(-1) = 0
                   2.0, -1.0, 3.0}, // Row 4: 2*1 + (-1)*0 + 3*(-1) = -1
        .rows = 4,
        .cols = 3,
        .is_valid = true};
    float result4[4];
    matrix_multiply_vector3(mat4x3, 1.0, 0.0, -1.0, result4);
    helper::printf("Expected: [0.0, 0.0, 0.0, -1.0]\n");
    helper::printf("Got:      [%.3f, %.3f, %.3f, %.3f]\n", result4[0], result4[1], result4[2], result4[3]);

    // Test 5: Fractional values
    helper::println("\nTest 5: 2x3 matrix * [0.1, 0.2, 0.3]");
    MatrixData matFrac = {
        .values = {10.0, 20.0, 30.0, // Row 1: 10*0.1 + 20*0.2 + 30*0.3 = 1 + 4 + 9 = 14
                   1.0, -2.0, 5.0},  // Row 2: 1*0.1 + (-2)*0.2 + 5*0.3 = 0.1 - 0.4 + 1.5 = 1.2
        .rows = 2,
        .cols = 3,
        .is_valid = true};
    float result5[2];
    matrix_multiply_vector3(matFrac, 0.1, 0.2, 0.3, result5);
    helper::printf("Expected: [14.0, 1.2]\n");
    helper::printf("Got:      [%.3f, %.3f]\n", result5[0], result5[1]);

    helper::println("\n=== MATRIX MULTIPLY TESTS COMPLETE ===");
}
