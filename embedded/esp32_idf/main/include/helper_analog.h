
#pragma once

#include "esp_log.h"
#include "esp_adc/adc_oneshot.h"

// ADC Configuration Constants
#define ADC_MAX 4095.0      // 12-bit ADC maximum value (2^12 - 1)
#define VOLTAGE_MAX 3.3     // Maximum voltage reference (3.3V)

enum class AnalogPort {
    AN1 = 1,    // ADC1_CHANNEL_3 (GPIO 39)
    AN2 = 2,    // ADC1_CHANNEL_5 (GPIO 33)
    AN3 = 3,    // ADC1_CHANNEL_4 (GPIO 32)
    AN4 = 4,    // ADC1_CHANNEL_7 (GPIO 35)
    AN5 = 5,    // ADC1_CHANNEL_6 (GPIO 34)
    AN6 = 6     // ADC1_CHANNEL_0 (GPIO 36)
};

void analog_init();
float analog_read_port(AnalogPort port);