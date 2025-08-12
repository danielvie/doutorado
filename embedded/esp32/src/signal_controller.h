#ifndef SIGNAL_CONTROLLER_H
#define SIGNAL_CONTROLLER_H

#include <Arduino.h>
#include "driver/timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "helpers.h"

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
extern SignalTaskState signal_task_state;
extern SemaphoreHandle_t signal_mutex;
extern uint32_t cycle_nrun;

// Timer and signal control variables (volatile for ISR access)
extern volatile uint8_t current_state;
extern volatile uint32_t cycle_count;
extern volatile bool timer_initialized;
extern volatile uint8_t num_timings;
extern volatile uint8_t active_num_timings;
extern volatile ActiveSignalSet active_set;
extern volatile bool switch_set_pending;

// Signal vectors

struct MatrixData {
    std::vector<float> values;
    int rows, cols;
    bool is_valid;
};

struct DataSet {
    std::vector<uint32_t> time_vec;
    std::vector<uint32_t> d4_vec;
    std::vector<uint32_t> d5_vec;
    std::vector<uint32_t> d6_vec; 
    std::vector<int32_t> time_us_diff;
    std::vector<float> target; 
    MatrixData gain_k;
};

extern DataSet dataset_a; // Signal set A
extern DataSet dataset_b; // Signal set B

void set_dataset_a();
void set_dataset_b();
void toggle_dataset();

void set_control_on();
void set_control_off();

// extern std::vector<uint32_t> time_vec_a, d4_vec_a, d5_vec_a, d6_vec_a;
// extern std::vector<uint32_t> time_vec_b, d4_vec_b, d5_vec_b, d6_vec_b;

// Function declarations
void initialize_signal_controller();
void signal_task(void* arg);
void start_signal_timer();
void stop_signal_timer();
void set_all_outputs_high();
void set_all_outputs_low();
void update_signal_pattern(const std::string& signal);
ERROR_CODE update_signal_control(const std::string& str_control_message);

DataSet* get_dataset_active();
std::string get_dataset_active_name();
int get_signal_set_size(ActiveSignalSet set);

// Timer ISR callback
bool IRAM_ATTR timer_group_isr_callback(void *args);

#endif // SIGNAL_CONTROLLER_H
