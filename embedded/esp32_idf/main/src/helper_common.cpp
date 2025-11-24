// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

/**
 * Helper Functions Implementation for ESP32 Signal Controller
 *
 * This file implements utility functions for signal processing,
 * data parsing, and analog sensor interfacing.
 */

#include "helper_common.h"

void blink(uint8_t N) {
    for (uint8_t i = 0; i < N; i++) {
        led_on();
        vTaskDelay(pdMS_TO_TICKS(100));
        led_off();
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

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


void parse_section(const std::string &section, std::vector<uint32_t> &result) {
    std::stringstream ss(section);
    std::string item;

    // Split by comma and convert each item to integer
    while (std::getline(ss, item, ',')) {
        result.push_back(std::stoi(item));
    }
}


int parse_signal(const std::string &s, std::vector<uint32_t> &time, std::vector<uint32_t> &mode) {
    // Clear any existing values to start fresh
    time.clear();
    mode.clear();

    // Find the semicolon separator between timing and mode sections
    size_t semicolonPos = s.find(';');
    if (semicolonPos == std::string::npos) {
        return 0;
    }

    // Extract timing section (before semicolon) and mode section (after semicolon)
    std::string timeSection = s.substr(0, semicolonPos);
    std::string modeSection = s.substr(semicolonPos + 1);

    // Parse each section into respective vectors
    parse_section(timeSection, time);
    parse_section(modeSection, mode);

    return 1; // Success
}

std::string get_signal_set_label(SignalSet set) {
    switch (set) {
    case SignalSet::SET_A:
        return "SET_A";
    case SignalSet::SET_B:
        return "SET_B";
    default:
        return "-ERROR";
    }
}