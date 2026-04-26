// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

/**
 * Helper Functions Implementation for ESP32 Signal Controller
 *
 * This file implements utility functions for signal processing,
 * data parsing, and analog sensor interfacing.
 */

#include "helper_common.h"

// .. globals
volatile uint32_t g_analog_monitor_period_ms = 500;

// .. semaphore
SemaphoreHandle_t sem_analog_read_trigger;

LogDuration g_log_duration = {
    .read_and_send_analog_us = -42,
    .matrix_multiply_us = -42,
    .dtk_condition = -42,
    .update_signal_with_dtk = -42,
};

volatile SystemState g_system_state = {
    .signal_state = ATOMIC_VAR_INIT(SignalState::IDLE),
    .ble_an_read_state = ATOMIC_VAR_INIT(BLEAnalogReadState::IDLE),
    .control_state = ATOMIC_VAR_INIT(ControlState::OFF),
    .led_mode = ATOMIC_VAR_INIT(LedMode::NORMAL),
};

// .. control globals
std::atomic<uint16_t> g_blink_delay1_ms = 200;
std::atomic<uint16_t> g_blink_delay2_ms = 500;
std::atomic<bool> g_control_enabled = false;
std::atomic<float> g_adc_an3 = 0.0f;
std::atomic<float> g_adc_an5 = 0.0f;
std::atomic<float> g_adc_an6 = 0.0f;
std::atomic<bool> g_adc_fresh = false;

bool led_get_desired_state() {
    return (g_system_state.signal_state.load(std::memory_order_acquire) == SignalState::RUNNING);
}

struct Bin num2bin(uint32_t num) {
    auto b = Bin();
    b.b1 = num & 0x1;
    b.b2 = num & 0x2;
    b.b3 = num & 0x4;
    b.b4 = num & 0x8;
    b.b5 = num & 0x10;
    b.b6 = num & 0x20;

    return b;
}


void parse_section(const std::string &section, std::vector<uint32_t> &result) {
    std::stringstream ss(section);
    std::string item;

    // Split by comma and convert each item to integer
    while (std::getline(ss, item, ',')) {
        result.push_back(std::stoi(item));
    }
}

int parse_signal(const std::string &s, std::vector<uint32_t> &time,
                 std::vector<uint32_t> &mode) {
    // Clear any existing values to start fresh
    time.clear();
    mode.clear();

    // Find the semicolon separator between timing and mode sections
    size_t semicolonPos = s.find(';');
    if (semicolonPos == std::string::npos) {
        return 0;
    }

    // Extract timing section (before semicolon) and mode section (after
    // semicolon)
    std::string timeSection = s.substr(0, semicolonPos);
    std::string modeSection = s.substr(semicolonPos + 1);

    // Parse each section into respective vectors
    parse_section(timeSection, time);
    parse_section(modeSection, mode);

    return 1; // Success
}

std::string get_label(SignalSet set) {
    switch (set) {
    case SignalSet::SET_A:
        return "SET_A";
    case SignalSet::SET_B:
        return "SET_B";
    default:
        return "-ERROR";
    }
}

std::string get_label(SignalState state) {
    switch (state) {
    case SignalState::IDLE:
        return "IDLE";
    case SignalState::RUNNING:
        return "RUNNING";
    default:
        return "-ERROR";
    }
}

std::string get_label(BLEAnalogReadState state) {
    switch (state) {
    case BLEAnalogReadState::DISABLED:
        return "DISABLED";
    case BLEAnalogReadState::IDLE:
        return "IDLE";
    case BLEAnalogReadState::READING:
        return "READING";
    default:
        return "-ERROR";
    }
}

std::string get_label(ControlState state) {
    switch (state) {
    case ControlState::OFF:
        return "OFF";
    case ControlState::ON:
        return "ON";
    default:
        return "-ERROR";
    }
}
