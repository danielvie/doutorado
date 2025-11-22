// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

#pragma once

#include <iostream>
#include <sstream>
#include <vector>
#include <numeric>
#include <chrono>
#include <random>
#include <memory>


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

struct Bin num2bin(uint32_t num);
void parse_section(const std::string &section, std::vector<uint32_t> &result);
int parse_signal(const std::string &s, std::vector<uint32_t> &time, std::vector<uint32_t> &mode);