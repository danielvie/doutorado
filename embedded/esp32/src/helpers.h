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

enum class ActiveSignalSet { SET_A, SET_B };
enum class SignalTaskState { IDLE, HIGH_RUN, SIGNAL_RUN };
enum class BLETaskState { IDLE, ANALOG_READ, ANALOG_READING, SIGNAL_READING };
enum class AnalogPort { AN1 = 1, AN2 = 2, AN3 = 3, AN4 = 4, AN5 = 5, AN6 = 6 };

struct Bin Num2Bin(uint64_t n);

void _parseSection(const std::string &section, std::vector<uint64_t> &result);
int parseSignal(const std::string &s, std::vector<uint64_t> &time, std::vector<uint64_t> &mode);


float esp2multi(float x);

float read_analog(AnalogPort port);