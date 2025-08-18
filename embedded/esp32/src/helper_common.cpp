/**
 * Helper Functions Implementation for ESP32 Signal Controller
 * 
 * This file implements utility functions for signal processing,
 * data parsing, and analog sensor interfacing.
 */

#include <math.h>
#include "helper_common.h"
#include "signal_controller.h"
#include "ble_controller.h"
#include "Arduino.h"

// Convert a numeric value to binary representation structure
struct Bin num2bin(uint32_t num) {
    auto b = Bin();
    b.b1 = num & 0x1;
    b.b2 = num & 0x2;
    b.b3 = num & 0x4;
    b.b4 = num & 0x8;
    b.b5 = num & 0x16;
    b.b6 = num & 0x32;

    return b;
}

SystemStatus g_system_status = {
    .prop_control = StatusONOFF::OFF,
    .log_last_calc = StatusONOFF::OFF,
};

// calibration function
// Apply calibration transformation to ESP32 voltage reading
float calib_from[] = {0.00, 0.07, 0.17, 0.26, 0.36, 0.46, 0.56, 0.66, 0.76, 0.86, 0.96, 1.06, 1.16, 1.27, 1.37, 1.46, 1.56, 1.67, 1.76, 1.86, 1.96, 2.06, 2.16, 2.27, 2.37, 2.49, 2.61, 2.75, 2.90, 3.07, 3.26, 3.30, 3.30};
float calib_to[]   = {0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00, 1.10, 1.20, 1.30, 1.40, 1.50, 1.60, 1.70, 1.80, 1.90, 2.00, 2.10, 2.20, 2.30, 2.40, 2.50, 2.60, 2.70, 2.80, 2.90, 3.00, 3.10, 3.20, 3.30};
int   calib_numel  = sizeof(calib_from) / sizeof(calib_from[0]);

//Read analog voltage from specified port with calibration
float read_analog(AnalogPort port) {
    int rawValue = 0;
    
    // Map logical port to physical ADC channel
    switch (port) {
        case AnalogPort::AN1:
            rawValue = adc1_get_raw(ADC1_CHANNEL_3);  // GPIO39
            break;
        case AnalogPort::AN2:
            rawValue = adc1_get_raw(ADC1_CHANNEL_5);  // GPIO33
            break;
        case AnalogPort::AN3:
            rawValue = adc1_get_raw(ADC1_CHANNEL_4);  // GPIO32
            break;
        case AnalogPort::AN4:
            rawValue = adc1_get_raw(ADC1_CHANNEL_7);  // GPIO35
            break;
        case AnalogPort::AN5:
            rawValue = adc1_get_raw(ADC1_CHANNEL_6);  // GPIO34
            break;
        case AnalogPort::AN6:
            rawValue = adc1_get_raw(ADC1_CHANNEL_0);  // GPIO36
            break;
        default:
            return -9.9f; // Error indicator for invalid ports
    }
    
    // Convert raw ADC value to voltage (0-3.3V range)
    float voltage = ((float)rawValue / ADC_MAX) * VOLTAGE_MAX;
    
    // Apply calibration transformation
    voltage = esp32_calibration(voltage);
    
    return voltage;
}

std::string get_status_onoff_label(StatusONOFF status) {
    if (status == StatusONOFF::ON) {
        return "ON";
    } else {
        return "OFF";
    }
}

std::string get_active_signal_set_label(ActiveSignalSet set) {
    switch (set)
    {
    case ActiveSignalSet::SET_A:
        return "SET_A";
    case ActiveSignalSet::SET_B:
        return "SET_B";
    default:
        return "-ERROR";
    }
}

std::string get_signal_task_state_label(SignalTaskState state) {
    switch (state)
    {
    case SignalTaskState::IDLE:
        return "IDLE";
    case SignalTaskState::HIGH_ALL:
        return "HIGH_ALL";
    case SignalTaskState::SIGNAL_RUN:
        return "SIGNAL_RUN";
    default:
        return "-ERROR";
    }
}

std::string get_ble_task_state_label(BLETaskState state) {
    switch (state)
    {
    case BLETaskState::IDLE:
        return "IDLE";
    case BLETaskState::ANALOG_READ:
        return "ANALOG_READ";
    case BLETaskState::ANALOG_READING:
        return "ANALOG_READING";
    case BLETaskState::SIGNAL_READING:
        return "SIGNAL_READING";
    default:
        return "-ERROR";
    }
}


float esp32_calibration(float value) {
    
    // return value;
    // lower boundary
    if (value <= calib_from[0]) {
        return calib_to[0];
    }
    
    // higher boundary
    if (value >= calib_from[calib_numel - 1]) {
        return calib_to[calib_numel-1];
    }
    
    // find the lookup interval
    for (int i = 0; i < calib_numel-1; ++i) {
        if (value >= calib_from[i] && value <= calib_from[i+1]) {
            float x1 = calib_from[i];
            float y1 = calib_to[i];
            float x2 = calib_from[i+1];
            float y2 = calib_to[i+1];
            
            // perform a linear interpolation
            if (x2 == x1) {
                return y1;
            }

            return y1 + (value - x1) * (y2 - y1) / (x2 - x1);
        }
    }
    
    // edge cases protection
    return calib_to[calib_numel - 1];
}

void print_error_code(ERROR_CODE err) {

    switch (err) {
        case ERROR_CODE::OK:
            Serial.println("OK");
            break;
        case ERROR_CODE::INVALID_ARGUMENT_EMPTY:
            Serial.println("INVALID_ARGUMENT_EMPTY");
            break;
        case ERROR_CODE::INVALID_ARGUMENT_NON_NUMERIC:
            Serial.println("INVALID_ARGUMENT_NON_NUMERIC");
            break;
        case ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON:
            Serial.println("RUNTIME_ERROR_MISSING_SEMICOLON");
            break;
        case ERROR_CODE::INVALID_ARGUMENT_MATRIX_ROWS_M_MUST_BE_A_POSITIVE_INTEGER:
            Serial.println("INVALID_ARGUMENT_MATRIX_ROWS_M_MUST_BE_A_POSITIVE_INTEGER");
            break;
        case ERROR_CODE::INVALID_ARGUMENT_MATRIX_COLUMNS_N_MUST_BE_A_POSITIVE_INTEGER:
            Serial.println("INVALID_ARGUMENT_MATRIX_COLUMNS_N_MUST_BE_A_POSITIVE_INTEGER");
            break;
        case ERROR_CODE::RUNTIME_ERROR_UNEXPECTED_CHARACTERS_AFTER_LAST_SEMICOLON:
            Serial.println("RUNTIME_ERROR_UNEXPECTED_CHARACTERS_AFTER_LAST_SEMICOLON");
            break;
        case ERROR_CODE::RUNTIME_ERROR_UNEXPECTED_ERROR:
            Serial.println("RUNTIME_ERROR_UNEXPECTED_ERROR");
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

ERROR_CODE safe_stod(const std::string& s, float &number) {
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

ERROR_CODE parse_control_message__vector_uint64(std::string& s, size_t& semicolon_pos, std::vector<uint32_t>& V) {
        s = s.substr(semicolon_pos + 1); // Consume previous and its semicolon
        semicolon_pos = s.find(';');
        if (semicolon_pos == std::string::npos) {
            return ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON;
        }

        std::string str_segment = s.substr(0, semicolon_pos);
        if (str_segment.empty()) {
            return ERROR_CODE::INVALID_ARGUMENT_EMPTY;
        }

        size_t start_pos = 0;
        size_t comma_pos;
        int value;

        while ((comma_pos = str_segment.find(',', start_pos)) != std::string::npos) {
            std::string str_element = str_segment.substr(start_pos, comma_pos - start_pos);
            safe_stoi(str_element, value);
            V.push_back(value);
            start_pos = comma_pos + 1;
        }
        std::string str_element = str_segment.substr(start_pos);
        safe_stoi(str_element, value);
        V.push_back(value);

        return ERROR_CODE::OK;
}

ERROR_CODE parse_control_message__vector_double(std::string& s, size_t& semicolon_pos, std::vector<float>& V) {
        s = s.substr(semicolon_pos + 1); // Consume previous and its semicolon
        semicolon_pos = s.find(';');
        if (semicolon_pos == std::string::npos) {
            return ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON;
        }

        std::string str_segment = s.substr(0, semicolon_pos);
        if (str_segment.empty()) {
            return ERROR_CODE::INVALID_ARGUMENT_EMPTY;
        }

        size_t start_pos = 0;
        size_t comma_pos;
        float value;

        while ((comma_pos = str_segment.find(',', start_pos)) != std::string::npos) {
            std::string str_element = str_segment.substr(start_pos, comma_pos - start_pos);
            safe_stod(str_element, value);
            V.push_back(value);
            start_pos = comma_pos + 1;
        }
        std::string str_element = str_segment.substr(start_pos);
        safe_stod(str_element, value);
        V.push_back(value);

        return ERROR_CODE::OK;
}

ERROR_CODE parse_control_message(const std::string& input_str, std::vector<float>& gain_k_data, int& out_m, int& out_n, std::vector<uint32_t>& times, std::vector<uint32_t>& modes, std::vector<float>& target) {

    // ensure that the vectors are clear
    gain_k_data.clear();
    times.clear();
    modes.clear();
    target.clear();

    std::string s = input_str;
    size_t semicolon_pos;

    try {
        // .. --- 1. Parse 'm' (rows) ---
        semicolon_pos = s.find(';');
        if (semicolon_pos == std::string::npos) {
            return ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON;
        }
        std::string str_element = s.substr(0, semicolon_pos);
        safe_stoi(str_element, out_m);
        if (out_m <= 0) {
            return ERROR_CODE::INVALID_ARGUMENT_MATRIX_ROWS_M_MUST_BE_A_POSITIVE_INTEGER;
        }

        // .. --- 2. Parse 'n' (columns) ---
        s = s.substr(semicolon_pos + 1); // Consume 'm' and its semicolon
        semicolon_pos = s.find(';');
        if (semicolon_pos == std::string::npos) {
            return ERROR_CODE::RUNTIME_ERROR_MISSING_SEMICOLON;
        }
        str_element = s.substr(0, semicolon_pos);
        safe_stoi(str_element, out_n);
        if (out_n <= 0) {
            return ERROR_CODE::INVALID_ARGUMENT_MATRIX_COLUMNS_N_MUST_BE_A_POSITIVE_INTEGER;
        }

        // .. --- 3. Parse 'gain_k_data' vector ---
        ERROR_CODE err = parse_control_message__vector_double(s,semicolon_pos,gain_k_data);
        if (err != ERROR_CODE::OK) {
            return err;
        }

        // .. --- 4. Parse 'time[]' vector ---
        err = parse_control_message__vector_uint64(s,semicolon_pos,times);
        if (err != ERROR_CODE::OK) {
            return err;
        }

        // .. --- 5. Parse 'modes[]' vector ---
        err = parse_control_message__vector_uint64(s,semicolon_pos,modes);
        if (err != ERROR_CODE::OK) {
            return err;
        }

        // .. --- 6. Parse 'target[]' vector ---
        err = parse_control_message__vector_double(s,semicolon_pos,target);
        if (err != ERROR_CODE::OK) {
            return err;
        }

        // .. Check for unexpected trailing characters after the final semicolon
        if (semicolon_pos != std::string::npos && s.length() > semicolon_pos + 1) {
            return ERROR_CODE::RUNTIME_ERROR_UNEXPECTED_CHARACTERS_AFTER_LAST_SEMICOLON;
        }

    } catch (const std::exception& e) {
        return ERROR_CODE::RUNTIME_ERROR_UNEXPECTED_ERROR;
    }
    return ERROR_CODE::OK;
}

// Parse a comma-separated section of a signal string
void parse_section(const std::string &section, std::vector<uint32_t> &result) {
    std::stringstream ss(section);
    std::string item;
    
    // Split by comma and convert each item to integer
    while (std::getline(ss, item, ',')) {
        result.push_back(std::stoi(item));
    }
}

// Parse a complete signal string containing timing and mode data
int parse_signal(const std::string &s, std::vector<uint32_t> &time, std::vector<uint32_t> &mode) {
    // Clear any existing values to start fresh
    time.clear();
    mode.clear();
    
    // Find the semicolon separator between timing and mode sections
    size_t semicolonPos = s.find(';');
    if (semicolonPos == std::string::npos) {
        throw std::runtime_error("No semicolon found");
        return 0;
    }
    
    // Extract timing section (before semicolon) and mode section (after semicolon)
    std::string timeSection = s.substr(0, semicolonPos);
    std::string modeSection = s.substr(semicolonPos + 1);
    
    // Parse each section into respective vectors
    parse_section(timeSection, time);
    parse_section(modeSection, mode);
    
    return 1;  // Success
}

void print_vec_i32(const std::vector<int32_t>& V, const std::string& name) {
    Serial.printf("%s: \n", name.c_str());
    for (auto el : V) {
        Serial.printf("%d,", el);
    }
    Serial.println("\n");
}

void print_vec_u32(const std::vector<uint32_t>& V, const std::string& name) {
    Serial.printf("%s: \n", name.c_str());
    for (auto el : V) {
        Serial.printf("%u,", el);
    }
    Serial.println("\n");
}

void print_array_i32(const int32_t* V,const size_t& len, const std::string& name) {
    Serial.printf("%s: \n", name.c_str());
    for (size_t i = 0; i < len; i++) {
        Serial.printf("%d,", V[i]);
    }
    Serial.println("\n");
}

void print_array_u32(const uint32_t* V,const size_t& len, const std::string& name) {
    Serial.printf("%s: \n", name.c_str());
    for (size_t i = 0; i < len; i++) {
        Serial.printf("%u,", V[i]);
    }
    Serial.println("\n");
}

void print_dataset(DataSet* d) {
    Serial.println("-- Dataset d:");
    print_vec_u32(d->time_vec, "d->time_vec");
    print_vec_u32(d->d4_vec, "d->d4_vec");
    print_vec_u32(d->d5_vec, "d->d5_vec");
    print_vec_u32(d->d6_vec, "d->d6_vec");
    print_vec_i32(d->time_us_diff, "d->time_us_diff");
    // print_vec_u32(d->target, "d->time_vec");
    Serial.println("-- \n");
}

void print_ts_us_constructed() {
    DataSet* d = (g_active_set == ActiveSignalSet::SET_A) ? &g_dataset_a : &g_dataset_b;

    size_t time_us_len = d->time_vec.size();

    std::vector<uint32_t> ts_us, ts_us_2;
    ts_us.resize(time_us_len+1, 0);
    ts_us_2.resize(time_us_len+1, 0);
    
    for (size_t i = 0; i < time_us_len; i++) {
        ts_us[i+1] = ts_us[i] + d->time_vec[i];
    }
    print_vec_u32(ts_us, "ts_us constructed");

    for (size_t i = 0; i < time_us_len; i++) {
        ts_us_2[i+1] = ts_us_2[i] + d->time_vec[i] + d->time_us_diff[i];
    }
    print_vec_u32(ts_us_2, "ts_us_2 constructed");

}


void condition_dtk_signal(const std::vector<uint32_t>& time_us, const float& time_constraint_us, int32_t* dtk_us, size_t dtk_len) {
    
    size_t ts_us_len = time_us.size()+1;

    auto compute_sum_u = [](const std::vector<uint32_t>& vec) -> uint32_t {
        return std::accumulate(vec.begin(), vec.end(), uint32_t(0));
    };

    auto compute_sum_array_i = [](const int32_t* vec, size_t dtk_len) -> int32_t {
        return std::accumulate(vec, vec + dtk_len, int32_t(0));
    };

    // create ts_us_ref
    std::vector<float> ts_us_ref(dtk_len + 2, 0.0);
    ts_us_ref[dtk_len+1] = std::round(compute_sum_u(time_us));
    
    for (int i=0; i < dtk_len; i++) {
        ts_us_ref[i+1] = ts_us_ref[i] + time_us[i];
    }

    // normalize dtk to the cycle range
    float dtk_us_sum = compute_sum_array_i(dtk_us, dtk_len);

    if (dtk_us_sum > ts_us_ref[ts_us_len-1]) {
        for (int i = 0; i < dtk_len; i++) {
            dtk_us[i] = dtk_us[i] / dtk_us_sum * ts_us_ref[ts_us_len - 1];
        }
    }

    // adjust ts_us with dtk_us
    std::vector<float> ts_us = ts_us_ref;
    for (size_t i = 0; i < dtk_len; i++) {
        ts_us[i+1] = ts_us[i+1] + dtk_us[i];
    }

    // impose time constraint for `ts_us`
    for (size_t i = 0; i < ts_us_len-2; i++) {
        if (ts_us[i+1] - ts_us[i] < time_constraint_us) {
            ts_us[i+1] = ts_us[i] + time_constraint_us;
        }
    }
    
    // adjust final time
    float ts_us_end = ts_us[ts_us_len - 1];
    if (ts_us[ts_us_len-2] > ts_us_end) {
        for (size_t i = 0; i < ts_us_len-1; i++) {
            ts_us[i] = ts_us[i]/ts_us[ts_us_len-2]*(ts_us_end - time_constraint_us*dtk_len);
        }
    }

    // impose time constraint for `ts_us`
    for (size_t i = 0; i < ts_us_len-1; i++) {
        if (ts_us[i+1] - ts_us[i] < time_constraint_us) {
            ts_us[i+1] = ts_us[i] + time_constraint_us;
        }
    }

    for (size_t i = 0; i < dtk_len; i++) {
        dtk_us[i] = ts_us[i+1] - ts_us_ref[i+1];
    }
}