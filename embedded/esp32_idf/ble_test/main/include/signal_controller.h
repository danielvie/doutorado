#pragma once

#include <stdint.h>
#include "esp_err.h"

#define MAX_SIGNAL_SIZE 100
struct DataSet {
    uint16_t DEMO_DURATIONS[MAX_SIGNAL_SIZE];
    uint8_t  DEMO_MODES[MAX_SIGNAL_SIZE];
    uint8_t  DEMO_SIZE;
};

/**
 * @brief Initialize the GPIOs and populate the custom signal pattern.
 */
void signal_controller_init();

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
 * @brief (Internal) Executes the signal sequence with interrupts disabled.
 * @param durations Array of durations in microseconds
 * @param modes Array of mode bitmasks (0-7)
 * @param segment_count Number of segments in the pattern
 * @param repeats Number of times to repeat the full pattern in this burst
 */
void signal_execute_sequence(const uint16_t* durations, const uint8_t* modes, int segment_count, int repeats);