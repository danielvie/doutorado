#include "MatrixMath.h"

/**
 * Perform matrix multiplication without class overhead
 * 
 * Multiplies matrix A (m_a x n_a) by matrix B (m_b x n_b)
 * Result matrix C will be (m_a x n_b)
 * 
 * @param m_a Number of rows in matrix A
 * @param n_a Number of columns in matrix A (must equal m_b)
 * @param values_a Pointer to matrix A data in row-major order
 * @param m_b Number of rows in matrix B (must equal n_a)
 * @param n_b Number of columns in matrix B
 * @param values_b Pointer to matrix B data in row-major order
 * @param result Pointer to result matrix data (must be pre-allocated with size m_a * n_b)
 * @return true if multiplication successful, false if dimensions incompatible
 */
bool matrix_multiply(int m_a, int n_a, const double* values_a,
                    int m_b, int n_b, const double* values_b,
                    double* result) {
    
    // Check dimension compatibility
    if (n_a != m_b) {
        return false;  // Incompatible dimensions
    }
    
    // Check for null pointers
    if (!values_a || !values_b || !result) {
        return false;
    }
    
    // Initialize result matrix to zero
    int result_size = m_a * n_b;
    for (int idx = 0; idx < result_size; ++idx) {
        result[idx] = 0.0;
    }
    
    // Optimized matrix multiplication with i-k-j loop order for better cache locality
    for (int i = 0; i < m_a; ++i) {           // Rows of A (and result)
        for (int k = 0; k < n_a; ++k) {       // Columns of A (rows of B)
            double a_ik = values_a[i * n_a + k];  // Cache this element
            for (int j = 0; j < n_b; ++j) {   // Columns of B (and result)
                result[i * n_b + j] += a_ik * values_b[k * n_b + j];
            }
        }
    }
    
    return true;
}

/**
 * Scale a matrix by a constant factor
 * 
 * @param m Number of rows in matrix
 * @param n Number of columns in matrix
 * @param values Pointer to matrix data (modified in-place)
 * @param scale_factor Factor to multiply each element by
 */
void matrix_scale(int m, int n, double* values, double scale_factor) {
    if (!values) return;
    
    int size = m * n;
    for (int i = 0; i < size; ++i) {
        values[i] *= scale_factor;
    }
}

/**
 * Copy matrix data
 * 
 * @param m Number of rows
 * @param n Number of columns
 * @param src Source matrix data
 * @param dst Destination matrix data (must be pre-allocated)
 */
void matrix_copy(int m, int n, const double* src, double* dst) {
    if (!src || !dst) return;
    
    int size = m * n;
    for (int i = 0; i < size; ++i) {
        dst[i] = src[i];
    }
}

/**
 * Print matrix for debugging (requires Serial to be initialized)
 * 
 * @param m Number of rows
 * @param n Number of columns
 * @param values Pointer to matrix data
 * @param name Optional name for the matrix
 */
void matrix_print(int m, int n, const double* values, const char* name) {
    if (!values) {
        Serial.println("Matrix is null");
        return;
    }
    
    if (name) {
        Serial.printf("%s (%dx%d):\n", name, m, n);
    } else {
        Serial.printf("Matrix (%dx%d):\n", m, n);
    }
    
    for (int i = 0; i < m; ++i) {
        for (int j = 0; j < n; ++j) {
            Serial.printf("%.6f\t", values[i * n + j]);
        }
        Serial.println();
    }
}
