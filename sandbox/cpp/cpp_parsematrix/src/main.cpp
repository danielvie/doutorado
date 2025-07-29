#include <iostream>
#include <vector>
#include <string>
#include <cassert>
// #include <sstream> // For potential future use, though stoi is direct
#include <stdexcept> // For std::runtime_error, std::invalid_argument, std::out_of_range
// #include <limits>    // For std::numeric_limits

// --- Helper Function for Safe String to Integer Conversion ---
// (Reused from previous turn, made slightly more generic)
int safeStoi(const std::string& s) {
    size_t pos;
    // Check for empty string or string containing only whitespace
    if (s.empty() || s.find_first_not_of(" \t\n\v\f\r") == std::string::npos) {
        throw std::invalid_argument("Empty or whitespace-only string cannot be converted to integer.");
    }
    int value = std::stoi(s, &pos);
    // Ensure no non-numeric characters remain after conversion
    if (pos != s.length()) {
        throw std::invalid_argument("Non-numeric characters found after number: '" + s + "'");
    }
    return value;
}

// --- Utility Function to Parse the Matrix String Format ---
// This function extracts m, n, and the flattened data vector.
// It throws exceptions for format errors.
void parse_matrix_string(const std::string& input_str, int& out_m, int& out_n, std::vector<int>& out_data) {
    std::string s = input_str;
    out_data.clear(); // Ensure output vector is clean

    try {
        // --- 1. Parse 'm' (rows) ---
        size_t first_semicolon_pos = s.find(';');
        if (first_semicolon_pos == std::string::npos) {
            throw std::runtime_error("Missing first semicolon (after m). Input: '" + input_str + "'");
        }
        std::string m_str = s.substr(0, first_semicolon_pos);
        out_m = safeStoi(m_str);
        if (out_m <= 0) {
            throw std::invalid_argument("Matrix rows (m) must be a positive integer.");
        }

        s = s.substr(first_semicolon_pos + 1); // Consume 'm' and its semicolon

        // --- 2. Parse 'n' (columns) ---
        size_t second_semicolon_pos = s.find(';');
        if (second_semicolon_pos == std::string::npos) {
            throw std::runtime_error("Missing second semicolon (after n). Input: '" + input_str + "'");
        }
        std::string n_str = s.substr(0, second_semicolon_pos);
        out_n = safeStoi(n_str);
        if (out_n <= 0) {
            throw std::invalid_argument("Matrix columns (n) must be a positive integer.");
        }

        s = s.substr(second_semicolon_pos + 1); // Consume 'n' and its semicolon

        // --- 3. Parse 'data' vector ---
        size_t last_semicolon_pos = s.find(';');
        if (last_semicolon_pos == std::string::npos) {
            throw std::runtime_error("Missing final semicolon (after data). Input: '" + input_str + "'");
        }
        std::string data_str_segment = s.substr(0, last_semicolon_pos);

        // Check for unexpected trailing characters after the final semicolon
        if (s.length() > last_semicolon_pos + 1) {
            throw std::runtime_error("Unexpected characters after final semicolon. Input: '" + input_str + "'");
        }

        // Handle empty data segment (e.g., "9;5;;")
        if (!data_str_segment.empty()) {
            size_t start_pos = 0;
            size_t comma_pos;
            while ((comma_pos = data_str_segment.find(',', start_pos)) != std::string::npos) {
                std::string num_str = data_str_segment.substr(start_pos, comma_pos - start_pos);
                out_data.push_back(safeStoi(num_str));
                start_pos = comma_pos + 1;
            }
            // Add the last number (or the only number if no commas)
            std::string last_num_str = data_str_segment.substr(start_pos);
            out_data.push_back(safeStoi(last_num_str));
        }

    } catch (const std::invalid_argument& e) {
        throw std::runtime_error("Parsing error: Invalid number format in string: " + std::string(e.what()));
    } catch (const std::out_of_range& e) {
        throw std::runtime_error("Parsing error: Number out of range in string: " + std::string(e.what()));
    } catch (const std::runtime_error& e) {
        // Re-throw custom runtime errors
        throw;
    } catch (const std::exception& e) {
        throw std::runtime_error("An unexpected error occurred during string parsing: " + std::string(e.what()));
    }
}


// --- Matrix Class Definition ---
class Matrix {
private:
    bool m_is_valid;
    int m_rows;
    int m_cols;
    std::vector<int> m_data; // Stored in row-major order

public:
    // Constructor for explicit dimensions and data
    Matrix(int rows, int cols, const std::vector<int>& data)
        : m_is_valid(true), m_rows(rows), m_cols(cols), m_data(data) {

        // Assert: Dimensions must be positive.
        // assert(m_rows > 0 && m_cols > 0 && "Matrix dimensions must be positive.");

        // Assert: Data vector size must match matrix dimensions.
        // assert(m_data.size() == static_cast<size_t>(m_rows * m_cols) &&
        //        "Data vector size does not match matrix dimensions (rows * cols).");

        if (m_rows <= 0 || m_cols <= 0) {
            m_is_valid = false;
            // throw std::invalid_argument("Matrix dimensions must be positive.");
        }
        if (m_data.size() != static_cast<size_t>(m_rows * m_cols)) {
            m_is_valid = false;
            // throw std::invalid_argument("Data vector size does not match matrix dimensions (rows * cols).");
        }
    }

    // Static factory method to create a Matrix from the specific string format
    static Matrix from_string(const std::string& matrix_str) {
        int m, n;
        std::vector<int> data;
        parse_matrix_string(matrix_str, m, n, data); // Uses the utility function
        return Matrix(m, n, data); // Construct the matrix
    }

    // Accessors
    int get_rows() const { return m_rows; }
    int get_cols() const { return m_cols; }
    int is_valid() const { return m_is_valid; }

    // Get element at (row, col)
    int get_element(int row, int col) const {
        if (row < 0 || row >= m_rows || col < 0 || col >= m_cols) {
            throw std::out_of_range("Matrix element access out of bounds.");
        }
        return m_data[row * m_cols + col];
    }

    // Set element at (row, col)
    void set_element(int row, int col, int value) {
        if (row < 0 || row >= m_rows || col < 0 || col >= m_cols) {
            throw std::out_of_range("Matrix element access out of bounds.");
        }
        m_data[row * m_cols + col] = value;
    }

    // Matrix Multiplication
    // Returns a new Matrix object representing the product
    Matrix multiply(const Matrix& other) const {
        if (m_cols != other.m_rows) {
            throw std::invalid_argument("Matrix dimensions mismatch for multiplication: A.cols (" +
                                        std::to_string(m_cols) + ") != B.rows (" +
                                        std::to_string(other.m_rows) + ")");
        }

        int result_rows = m_rows;
        int result_cols = other.m_cols;
        std::vector<int> result_data(result_rows * result_cols);

        for (int i = 0; i < result_rows; ++i) { // Iterate through rows of result matrix (and A)
            for (int j = 0; j < result_cols; ++j) { // Iterate through columns of result matrix (and B)
                int sum = 0;
                for (int k = 0; k < m_cols; ++k) { // Iterate through columns of A (and rows of B)
                    sum += this->get_element(i, k) * other.get_element(k, j);
                }
                result_data[i * result_cols + j] = sum;
            }
        }
        return Matrix(result_rows, result_cols, result_data);
    }

    // Print the matrix
    void print() const {
        std::cout << "Matrix (" << m_rows << "x" << m_cols << "):" << std::endl;
        for (int i = 0; i < m_rows; ++i) {
            for (int j = 0; j < m_cols; ++j) {
                if ((i * m_cols + j) >= m_data.size()) {
                    break;
                }
                std::cout << get_element(i, j) << "\t";
            }
            std::cout << std::endl;
        }
    }
};

// --- Main function for demonstration ---
int main() {

    // --- Test Cases for String Parsing and Matrix Creation ---
    // std::string str_matrix_A = "2;3;1,2,3,4,5,6;";          // 2x3 matrix
    std::string str_matrix_A = "2;4;1,2,3,4,5,6;";          // 2x3 matrix
    std::string str_matrix_B = "3;2;7,8,9,10,11,12;";       // 3x2 matrix

    // --- Test Matrix Multiplication ---
    std::cout << "\n--- Testing Matrix Multiplication ---" << std::endl;

    Matrix matrixA = Matrix::from_string(str_matrix_A); // 2x3
    Matrix matrixB(3,1,{1,2,3});
    
    if (!matrixA.is_valid()) {
        std::cout << "matrix A is not valid!\n";
        matrixA.print();
        
        return 0;
    }


    // Matrix matrixB = Matrix::fromString(str_matrix_B); // 3x2

    // std::cout << "Matrix A:" << std::endl;
    // matrixA.print();
    // std::cout << "\n";
    // std::cout << "Matrix B:" << std::endl;
    // matrixB.print();

    // Matrix result_AB = matrixA.multiply(matrixB); // Result should be 2x2
    // std::cout << "\n";
    // std::cout << "Result A * B:" << std::endl;
    // result_AB.print();

    // Expected result for A*B:
    // (1*7 + 2*9 + 3*11) = 7 + 18 + 33 = 58
    // (1*8 + 2*10 + 3*12) = 8 + 20 + 36 = 64
    // (4*7 + 5*9 + 6*11) = 28 + 45 + 66 = 139
    // (4*8 + 5*10 + 6*12) = 32 + 50 + 72 = 154
    // Result should be:
    // 58   64
    // 139  154

    return 0;
}