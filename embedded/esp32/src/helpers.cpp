#include "helpers.h"

struct Bin Num2Bin(uint64_t num) {
    auto b  = Bin();
    b.b1 = num & 0x1;
    b.b2 = num & 0x2;
    b.b3 = num & 0x4;
    b.b4 = num & 0x8;
    b.b5 = num & 0x16;
    b.b6 = num & 0x32;

    return b;
};

void _parseSection(const std::string &section, std::vector<uint64_t> &result) {
    std::stringstream ss(section);
    std::string item;
    
    while (std::getline(ss, item, ',')) {
        result.push_back(std::stoi(item));
    }
}


float esp2multi(float x) {
    float beta[] = {-0.1545, 0.99686667};
    return (x-beta[0])/beta[1];
}

int parseSignal(const std::string &s, std::vector<uint64_t> &time, std::vector<uint64_t> &mode) {
    // clearing values
    time.clear();
    mode.clear();
    
    // parsing new values
    size_t semicolonPos = s.find(';');
    if (semicolonPos == std::string::npos) {
        throw std::runtime_error("No semicolon found");
        return 0;
    }
    
    // extract the parts
    std::string timeSection = s.substr(0, semicolonPos);
    std::string modeSection = s.substr(semicolonPos + 1);
    
    // parse each part
    _parseSection(timeSection, time);
    _parseSection(modeSection, mode);
    return 1;
}

float read_analog(AnalogPort port) {
    int rawValue = 0;
    
    switch (port) {
        case AnalogPort::AN1:
            rawValue = adc1_get_raw(ADC1_CHANNEL_3);
            break;
        case AnalogPort::AN2:
            rawValue = adc1_get_raw(ADC1_CHANNEL_5);
            break;
        case AnalogPort::AN3:
            rawValue = adc1_get_raw(ADC1_CHANNEL_4);
            break;
        case AnalogPort::AN4:
            rawValue = adc1_get_raw(ADC1_CHANNEL_7);
            break;
        case AnalogPort::AN5:
            rawValue = adc1_get_raw(ADC1_CHANNEL_6);
            break;
        case AnalogPort::AN6:
            rawValue = adc1_get_raw(ADC1_CHANNEL_0);
            break;
        default:
            return -9.9f; // Return -9.9V for invalid ports
    }
    
    float voltage = ((float)rawValue / ADC_MAX) * VOLTAGE_MAX;
    
    float voltageCompensated = esp2multi(voltage);
    
    return voltageCompensated;
}