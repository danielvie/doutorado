#include "Matrix.h"

// --- Helper Function for Safe String to Double Conversion ---
double safeStod(const std::string& s) {
    size_t pos;
    // Check for empty string or string containing only whitespace
    if (s.empty() || s.find_first_not_of(" \t\n\v\f\r") == std::string::npos) {
        throw std::invalid_argument("Empty or whitespace-only string cannot be converted to double.");
    }
    double value = std::stod(s, &pos);
    // Ensure no non-numeric characters remain after conversion
    if (pos != s.length()) {
        throw std::invalid_argument("Non-numeric characters found after number: '" + s + "'");
    }
    return value;
}

// --- Utility Function to Parse the Matrix String Format ---
// This function extracts m, n, and the flattened data vector.
// It throws exceptions for format errors.
void parse_matrix_string(const std::string& input_str, int& out_m, int& out_n, std::vector<double>& out_data) {
    std::string s = input_str;
    out_data.clear(); // Ensure output vector is clean

    try {
        // --- 1. Parse 'm' (rows) ---
        size_t first_semicolon_pos = s.find(';');
        if (first_semicolon_pos == std::string::npos) {
            throw std::runtime_error("Missing first semicolon (after m). Input: '" + input_str + "'");
        }
        std::string m_str = s.substr(0, first_semicolon_pos);
        out_m = safeStod(m_str);
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
        out_n = safeStod(n_str);
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
                out_data.push_back(safeStod(num_str));
                start_pos = comma_pos + 1;
            }
            // Add the last number (or the only number if no commas)
            std::string last_num_str = data_str_segment.substr(start_pos);
            out_data.push_back(safeStod(last_num_str));
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


// Constructor for explicit dimensions and data
Matrix::Matrix(int rows, int cols, const std::vector<double>& data)
    : m_is_valid(true), m_rows(rows), m_cols(cols), m_data(data) {

    if (m_rows <= 0 || m_cols <= 0) {
        m_is_valid = false;
    }
    if (m_data.size() != static_cast<size_t>(m_rows * m_cols)) {
        m_is_valid = false;
    }
}

// Static factory method to create a Matrix from the specific string format
Matrix Matrix::from_string(const std::string& matrix_str) {
    int m, n;
    std::vector<double> data;
    parse_matrix_string(matrix_str, m, n, data); // Uses the utility function
    return Matrix(m, n, data); // Construct the matrix
}

// Accessors
int Matrix::get_rows() const {
    return m_rows;
}
int Matrix::get_cols() const {
    return m_cols;
}
int Matrix::is_valid() const {
    return m_is_valid;
}

// Get element at (row, col)
double Matrix::get_element(int row, int col) const {
    if (row < 0 || row >= m_rows || col < 0 || col >= m_cols) {
        throw std::out_of_range("Matrix element access out of bounds.");
    }
    return m_data[col * m_rows + row];
}

// Set element at (row, col)
void Matrix::set_element(int row, int col, int value) {
    if (row < 0 || row >= m_rows || col < 0 || col >= m_cols) {
        throw std::out_of_range("Matrix element access out of bounds.");
    }
    m_data[row * m_cols + col] = value;
}

// Matrix Multiplication
// Returns a new Matrix object representing the product
Matrix Matrix::multiply(const Matrix& other) const {
    int result_rows = m_rows;
    int result_cols = other.m_cols;
    std::vector<double> result_data(result_rows * result_cols, 0.0); // Initialize to 0

    // Cache data pointers to avoid repeated vector access overhead
    const double* this_data = m_data.data();
    const double* other_data = other.m_data.data();
    double* result_ptr = result_data.data();

    // Optimized loop order: i-k-j for better cache locality
    for (int i = 0; i < result_rows; ++i) {
        for (int k = 0; k < m_cols; ++k) {
            double this_ik = this_data[k * m_rows + i]; // Cache this element
            for (int j = 0; j < result_cols; ++j) {
                result_ptr[i * result_cols + j] += this_ik * other_data[j * other.m_rows + k];
            }
        }
    }
    return Matrix(result_rows, result_cols, result_data);
}

/**
 * Specialized multiplication with 3-element vector (optimized, no object creation)
 * Multiplies this matrix by a 3x1 vector [x1, x2, x3]
 * Result is stored in the provided result array (must be pre-allocated with size = number of rows)
 * 
 * @param x1 First element of the 3x1 vector
 * @param x2 Second element of the 3x1 vector  
 * @param x3 Third element of the 3x1 vector
 * @param result Pointer to result array (must be pre-allocated with size = m_rows)
 */
void Matrix::multiply_vector3(double x1, double x2, double x3, double* result) const {
    if (!m_is_valid || m_cols != 3 || !result) {
        return; // Invalid matrix or wrong dimensions or null result pointer
    }
    
    // Cache data pointer to avoid repeated vector access overhead
    const double* data_ptr = m_data.data();
    
    // Use the same indexing as get_element(): col * m_rows + row (column-major)
    for (int i = 0; i < m_rows; ++i) {
        result[i] = data_ptr[0 * m_rows + i] * x1 +     // matrix[i][0] * x1
                    data_ptr[1 * m_rows + i] * x2 +     // matrix[i][1] * x2  
                    data_ptr[2 * m_rows + i] * x3;      // matrix[i][2] * x3
    }
}

Matrix& Matrix::scale(const double value) {
    for (size_t i = 0; i < m_data.size(); ++i) {
        m_data[i] *= value;
    }
    return *this;
}

// Print the matrix
void Matrix::print() const {
    Serial.printf("Matrix (%dx%d):\n", m_rows, m_cols);
    for (int i = 0; i < m_rows; ++i) {
        for (int j = 0; j < m_cols; ++j) {
            if ((i * m_cols + j) >= m_data.size()) {
                break;
            }
            Serial.printf("%f\t", get_element(i, j));
        }
        Serial.println("");
    }
}
