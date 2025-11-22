#pragma once

#include "helper_common.h"
#include "led.h"

#include "driver/gpio.h"
#include "esp_err.h"
#include "esp_log.h"
#include "esp_rom_sys.h"
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "soc/gpio_struct.h"
#include <string>
#include <vector>


#define MAX_SIGNAL_SIZE 100
struct DataSet {
    uint16_t time_durations[MAX_SIGNAL_SIZE];
    uint8_t  modes[MAX_SIGNAL_SIZE];
    uint8_t  size;
};

enum class SignalSet { 
    SET_A,      // Signal set A is active
    SET_B       // Signal set B is active
};

/**
 * @brief Initialize the GPIOs and populate the custom signal pattern.
 */
void signal_controller_init();

/**
 * @brief Updates the inactive signal buffer with new data.
 * Parses the string, populates the buffer, and sets a flag to swap.
 * Safe to call from BLE/Core0.
 * @param message The raw message string (e.g., "SIGNAL:...")
 */
void signal_update_from_string(const std::string& message);

/**
 * @brief Starts generating the signal continuously in a loop.
 * Runs in a separate FreeRTOS task on Core 1.
 */
void signal_start_continuous();

/**
 * @brief Stops the continuous signal generation and forces pins LOW.
 */
void signal_stop();

/**
 * @brief (Internal) Placeholder
 */
void signal_execute_sequence(const uint16_t* durations, const uint8_t* modes, int segment_count, int repeats);