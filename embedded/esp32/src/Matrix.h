#pragma once

// #include <iostream>
#include <Arduino.h>
#include <vector>
#include <string>

int safeStoi(const std::string& s);
void parse_matrix_string(const std::string& input_str, int& out_m, int& out_n, std::vector<double>& out_data);

class Matrix {
public:
    bool m_is_valid;
    int m_rows;
    int m_cols;
    std::vector<double> m_data; // Stored in row-major order

public:
    // Constructor for explicit dimensions and data
    Matrix(int rows, int cols, const std::vector<double>& data);

    // Static factory method to create a Matrix from the specific string format
    static Matrix from_string(const std::string& matrix_str);

    // Accessors
    int get_rows() const;
    int get_cols() const;
    int is_valid() const;

    // Get element at (row, col)
    double get_element(int row, int col) const;

    // Set element at (row, col)
    void set_element(int row, int col, int value);

    // Matrix Multiplication
    Matrix multiply(const Matrix& other) const;
    Matrix& scale(const double value);

    // Print the matrix
    void print() const;
};
