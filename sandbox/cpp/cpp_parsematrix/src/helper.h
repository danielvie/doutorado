#pragma once

#include <cstdint>
#include <iostream>
#include <vector>
#include <string>

enum class ERROR_CODE {
    OK,
    INVALID_ARGUMENT_EMPTY,
    INVALID_ARGUMENT_MATRIX_COLUMNS_N_MUST_BE_A_POSITIVE_INTEGER,
    INVALID_ARGUMENT_MATRIX_ROWS_M_MUST_BE_A_POSITIVE_INTEGER,
    INVALID_ARGUMENT_NON_NUMERIC,
    RUNTIME_ERROR_MISSING_SEMICOLON,
    RUNTIME_ERROR_UNEXPECTED_CHARACTERS_AFTER_LAST_SEMICOLON,
    RUNTIME_ERROR_UNEXPECTED_ERROR
};

void print_error_code(ERROR_CODE err);
ERROR_CODE parse_message_data(const std::string& input_str, int& out_m, int& out_n, std::vector<double>& out_data, std::vector<uint64_t>& times, std::vector<uint64_t>& modes);