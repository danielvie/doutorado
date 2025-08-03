#pragma once

// #include <iostream>
#include <Arduino.h>
#include <vector>
#include <string>
#include "signal_controller.h"

int safeStoi(const std::string& s);
void parse_matrix_string(const std::string& input_str, int& out_m, int& out_n, std::vector<float>& out_data);

class Matrix {
public:
    bool m_is_valid;
    int m_rows;
    int m_cols;
    std::vector<float> m_data; // Stored in row-major order

public:
    // Constructor for explicit dimensions and data
    Matrix(int rows, int cols, const std::vector<float>& data);

    Matrix(MatrixData& gain_k);

    // Static factory method to create a Matrix from the specific string format
    static Matrix from_string(const std::string& matrix_str);

    // Accessors
    int get_rows() const;
    int get_cols() const;
    int is_valid() const;

    // Get element at (row, col)
    float get_element(int row, int col) const;

    // Set element at (row, col)
    void set_element(int row, int col, int value);

    // Matrix Multiplication
    Matrix multiply(const Matrix& other) const;
    
    // Specialized multiplication with 3-element vector (optimized, no object creation)
    void multiply_vector3(float x1, float x2, float x3, float* result) const;
    
    Matrix& scale(const float value);

    // Print the matrix
    void print() const;
};
