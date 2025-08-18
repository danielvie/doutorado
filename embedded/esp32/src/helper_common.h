#pragma once

#include <iostream>
#include <sstream>
#include <vector>
#include <driver/adc.h>
#include <numeric>
#include <chrono>
#include <random>

// Forward declarations
struct DataSet;

// ADC Configuration Constants
#define ADC_MAX 4095.0      // 12-bit ADC maximum value (2^12 - 1)
#define VOLTAGE_MAX 3.3     // Maximum voltage reference (3.3V)


enum class StatusONOFF {
    ON,
    OFF,
};


struct SystemStatus {
    StatusONOFF prop_control; // proportional control
    StatusONOFF log_last_calc;
};

extern SystemStatus g_system_status;

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
enum class SignalSet { 
    SET_A,      // Signal set A is active
    SET_B       // Signal set B is active
};

/**
 * Signal Generation Task States
 * Controls the behavior of the signal generation system
 */
enum class SignalTaskState { 
    IDLE,       // No signal generation, all outputs low
    HIGH_ALL,   // All outputs forced high (constant)
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

// Convert number to bit flags
Bin num2bin(uint32_t n);

// Split comma-separated list into vector
void parse_section(const std::string &section, std::vector<uint32_t> &result);

// Parse timing and mode from "time1,time2;mode1,mode2" string
int parse_signal(const std::string &s, std::vector<uint32_t> &time, std::vector<uint32_t> &mode);

// Calibrate raw ADC voltage to actual voltage
float esp32_calibration(float x);

// Read analog input and return calibrated voltage
float read_analog(AnalogPort port);

std::string get_signal_set_label(SignalSet set);
std::string get_ble_task_state_label(BLETaskState state);
std::string get_signal_task_state_label(SignalTaskState state);
std::string get_status_onoff_label(StatusONOFF status);
DataSet* get_dataset_from_set(SignalSet set);
uint32_t get_rand_int(uint32_t a, uint32_t b);

// Print error code to Serial
void print_error_code(ERROR_CODE err);

// Parse control message into parameters (rows, cols, gain, times, modes, target)
ERROR_CODE parse_control_message(const std::string& input_str, std::vector<float>& gain_k_data, int& out_m, int& out_n, std::vector<uint32_t>& times, std::vector<uint32_t>& modes, std::vector<float>& target);

void print_vec_i32(const std::vector<int32_t>& V, const std::string& name);
void print_vec_u32(const std::vector<uint32_t>& V, const std::string& name);

void print_array_i32(const int32_t* V,const size_t& len, const std::string& name);
void print_array_u32(const uint32_t* V,const size_t& len, const std::string& name);


void print_dataset(DataSet* d);
void print_ts_us_constructed();

// Adjust timing based on constraints and return status
void condition_dtk_signal(const std::vector<uint32_t>& time_us, const float& time_constraint_us, int32_t* dtk_us, size_t dtk_len);
