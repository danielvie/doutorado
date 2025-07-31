#include "helper.h"
#include <cstdint>
#include <string>
#include <vector>


void print_error_code(ERROR_CODE err) {

    switch (err) {
        case ERROR_CODE::OK:
            std::cout << "OK\n";
            break;
        case ERROR_CODE::INVALID_ARGUMENT_EMPTY:
            std::cout << "INVALID_ARGUMENT_EMPTY\n";
            break;
        case ERROR_CODE::INVALID_ARGUMENT_NON_NUMERIC:
            std::cout << "INVALID_ARGUMENT_NON_NUMERIC\n";
            break;
        case ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON:
            std::cout << "RUNTIME_ERROR_MISSING_SEMICOLON\n";
            break;
        case ERROR_CODE::INVALID_ARGUMENT_MATRIX_ROWS_M_MUST_BE_A_POSITIVE_INTEGER:
            std::cout << "INVALID_ARGUMENT_MATRIX_ROWS_M_MUST_BE_A_POSITIVE_INTEGER\n";
            break;
        case ERROR_CODE::INVALID_ARGUMENT_MATRIX_COLUMNS_N_MUST_BE_A_POSITIVE_INTEGER:
            std::cout << "INVALID_ARGUMENT_MATRIX_COLUMNS_N_MUST_BE_A_POSITIVE_INTEGER\n";
            break;
        case ERROR_CODE::RUNTIME_ERROR_UNEXPECTED_CHARACTERS_AFTER_LAST_SEMICOLON:
            std::cout << "RUNTIME_ERROR_UNEXPECTED_CHARACTERS_AFTER_LAST_SEMICOLON\n";
            break;
        case ERROR_CODE::RUNTIME_ERROR_UNEXPECTED_ERROR:
            std::cout << "RUNTIME_ERROR_UNEXPECTED_ERROR\n";
            break;
    }

}

ERROR_CODE safe_stoi(const std::string& s, int &number) {
    size_t pos;
    // Check for empty string or string containing only whitespace
    if (s.empty() || s.find_first_not_of(" \t\n\v\f\r") == std::string::npos) {
        return ERROR_CODE::INVALID_ARGUMENT_EMPTY;
    }
    number = std::stoi(s, &pos);
    // Ensure no non-numeric characters remain after conversion
    if (pos != s.length()) {
        return ERROR_CODE::INVALID_ARGUMENT_NON_NUMERIC;
    }
    
    return ERROR_CODE::OK;
}

ERROR_CODE safe_stod(const std::string& s, double &number) {
    size_t pos;
    // Check for empty string or string containing only whitespace
    if (s.empty() || s.find_first_not_of(" \t\n\v\f\r") == std::string::npos) {
        return ERROR_CODE::INVALID_ARGUMENT_EMPTY;
    }
    number = std::stod(s, &pos);
    // Ensure no non-numeric characters remain after conversion
    if (pos != s.length()) {
        return ERROR_CODE::INVALID_ARGUMENT_NON_NUMERIC;
    }
    
    return ERROR_CODE::OK;
}

ERROR_CODE parse_message_data(const std::string& input_str, int& out_m, int& out_n, std::vector<double>& gain_k_data, std::vector<uint64_t>& times, std::vector<uint64_t>& modes) {
    std::string s = input_str;
    gain_k_data.clear(); // Ensure output vector is clean
    times.clear();    // Ensure output vector is clean
    modes.clear();    // Ensure output vector is clean

    try {
        // --- 1. Parse 'm' (rows) ---
        size_t semicolon_pos = s.find(';');
        if (semicolon_pos == std::string::npos) {
            return ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON;
        }
        std::string m_str = s.substr(0, semicolon_pos);
        safe_stoi(m_str, out_m);
        if (out_m <= 0) {
            return ERROR_CODE::INVALID_ARGUMENT_MATRIX_ROWS_M_MUST_BE_A_POSITIVE_INTEGER;
        }

        s = s.substr(semicolon_pos + 1); // Consume 'm' and its semicolon

        // --- 2. Parse 'n' (columns) ---
        semicolon_pos = s.find(';');
        if (semicolon_pos == std::string::npos) {
            return ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON;
        }
        std::string n_str = s.substr(0, semicolon_pos);
        safe_stoi(n_str, out_n);
        if (out_n <= 0) {
            return ERROR_CODE::INVALID_ARGUMENT_MATRIX_COLUMNS_N_MUST_BE_A_POSITIVE_INTEGER;
        }

        s = s.substr(semicolon_pos + 1); // Consume 'n' and its semicolon

        // --- 3. Parse 'gain_k_data' vector ---
        semicolon_pos = s.find(';');
        if (semicolon_pos == std::string::npos) {
            return ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON;
        }
        std::string gain_k_str_segment = s.substr(0, semicolon_pos);

        // Handle empty data segment (e.g., "9;5;;")
        if (gain_k_str_segment.empty()) {
            return ERROR_CODE::INVALID_ARGUMENT_EMPTY;
        }

        size_t start_pos = 0;
        size_t comma_pos;
        double value_double = 0.0;
        std::string num_str;

        while ((comma_pos = gain_k_str_segment.find(',', start_pos)) != std::string::npos) {
            num_str = gain_k_str_segment.substr(start_pos, comma_pos - start_pos);
            safe_stod(num_str, value_double);
            gain_k_data.push_back(value_double);
            start_pos = comma_pos + 1;
        }
        // Add the last number (or the only number if no commas)
        std::string last_num_str = gain_k_str_segment.substr(start_pos);
        safe_stod(last_num_str, value_double);
        gain_k_data.push_back(value_double);

        s = s.substr(semicolon_pos + 1); // Consume 'gain_k_data' and its semicolon

        // --- 4. Parse 'time[]' vector ---
        semicolon_pos = s.find(';');
        if (semicolon_pos == std::string::npos) {
            return ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON;
        }

        std::string times_str_segment = s.substr(0, semicolon_pos);
        if (times_str_segment.empty()) {
            return ERROR_CODE::INVALID_ARGUMENT_EMPTY;
        }

        start_pos = 0;
        int value_int;

        while ((comma_pos = times_str_segment.find(',', start_pos)) != std::string::npos) {
            num_str = times_str_segment.substr(start_pos, comma_pos - start_pos);
            safe_stoi(num_str, value_int);
            times.push_back(value_int);
            start_pos = comma_pos + 1;
        }
        std::string last_time_str = times_str_segment.substr(start_pos);
        safe_stoi(last_time_str, value_int);
        times.push_back(value_int);

        s = s.substr(semicolon_pos + 1); // Consume 'times' and its semicolon

        // --- 5. Parse 'modes[]' vector ---
        semicolon_pos = s.find(';');
        std::string modes_str_segment;
        if (semicolon_pos != std::string::npos) {
            modes_str_segment = s.substr(0, semicolon_pos);
        } else {
            // No final semicolon, take the rest of the string
            modes_str_segment = s;
        }
        
        if (modes_str_segment.empty()) {
            return ERROR_CODE::INVALID_ARGUMENT_EMPTY;
        }
        
        start_pos = 0;

        while ((comma_pos = modes_str_segment.find(',', start_pos)) != std::string::npos) {
            num_str = modes_str_segment.substr(start_pos, comma_pos - start_pos);
            safe_stoi(num_str, value_int);
            modes.push_back(value_int);
            start_pos = comma_pos + 1;
        }
        std::string last_str_segment = modes_str_segment.substr(start_pos);
        safe_stoi(last_str_segment, value_int);
        modes.push_back(value_int);

        // Check for unexpected trailing characters after the final semicolon
        if (semicolon_pos != std::string::npos && s.length() > semicolon_pos + 1) {
            return ERROR_CODE::RUNTIME_ERROR_UNEXPECTED_CHARACTERS_AFTER_LAST_SEMICOLON;
        }

    } catch (const std::exception& e) {
        return ERROR_CODE::RUNTIME_ERROR_UNEXPECTED_ERROR;
    }
    return ERROR_CODE::OK;
}
