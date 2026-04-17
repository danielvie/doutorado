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
#include "esp_cpu.h"

#define CORE_0 0
#define CORE_1 1


#define PIN_U1_LOW   GPIO_NUM_23 // Bit 2 (4)
#define PIN_U1_HIGH  GPIO_NUM_22 //

#define PIN_U2_LOW   GPIO_NUM_21 // Bit 1 (2)
#define PIN_U2_HIGH  GPIO_NUM_19 //
#define PIN_U3_LOW   GPIO_NUM_18 // Bit 0 (1)

#define PIN_U3_HIGH  GPIO_NUM_17 //
#define PIN_OUT_SIG  GPIO_NUM_4  //


// .. globals
extern volatile uint32_t g_analog_monitor_period_ms;


// .. defining semaphore for reading data
extern SemaphoreHandle_t sem_analog_read_trigger;

// .. control and adc globals
extern volatile bool g_control_enabled;
extern volatile float g_adc_an3;
extern volatile float g_adc_an5;
extern volatile float g_adc_an6;
extern volatile bool g_adc_fresh;

struct PIDConfig {
    float kp;
    float ki;
    float kd;
    float err_sum;
    float prev_err;
    float target;
};

extern volatile bool g_pid_enabled;
extern volatile PIDConfig g_pid_config;

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

enum class ControlState {
    OFF,
    ON,
    ON_PID,
};

struct SystemState {
    SignalState signal_state;
    BLEAnalogReadState ble_an_read_state;
    ControlState control_state;
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
std::string get_label(ControlState state);

static inline void __attribute__((always_inline)) helper_delay_cycles(uint32_t cycles) {
    uint32_t start = esp_cpu_get_cycle_count();
    while (esp_cpu_get_cycle_count() - start < cycles) { }
}
