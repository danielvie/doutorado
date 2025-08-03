#include "MatrixMath.h"

/* bool matrix_multiply(int& rows_a, int& cols_a, std::vector<float>& values_a,
                    int rows_b, int cols_b, std::vector<float> values_b,
                    std::vector<float>& result) {
    
    // Check dimension compatibility
    if (cols_a != rows_b) {
        return false;  // Incompatible dimensions
    }
    
    // Initialize result matrix to zero
    int result_size = rows_a * cols_b;
    result.clear();
    result.resize(result_size, 0.0f);
    
    // Optimized matrix multiplication with i-k-j loop order for better cache locality
    for (int i = 0; i < rows_a; ++i) {           // Rows of A (and result)
        for (int k = 0; k < cols_a; ++k) {       // Columns of A (rows of B)
            float a_ik = values_a[i * cols_a + k];  // Cache this element
            for (int j = 0; j < cols_b; ++j) {   // Columns of B (and result)
                result[i * cols_b + j] += a_ik * values_b[k * cols_b + j];
            }
        }
    }
    
    return true;
} */


bool matrix_isvalid(MatrixData& M) {
    // rows -> m
    // cols -> n
    // values -> matrix(:)
    
    if (M.rows <= 0 || M.cols <= 0) {
        return false;
    }
    if (M.values.size() != static_cast<size_t>(M.rows*M.cols)) {
        return false;
    }
    
    return true;
}

bool matrix_multiply_vector3(MatrixData& M, float x1, float x2, float x3, float* result) {
    // Cache data pointer to avoid repeated vector access overhead
    const float* data_ptr = M.values.data();
    
    // Use the same indexing as get_element(): col * m_rows + row (column-major)
    for (int i = 0; i < M.rows; ++i) {
        result[i] = data_ptr[0 * M.rows + i] * x1 +     // matrix[i][0] * x1
                    data_ptr[1 * M.rows + i] * x2 +     // matrix[i][1] * x2  
                    data_ptr[2 * M.rows + i] * x3;      // matrix[i][2] * x3
    }
    return true;
}

void matrix_print(MatrixData& M) {
    if (!matrix_isvalid(M)) {
        Serial.println("Matrix is not valid!!");
        return;
    }
    
    Serial.printf("Matrix (%dx%d):\n", M.rows, M.cols);
    for (int i = 0; i < M.rows; ++i) {
        for (int j = 0; j < M.cols; ++j) {
            Serial.printf("%.6f\t", M.values[i * M.cols + j]);
        }
        Serial.println();
    }
}


// bool matrix_isvalid(int rows, int cols, std::vector<float> values){
//     // rows -> m
//     // cols -> n
//     // values -> matrix(:)
    
//     if (rows <= 0 || cols <= 0) {
//         return false;
//     }
//     if (values.size() != static_cast<size_t>(rows*cols)) {
//         return false;
//     }
    
//     return true;
// }