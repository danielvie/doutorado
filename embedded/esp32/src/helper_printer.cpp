// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

#include "helper_printer.h"
#include <stdarg.h>

namespace helper {
    volatile boolean g_printer_on = true;

    void print(const char *format, ...) {

        if (g_printer_on == false) {
            return;
        }

        va_list args;
        va_start(args, format);

        // Create a buffer for the formatted string
        char buffer[512]; // Adjust size as needed
        vsnprintf(buffer, sizeof(buffer), format, args);

        // Print the formatted string
        Serial.print(buffer);

        va_end(args);
    }

    void println(const char *format, ...) {

        if (g_printer_on == false) {
            return;
        }

        va_list args;
        va_start(args, format);

        // Create a buffer for the formatted string
        char buffer[512]; // Adjust size as needed
        vsnprintf(buffer, sizeof(buffer), format, args);

        // Print the formatted string with newline
        Serial.println(buffer);

        va_end(args);
    }

    void printf(const char *format, ...) {

        if (g_printer_on == false) {
            return;
        }

        // Safety check for null format string
        if (format == nullptr) {
            Serial.print("[printf: null format]");
            return;
        }

        va_list args;
        va_start(args, format);

        // Create a buffer for the formatted string
        char buffer[512]; // Adjust size as needed
        int result = vsnprintf(buffer, sizeof(buffer), format, args);

        // Check for formatting errors
        if (result < 0) {
            Serial.print("[printf: format error]");
        }
        else if (result >= sizeof(buffer)) {
            Serial.print("[printf: truncated]");
            Serial.print(buffer);
        }
        else {
            // Print the formatted string
            Serial.print(buffer);
        }

        va_end(args);
    }

}