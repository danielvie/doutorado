#ifndef MATRIX_MATH_H
#define MATRIX_MATH_H

#include <Arduino.h>

/**
 * MatrixMath.h - High-performance matrix operations without class overhead
 * 
 * This library provides optimized matrix operations using plain C arrays
 * for maximum performance on embedded systems like ESP32.
 * 
 * All matrices are stored in row-major order:
 * For a matrix with m rows and n columns, element at (i,j) is at index [i*n + j]
 */

/**
 * Perform matrix multiplication: C = A * B
 * 
 * @param m_a Number of rows in matrix A
 * @param n_a Number of columns in matrix A (must equal m_b)
 * @param values_a Pointer to matrix A data in row-major order
 * @param m_b Number of rows in matrix B (must equal n_a)
 * @param n_b Number of columns in matrix B
 * @param values_b Pointer to matrix B data in row-major order
 * @param result Pointer to result matrix data (must be pre-allocated with size m_a * n_b)
 * @return true if multiplication successful, false if dimensions incompatible or null pointers
 */
bool matrix_multiply(int m_a, int n_a, const double* values_a,
                    int m_b, int n_b, const double* values_b,
                    double* result);

/**
 * Scale a matrix by a constant factor (in-place operation)
 * 
 * @param m Number of rows in matrix
 * @param n Number of columns in matrix
 * @param values Pointer to matrix data (modified in-place)
 * @param scale_factor Factor to multiply each element by
 */
void matrix_scale(int m, int n, double* values, double scale_factor);

/**
 * Copy matrix data from source to destination
 * 
 * @param m Number of rows
 * @param n Number of columns
 * @param src Source matrix data
 * @param dst Destination matrix data (must be pre-allocated)
 */
void matrix_copy(int m, int n, const double* src, double* dst);

/**
 * Print matrix for debugging purposes
 * 
 * @param m Number of rows
 * @param n Number of columns
 * @param values Pointer to matrix data
 * @param name Optional name for the matrix (can be nullptr)
 */
void matrix_print(int m, int n, const double* values, const char* name = nullptr);

#endif // MATRIX_MATH_H
