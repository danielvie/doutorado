#pragma once

#include <sstream>
#include <vector>
#include <driver/adc.h>

#define ADC_MAX 4095.0 // 12-bit ADC (2^12 - 1)
#define VOLTAGE_MAX 3.3

struct Bin {
    bool b1;
    bool b2;
    bool b3;
    bool b4;
    bool b5;
    bool b6;
};

namespace SignalWriteState {
    enum State {
        IDLE,
        RUN_SIGNAL,
        RUN_HIGH,
    };
}

namespace SignalReadState {
    enum State {
        IDLE,
        READ,
        READING,
        CHANGED,
    };
}

namespace AnalogReadState {
    enum State {
        IDLE,
        READ,
    };
}

struct Bin Num2Bin(uint64_t n);

void _parseSection(const std::string &section, std::vector<uint64_t> &result);
int parseSignal(const std::string &s, std::vector<uint64_t> &time, std::vector<uint64_t> &mode);

enum class AnalogPort {
    AN1 = 1,
    AN2 = 2,
    AN3 = 3,
    AN4 = 4,
    AN5 = 5,
    AN6 = 6
};

float esp2multi(float x);

float read_analog(AnalogPort port);