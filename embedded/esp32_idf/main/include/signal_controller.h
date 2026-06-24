#pragma once

#include "helper_common.h"
#include "helper_led.h"
#include "helper_matrix.h"

#include "driver/gpio.h"
#include "esp_attr.h"
#include "esp_err.h"
#include "esp_log.h"
#include "esp_rom_sys.h"
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "soc/gpio_struct.h"
#include <string>
#include <vector>
#include <cmath>

extern const uint32_t MASK_U1_LOW;
extern const uint32_t MASK_U1_HIGH;
extern const uint32_t MASK_U2_LOW;
extern const uint32_t MASK_U2_HIGH;
extern const uint32_t MASK_U3_LOW;
extern const uint32_t MASK_U3_HIGH;

#define MAX_SIGNAL_SIZE 100
static constexpr uint32_t SIGNAL_TIME_TICKS_PER_US = 10;
static constexpr uint32_t SIGNAL_CYCLES_PER_TIME_TICK = 24;

/**
 * @brief Represents a single atomic transition and delay in a signal pattern.
 * Pre-computed to minimize cycles in the high-speed execution loop.
 */
struct SignalStep {
    uint32_t set_mask;    ///< Bits to set to 1 (GPIO.out_w1ts)
    uint32_t clr_mask;    ///< Bits to set to 0 (GPIO.out_w1tc)
    uint32_t clear_mask;  ///< Initial clear mask (to prevent shoot-through)
    uint32_t dead_time;   ///< CPU cycles to wait during clear state
    uint32_t duration_ticks; ///< 0.1 us ticks to wait after transition
    uint32_t duration_cycles; ///< Derived delay cycles for the hot playback loop
};

struct DataSet {
    // Raw data (kept for reference/updates), stored as 0.1 us ticks.
    uint32_t time_durations[MAX_SIGNAL_SIZE];
    uint32_t modes_d4[MAX_SIGNAL_SIZE];
    uint32_t modes_d5[MAX_SIGNAL_SIZE];
    uint32_t modes_d6[MAX_SIGNAL_SIZE];
    uint32_t size;

    // Pre-computed steps for Core 1 loop
    SignalStep steps[MAX_SIGNAL_SIZE];

    int32_t time_us_diff[MAX_SIGNAL_SIZE];
    float target[3];
    MatrixData gain_k;
    float alpha;
};

struct SignalTimingCompact {
    uint32_t samples;
    float playback_avg_us;
    float loop_us;
    uint32_t overruns;
    uint32_t timing_faults;
};

extern DataSet g_dataset_a;
extern DataSet g_dataset_b;

extern volatile uint32_t g_cycle_count;
extern volatile uint32_t g_cycle_nrun;

extern std::atomic<SignalSet> g_active_set;
extern std::atomic<bool> g_ds_update_pending;
extern volatile uint32_t g_dead_time_cycles_up;
extern volatile uint32_t g_dead_time_cycles_down;
extern volatile uint32_t g_signal_edge_overhead_cycles;

/**
 * @brief Initialize the GPIOs and populate the custom signal pattern.
 */
void signal_controller_init();

/**
 * @brief Updates the inactive signal buffer with a pattern payload.
 * Parses the "time;mode" string, populates the buffer, and sets a flag to swap.
 * Safe to call from BLE/Core0.
 * @param message The pattern payload string.
 */
void signal_update_from_string(const std::string &message);

/**
 * @brief Pre-computes optimized SignalSteps for a given DataSet.
 */
void signal_precompute_steps(DataSet *ds);

/**
 * @brief Returns a compact JSON snapshot of the latest signal-loop timing.
 */
std::string signal_get_timing_snapshot_json();
std::string signal_get_timing_compact_fields_json();
void signal_get_timing_compact(SignalTimingCompact* timing);

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
 * @brief Stops the continuous signal generation and forces pins LOW.
 */
void signal_set_alpha(float alpha);

DataSet *get_dataset_active(void);

/**
 * @brief (Internal) Placeholder
 */
void signal_execute_sequence(const uint16_t *durations, const uint8_t *modes,
                             int segment_count, int repeats);
