// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

#ifndef SIGNAL_CONTROLLER_H
#define SIGNAL_CONTROLLER_H

#include "driver/timer.h"
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <Arduino.h>

#include "helper_common.h"
#include "ble_controller.h"
#include "helper_matrix.h"

// Timer configuration for precise signal timing
#define CPU_FREQ_MHZ 240         // ESP32 CPU frequency
#define TIMER_DIVIDER 80         // Timer prescaler (240MHz / 80 = 3MHz timer clock)
#define TIMER_GROUP TIMER_GROUP_0
#define TIMER_IDX TIMER_0

// Digital output pins for signal generation
#define GPIO_DI4 21              // Primary digital output pin 4
#define GPIO_DI5 22              // Primary digital output pin 5
#define GPIO_DI6 23              // Primary digital output pin 6

// Maximum number of timing elements in a signal pattern
#define MAX_ELEMENTS_SIGNAL 30

// External variables that need to be accessible from other modules
extern SignalTaskState g_signal_task_state;
extern SemaphoreHandle_t g_signal_mutex;
extern uint32_t g_cycle_nrun;

// Timer and signal control variables (volatile for ISR access)
extern volatile uint8_t g_current_state;
extern volatile uint16_t g_cycle_count;
extern volatile bool g_timer_initialized;
extern volatile uint8_t g_num_timings;
extern volatile uint8_t g_active_num_timings;
extern volatile SignalSet g_active_set;
extern volatile bool g_switch_set_pending;

// Signal vectors
struct DataSet {
    uint32_t time_vec[MAX_ELEMENTS_SIGNAL];
    uint32_t d4_vec[MAX_ELEMENTS_SIGNAL];
    uint32_t d5_vec[MAX_ELEMENTS_SIGNAL];
    uint32_t d6_vec[MAX_ELEMENTS_SIGNAL]; 
    uint16_t size_vec;
    int32_t time_us_diff[MAX_ELEMENTS_SIGNAL];
    float target[3]; 
    MatrixData gain_k;
};

extern DataSet g_dataset_a; // Signal set A
extern DataSet g_dataset_b; // Signal set B

void ble_router_set_signal_dataset_a();
void ble_router_set_signal_dataset_b();
void ble_router_toggle_signal_dataset();

void ble_router_set_ble_message_on();
void ble_router_set_ble_message_off();

void ble_router_set_signal_control_on();
void ble_router_set_signal_control_off();

void ble_router_set_print_on();
void ble_router_set_print_off();

// Function declarations
void initialize_signal_controller();
void signal_task(void* arg);
void start_signal_timer();
void stop_signal_timer();
void set_all_outputs_high();
void set_all_outputs_low();
void signal_update_pattern(const std::string& signal);
ERROR_CODE signal_update_full_control(const std::string& str_control_message);

DataSet* get_dataset_active();
DataSet* get_dataset_not_active();
std::string get_dataset_active_name();
int get_signal_set_size(SignalSet set);

// Timer ISR callback
bool IRAM_ATTR timer_group_isr_callback(void *args);

#endif // SIGNAL_CONTROLLER_H
