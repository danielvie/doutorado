#pragma once

#include <Arduino.h>

namespace helper {
    void print(const char *format, ...);
    void println(const char *format, ...);
    void printf(const char *format, ...);
}