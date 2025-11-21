#pragma once

#include <stdint.h>
#include "esp_err.h"

/**
 * @brief Initialize the GPIOs and populate the test signal pattern.
 */
void signal_controller_init();

/**
 * @brief Starts generating the signal continuously in a loop.
 * Runs in a separate FreeRTOS task.
 * Pattern: 50 cycles of (10us HIGH, 20us LOW) per burst.
 */
void signal_start_continuous();

/**
 * @brief Stops the continuous signal generation and forces pins LOW.
 */
void signal_stop();

/**
 * @brief (Internal) Executes the signal sequence with interrupts disabled.
 */
void signal_execute_sequence(const uint16_t* durations, const uint8_t* modes, int count);