#pragma once

#include <iostream>
#include <sstream>
#include <vector>
#include <driver/adc.h>
#include <numeric>


// ADC Configuration Constants
#define ADC_MAX 4095.0      // 12-bit ADC maximum value (2^12 - 1)
#define VOLTAGE_MAX 3.3     // Maximum voltage reference (3.3V)


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

enum class Result{
    OK,
    FAIL,
};

/**
 * Binary representation structure for digital output control
 * Each boolean represents a single bit/pin state
 * Used to decompose numeric modes into individual pin states
 */
struct Bin {
    bool b1;
    bool b2;
    bool b3;
    bool b4;
    bool b5;
    bool b6;
};

/**
 * Signal Set Management
 * Defines which signal buffer set is currently active for float-buffering
 */
enum class ActiveSignalSet { 
    SET_A,      // Signal set A is active
    SET_B       // Signal set B is active
};

/**
 * Signal Generation Task States
 * Controls the behavior of the signal generation system
 */
enum class SignalTaskState { 
    IDLE,       // No signal generation, all outputs low
    HIGH_RUN,   // All outputs forced high (constant)
    SIGNAL_RUN  // Active signal pattern generation
};

/**
 * BLE Communication Task States
 * Manages the state of BLE operations and data acquisition
 */
enum class BLETaskState { 
    IDLE,           // No active BLE operations
    ANALOG_READ,    // Request to read analog sensors
    ANALOG_READING, // Currently reading analog sensors
    SIGNAL_READING  // Currently processing new signal data
};

/**
 * Analog Input Port Mapping
 * Maps logical analog port numbers to physical ADC channels
 */
enum class AnalogPort { 
    AN1 = 1,    // Analog input 1
    AN2 = 2,    // Analog input 2
    AN3 = 3,    // Analog input 3
    AN4 = 4,    // Analog input 4
    AN5 = 5,    // Analog input 5
    AN6 = 6     // Analog input 6
};

// Function Declarations

/**
 * Convert a numeric value to binary representation
 * @param n Input number to convert
 * @return Bin structure with individual bit flags
 */
struct Bin num2bin(uint64_t n);

/**
 * Parse a comma-separated section of a signal string
 * @param section String containing comma-separated values
 * @param result Vector to store parsed numeric values
 */
void _parse_section(const std::string &section, std::vector<uint64_t> &result);

/**
 * Parse a complete signal string containing timing and mode data
 * Expected format: "time1,time2,time3;mode1,mode2,mode3"
 * @param s Input signal string to parse
 * @param time Vector to store timing values
 * @param mode Vector to store mode values
 * @return 1 on success, 0 on failure
 */
int parse_signal(const std::string &s, std::vector<uint64_t> &time, std::vector<uint64_t> &mode);

/**
 * Apply calibration transformation to ESP32 voltage reading
 * Converts raw ESP32 ADC voltage to calibrated measurement
 * @param x Raw voltage reading from ESP32 ADC
 * @return Calibrated voltage value
 */
float esp32_calibration(float x);

/**
 * Read analog voltage from specified port
 * Handles ADC channel mapping and voltage conversion
 * @param port Analog port to read from
 * @return Calibrated voltage reading in volts, or -9.9V for invalid ports
 */
float read_analog(AnalogPort port);

void print_error_code(ERROR_CODE err);
ERROR_CODE parse_control_message(const std::string& input_str, int& out_m, int& out_n, std::vector<float>& gain_k_data, std::vector<uint64_t>& times, std::vector<uint64_t>& mode, std::vector<float>& target);