// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

#pragma once

#include <Arduino.h>

namespace helper {

    extern volatile boolean g_printer_on;

    void print(const char *format, ...);
    void println(const char *format, ...);
    void printf(const char *format, ...);
}