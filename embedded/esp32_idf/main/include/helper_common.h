// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

#pragma once

#include <iostream>
#include <sstream>
#include <vector>
#include <numeric>
#include <chrono>
#include <random>
#include <memory>

#include "helper_led.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"

#define CORE_0 0
#define CORE_1 1


#define PIN_OUT_6   GPIO_NUM_23 // Bit 2 (4)
#define PIN_OUT_6_  GPIO_NUM_22 // 
#define PIN_OUT_5   GPIO_NUM_21 // Bit 1 (2)
#define PIN_OUT_5_  GPIO_NUM_19 // 
#define PIN_OUT_4   GPIO_NUM_18 // Bit 0 (1)
#define PIN_OUT_4_  GPIO_NUM_17 // 


// .. globals
extern volatile uint32_t g_analog_monitor_period_ms;


// .. defining semaphore for reading data
extern SemaphoreHandle_t sem_analog_read_trigger;

// .. data structures
struct LogDuration {
    int64_t read_and_send_analog_us;
    int64_t matrix_multiply_us;
    int64_t dtk_condition;
    int64_t update_signal_with_dtk;
};

extern LogDuration g_log_duration;

enum class BLEMode {
    SILENT,
    VERBOSE,
};

enum class Status {
    ON,
    OFF,
};

enum class SignalSet { 
    SET_A,      // Signal set A is active
    SET_B       // Signal set B is active
};

enum class BLEAnalogReadState {
    IDLE,
    READING,
    DISABLED,
};

enum class SignalState {
    IDLE,
    RUNNING,
};

struct SystemState {
    SignalState signal_state;
    BLEAnalogReadState ble_an_read_state;
};

extern volatile SystemState g_system_state;



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

void blink(uint8_t N);
struct Bin num2bin(uint32_t num);
void parse_section(const std::string &section, std::vector<uint32_t> &result);
int parse_signal(const std::string &s, std::vector<uint32_t> &time, std::vector<uint32_t> &mode);

std::string get_label(SignalSet set);
std::string get_label(BLEAnalogReadState state);
std::string get_label(SignalState state);

static inline void __attribute__((always_inline)) helper_delay_cycles(uint32_t cycles) {
    uint32_t start = esp_cpu_get_cycle_count();
    while (esp_cpu_get_cycle_count() - start < cycles) { }
}