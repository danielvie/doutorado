// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

/**
 * ESP32 Signal Controller with BLE Interface
 *
 * This firmware controls digital output signals on GPIO pins DI4, DI5, and DI6
 * based on timing and mode patterns received via Bluetooth Low Energy (BLE).
 * The system uses a hardware timer for precise signal timing and dual-core
 * processing for BLE communication and signal generation.
 */

#include <Arduino.h>
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/adc.h"

#include "ble_controller.h"
#include "analog_controller.h"
#include "signal_controller.h"

// CPU Core definitions for task assignment
#define CORE_0 0
#define CORE_1 1

// GPIO Pin definitions
#define LED 2 // Built-in LED for status indication

/**
 * System Setup Function
 * Initializes all hardware and software components:
 * - Serial communication
 * - Signal controller
 * - ADC configuration
 * - GPIO configuration
 * - Watchdog timer
 * - FreeRTOS tasks
 */
void setup()
{
    Serial.begin(115200);

    // initializing g_gain_k
    // g_control_gain_k.m_is_valid = false;
    // g_control_gain_k.m_data.reserve(50);

    // Initialize signal controller (creates mutex, initializes vectors, configures GPIO)
    initialize_signal_controller();

    // Configure ADC channels for analog input reading
    adc1_config_width(ADC_WIDTH_BIT_12);                        // 12-bit resolution (0-4095)
    adc1_config_channel_atten(ADC1_CHANNEL_0, ADC_ATTEN_DB_12); // 0-3.3V range
    adc1_config_channel_atten(ADC1_CHANNEL_3, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_4, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_5, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_6, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_7, ADC_ATTEN_DB_12);

    // Configure LED GPIO pin
    pinMode(LED, OUTPUT);
    digitalWrite(LED, LOW);

    // Initialize watchdog timer (30 second timeout)
    esp_task_wdt_init(30, true);
    esp_task_wdt_add(NULL);

    // Create BLE task on Core 0 with higher stack size and higher priority for BLE operations and memory safety
    xTaskCreatePinnedToCore(
        bleTask,              // Task function
        "BLE Task",           // Task name
        10240,                // Stack size (bytes)
        NULL,                 // Task parameter
        tskIDLE_PRIORITY + 1, // Priority
        NULL,                 // Task handle
        CORE_0                // CPU core
    );

    // Create analog task on Core 0 with sufficient stack size for helper::printf
    xTaskCreatePinnedToCore(
        analogTask,           // Task function
        "Analog Task",        // Task name (corrected name)
        4096,                 // Stack size (bytes) - increased for helper::printf
        NULL,                 // Task parameter
        tskIDLE_PRIORITY + 1, // Priority
        NULL,                 // Task handle
        CORE_0                // CPU core
    );

    // Create signal task on Core 1 with high priority for precise timing
    xTaskCreatePinnedToCore(
        signal_task,              // Task function
        "Signal Task",            // Task name
        4096,                     // Stack size (bytes)
        NULL,                     // Task parameter
        configMAX_PRIORITIES - 1, // High priority (second highest)
        NULL,                     // Task handle
        CORE_1                    // CPU core
    );
}

/**
 * Main Loop Function
 * Runs on Core 0 and serves as a simple watchdog reset loop
 * The actual work is done by the tasks created in setup()
 */
void loop()
{
    esp_task_wdt_reset();            // Reset watchdog timer
    vTaskDelay(pdMS_TO_TICKS(1000)); // 1 second delay
}
