/**
 * Helper Functions Implementation for ESP32 Signal Controller
 * 
 * This file implements utility functions for signal processing,
 * data parsing, and analog sensor interfacing.
 */

#include <math.h>
#include "helpers.h"

/**
 * Convert a numeric value to binary representation structure
 * 
 * Extracts individual bits from a number and maps them to boolean flags.
 * Used to convert combined mode values into individual pin states.
 * 
 * @param num Input number to decompose into bits
 * @return Bin structure with individual bit flags set
 * 
 * Note: There's a bug in bit 5 calculation (0x16 should be 0x10)
 */
struct Bin Num2Bin(uint64_t num) {
    auto b = Bin();
    b.b1 = num & 0x1;
    b.b2 = num & 0x2;
    b.b3 = num & 0x4;
    b.b4 = num & 0x8;
    b.b5 = num & 0x16;
    b.b6 = num & 0x32;

    return b;
}

/**
 * Parse a comma-separated section of a signal string
 * 
 * Takes a string containing comma-separated numeric values and converts
 * them to a vector of integers. Used internally by parseSignal().
 * 
 * @param section String containing values like "50,100,75,200"
 * @param result Vector to store the parsed numeric values
 * 
 * Example: "50,100,75" -> {50, 100, 75}
 */
void _parseSection(const std::string &section, std::vector<uint64_t> &result) {
    std::stringstream ss(section);
    std::string item;
    
    // Split by comma and convert each item to integer
    while (std::getline(ss, item, ',')) {
        result.push_back(std::stoi(item));
    }
}


/**
 * Parse a complete signal string containing timing and mode data
 * 
 * Parses a signal definition string with the format:
 * "time1,time2,time3;mode1,mode2,mode3"
 * 
 * The semicolon separates timing values from mode values.
 * Both sections are comma-separated lists of integers.
 * 
 * @param s Input signal string to parse
 * @param time Vector to store parsed timing values (in timer ticks)
 * @param mode Vector to store parsed mode values (binary combinations)
 * @return 1 on successful parsing, 0 on failure
 * 
 * Example input: "50,100,75;7,0,3" 
 * Results in: time={50,100,75}, mode={7,0,3}
 * 
 * Throws std::runtime_error if semicolon delimiter is not found.
 */
int parseSignal(const std::string &s, std::vector<uint64_t> &time, std::vector<uint64_t> &mode) {
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
    _parseSection(timeSection, time);
    _parseSection(modeSection, mode);
    
    return 1;  // Success
}

/**
 * Read analog voltage from specified port with calibration
 * 
 * Maps logical analog port numbers to physical ESP32 ADC channels,
 * reads the raw ADC value, converts to voltage, and applies calibration.
 * 
 * ADC Channel Mapping:
 * - AN1 -> ADC1_CHANNEL_3 (GPIO39)
 * - AN2 -> ADC1_CHANNEL_5 (GPIO33) 
 * - AN3 -> ADC1_CHANNEL_4 (GPIO32)
 * - AN4 -> ADC1_CHANNEL_7 (GPIO35)
 * - AN5 -> ADC1_CHANNEL_6 (GPIO34)
 * - AN6 -> ADC1_CHANNEL_0 (GPIO36)
 * 
 * @param port Analog port identifier (AN1-AN6)
 * @return Calibrated voltage reading in volts, or -9.9V for invalid ports
 * 
 * Process:
 * 1. Read raw 12-bit ADC value (0-4095)
 * 2. Convert to voltage (0-3.3V)
 * 3. Apply calibration correction
 */
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
    voltage = esp32calibration(voltage);
    
    return voltage;
}



// calibration function
/**
 * Apply calibration transformation to ESP32 voltage reading
 * 
 * Converts raw ESP32 ADC voltage measurements to calibrated values
 * using a linear transformation. The coefficients beta[] were determined
 * through calibration against a reference multimeter.
 * 
 * Formula: calibrated_voltage = (raw_voltage - offset) / scale
 * 
 * @param x Raw voltage reading from ESP32 ADC
 * @return Calibrated voltage value in volts
 */

double calib_from[] = {0.00, 0.07, 0.17, 0.26, 0.36, 0.46, 0.56, 0.66, 0.76, 0.86, 0.96, 1.06, 1.16, 1.27, 1.37, 1.46, 1.56, 1.67, 1.76, 1.86, 1.96, 2.06, 2.16, 2.27, 2.37, 2.49, 2.61, 2.75, 2.90, 3.07, 3.26, 3.30, 3.30};
double calib_to[]   = {0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00, 1.10, 1.20, 1.30, 1.40, 1.50, 1.60, 1.70, 1.80, 1.90, 2.00, 2.10, 2.20, 2.30, 2.40, 2.50, 2.60, 2.70, 2.80, 2.90, 3.00, 3.10, 3.20, 3.30};
int    calib_numel  = sizeof(calib_from) / sizeof(calib_from[0]);

float esp32calibration(float value) {
    
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