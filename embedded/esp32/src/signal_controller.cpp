// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

#include "signal_controller.h"

// Default signal pattern configuration
DataSet g_dataset_a; // Signal set A
DataSet g_dataset_b; // Signal set B

// Task state management
SignalTaskState g_signal_task_state = SignalTaskState::IDLE;

// Timer and signal control variables (volatile for ISR access)
//
volatile SignalSet g_active_set = SignalSet::SET_A;
volatile bool g_switch_set_pending = false;
volatile bool g_timer_initialized = false;

volatile uint16_t g_cycle_count = 0;
volatile uint8_t g_current_state = 0;
volatile uint8_t g_active_num_timings = 0;
volatile uint8_t g_num_timings = 0;

// Cycle configuration
uint32_t g_cycle_nrun = 1;

// Mutex for thread-safe access to shared signal data
SemaphoreHandle_t g_signal_mutex = NULL;

// Pre-calculated GPIO masks for efficient bit manipulation
const uint32_t GPIO_DI4_MASK = 1 << GPIO_DI4;
const uint32_t GPIO_DI5_MASK = 1 << GPIO_DI5;
const uint32_t GPIO_DI6_MASK = 1 << GPIO_DI6;
const uint32_t GPIO_PIN_MASK = GPIO_DI4_MASK | GPIO_DI5_MASK | GPIO_DI6_MASK;

void ble_router_set_signal_dataset_a() {
    // message == "TOGGLE_SET_A"
    //

    helper::println("Changing to SET_A");
    g_active_set = SignalSet::SET_A;
}

void ble_router_set_signal_dataset_b() {
    // message == "TOGGLE_SET_B"
    //

    helper::println("Changing to SET_B");
    g_active_set = SignalSet::SET_B;
}

void ble_router_set_signal_control_on() {
    // message == "CONTROL_ON"
    //

    helper::println("Changing control to ON");
    g_system_status.prop_control = StatusONOFF::ON;
}

void ble_router_set_ble_message_on() {
    // message == "BLE_MESSAGE_ON"
    //

    helper::println("Changing ble messages ON");
    g_system_status.ble_messages = StatusONOFF::ON;
}

void ble_router_set_ble_message_off() {
    // message == "BLE_MESSAGE_OFF"
    //

    helper::println("Changing ble messages OFF");
    g_system_status.ble_messages = StatusONOFF::OFF;
}


void ble_router_set_signal_control_off() {
    // message == "CONTROL_OFF"
    //

    helper::println("Changing control to OFF");
    g_system_status.prop_control = StatusONOFF::OFF;
}

void ble_router_set_print_on() {
    // message == "SET_PRINT_ON"
    //

    helper::g_printer_on = true;
}

void ble_router_set_print_off() {
    // message == "SET_PRINT_OFF"
    //

    helper::g_printer_on = false;
}

void ble_router_toggle_signal_dataset() {
    // message == "TOGGLE_SET"
    //

    if (g_active_set == SignalSet::SET_A) {
        helper::println("Changing to SET_B");
        g_active_set = SignalSet::SET_B;
    }
    else {
        helper::println("Changing to SET_A");
        g_active_set = SignalSet::SET_A;
    }
}

// Timer ISR: toggle signals and schedule next interrupt
// NOTE: signal callback
bool IRAM_ATTR timer_group_isr_callback(void *args) {
    // Re-enable timer alarm for next interrupt
    timer_group_enable_alarm_in_isr(TIMER_GROUP, TIMER_IDX);

    // Only execute signal generation when in SIGNAL_RUN state
    if (g_signal_task_state != SignalTaskState::SIGNAL_RUN) {
        return true;
    }

    // Pre-calculate next state
    uint8_t next_state = (g_current_state + 1) % g_active_num_timings;
    uint32_t new_gpio_out_value = 0;

    // Build pin state mask based on active signal pattern
    DataSet &dataset = (g_active_set == SignalSet::SET_A) ? g_dataset_a : g_dataset_b;

    new_gpio_out_value = (dataset.d4_vec[next_state] ? GPIO_DI4_MASK : 0) |
                         (dataset.d5_vec[next_state] ? GPIO_DI5_MASK : 0) |
                         (dataset.d6_vec[next_state] ? GPIO_DI6_MASK : 0);

    // Atomic GPIO update: Write directly to the GPIO_OUT_REG for simultaneous update
    GPIO.out = (GPIO.out & ~GPIO_PIN_MASK) | new_gpio_out_value;

    // Update state
    g_current_state = next_state;

    // NOTE: 6 -> Set next alarm with control adjustment
    // NOTE: Use g_control_dtk_us
    if (g_system_status.prop_control == StatusONOFF::ON) {
        timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, dataset.time_vec[g_current_state] + dataset.time_us_diff[g_current_state]);
    }
    else {
        timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, dataset.time_vec[g_current_state]);
    }

    // Check for cycle completion and trigger analog reading if needed
    if (g_current_state == 0 && g_system_status.ble_messages == StatusONOFF::ON) {
        g_cycle_count = (g_cycle_count + 1) % g_cycle_nrun;
        if (g_cycle_count == 0) {
            g_ble_task_state = BLETaskState::ANALOG_READ; // NOTE: 4 -> loop call
        }
    }

    return true;
}

// Initialize hardware timer
void initialize_timer() {
    timer_config_t config = {
        .alarm_en = TIMER_ALARM_EN,         // Enable alarm functionality
        .counter_en = TIMER_PAUSE,          // Start in paused state
        .intr_type = TIMER_INTR_LEVEL,      // Level-triggered interrupt
        .counter_dir = TIMER_COUNT_UP,      // Count upward
        .auto_reload = TIMER_AUTORELOAD_EN, // Auto-reload on alarm
        .divider = TIMER_DIVIDER            // Prescaler: 240MHz / 80 = 3MHz
    };

    timer_init(TIMER_GROUP, TIMER_IDX, &config);
    timer_set_counter_value(TIMER_GROUP, TIMER_IDX, 0);
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, g_dataset_a.time_vec[0]);
    timer_enable_intr(TIMER_GROUP, TIMER_IDX);
    timer_isr_callback_add(TIMER_GROUP, TIMER_IDX, timer_group_isr_callback, NULL, 0);
    g_timer_initialized = true;
}

// Start signal timer
void start_signal_timer() {
    if (!g_timer_initialized) {
        initialize_timer();
    }

    // Reset state variables
    g_current_state = 0;
    g_cycle_count = 0;
    timer_set_counter_value(TIMER_GROUP, TIMER_IDX, 0);

    DataSet *dataset = get_dataset_active();

    // Get references to active signal set
    uint32_t *time_vec = dataset->time_vec;
    uint32_t *d4_vec = dataset->d4_vec;
    uint32_t *d5_vec = dataset->d5_vec;
    uint32_t *d6_vec = dataset->d6_vec;

    // Update active signal length
    g_active_num_timings = dataset->size_vec;

    // Set initial pin states for first signal step using atomic GPIO update
    uint32_t initial_pin_states =
        (d4_vec[0] ? GPIO_DI4_MASK : 0) |
        (d5_vec[0] ? GPIO_DI5_MASK : 0) |
        (d6_vec[0] ? GPIO_DI6_MASK : 0);

    // Atomic GPIO update: Write directly to the GPIO_OUT_REG for simultaneous update
    GPIO.out = (GPIO.out & ~GPIO_PIN_MASK) | initial_pin_states;

    // Set first timer alarm and start timer
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, time_vec[0]);
    timer_start(TIMER_GROUP, TIMER_IDX);
}

// Stop signal timer
void stop_signal_timer() {
    if (g_timer_initialized) {
        timer_pause(TIMER_GROUP, TIMER_IDX);
    }
}

// Set outputs high
void set_all_outputs_high() {
    GPIO.out_w1ts = GPIO_DI4_MASK | GPIO_DI5_MASK | GPIO_DI6_MASK;
}

// Set outputs low
void set_all_outputs_low() {
    GPIO.out_w1tc = GPIO_DI4_MASK | GPIO_DI5_MASK | GPIO_DI6_MASK;
}

DataSet *get_dataset_active() {
    DataSet *dataset = (g_active_set == SignalSet::SET_A) ? &g_dataset_a : &g_dataset_b;
    return dataset;
}

DataSet *get_dataset_not_active() {
    DataSet *dataset = (g_active_set == SignalSet::SET_A) ? &g_dataset_b : &g_dataset_a;
    return dataset;
}

std::string get_dataset_active_name() {
    if (g_active_set == SignalSet::SET_A) {
        return "SET_A";
    }
    return "SET_B";
}

// Return number of elements in a signal set
int get_signal_set_size(SignalSet set) {
    if (set == SignalSet::SET_A) {
        return g_dataset_a.size_vec;
    }
    else {
        return g_dataset_b.size_vec;
    }
}

// Update signal pattern (double-buffered)
void signal_update_pattern(const std::string &signal) {
    std::vector<uint32_t> new_timings, new_modes;
    parse_signal(signal, new_timings, new_modes);

    // Convert combined modes to individual pin states
    std::vector<uint32_t> new_d4_vec, new_d5_vec, new_d6_vec;
    for (uint32_t mi : new_modes) {
        Bin bin = num2bin(mi); // Convert number to binary representation
        new_d4_vec.push_back(bin.b1);
        new_d5_vec.push_back(bin.b2);
        new_d6_vec.push_back(bin.b3);
    }

    // Debug output of parsed signal
    helper::print("time: ");
    for (auto ti : new_timings) {
        helper::printf("%d, ", ti);
    }
    helper::println(" ");
    helper::print("mode: ");
    for (auto mi : new_modes) {
        helper::printf("%d, ", mi);
    }
    helper::println(" ");

    // Update the inactive signal set (float buffering)
    if (xSemaphoreTake(g_signal_mutex, portMAX_DELAY) == pdTRUE) {
        if (g_active_set == SignalSet::SET_A) {
            helper::println("updating SET_B...");
            // Update SET_B while SET_A is active
            for (size_t i = 0; i < new_timings.size(); i++) {
                g_dataset_b.time_vec[i] = new_timings[i];
                g_dataset_b.d4_vec[i] = new_d4_vec[i];
                g_dataset_b.d5_vec[i] = new_d5_vec[i];
                g_dataset_b.d6_vec[i] = new_d6_vec[i];
            }
        }
        else {
            helper::println("updating SET_A...");
            // Update SET_A while SET_B is active
            for (size_t i = 0; i < new_timings.size(); i++) {
                g_dataset_a.time_vec[i] = new_timings[i];
                g_dataset_a.d4_vec[i] = new_d4_vec[i];
                g_dataset_a.d5_vec[i] = new_d5_vec[i];
                g_dataset_a.d6_vec[i] = new_d6_vec[i];
            }
        }
        g_num_timings = new_timings.size();
        g_switch_set_pending = true; // Mark for set switching
        xSemaphoreGive(g_signal_mutex);
    }
}

ERROR_CODE signal_update_full_control(const std::string &str_control_message) {

    int new_rows, new_cols;
    std::vector<float> new_gain_k;
    std::vector<uint32_t> new_timings;
    std::vector<uint32_t> new_modes;
    std::vector<float> new_target;
    ERROR_CODE err;

    // NOTE: 1 -> parse message
    parse_control_message(str_control_message, new_gain_k, new_rows, new_cols, new_timings, new_modes, new_target);

    if (err != ERROR_CODE::OK) {
        print_error_code(err);
        return err;
    }

    // Convert combined modes to individual pin states
    std::vector<uint32_t> new_d4_vec, new_d5_vec, new_d6_vec;
    for (uint32_t mi : new_modes) {
        Bin bin = num2bin(mi); // Convert number to binary representation
        new_d4_vec.push_back(bin.b1);
        new_d5_vec.push_back(bin.b2);
        new_d6_vec.push_back(bin.b3);
    }

    // NOTE: 2 -> Update dataset

    auto dataset_helper = [&new_timings, &new_d4_vec,
                           &new_d5_vec, &new_d6_vec,
                           &new_target, &new_rows,
                           &new_cols, &new_gain_k](DataSet &dataset) {
        for (size_t i = 0; i < new_timings.size(); i++) {
            dataset.time_vec[i] = new_timings[i];
            dataset.d4_vec[i] = new_d4_vec[i];
            dataset.d5_vec[i] = new_d5_vec[i];
            dataset.d6_vec[i] = new_d6_vec[i];
        }
        dataset.size_vec = new_target[0];

        dataset.target[0] = new_target[0];
        dataset.target[1] = new_target[1];
        dataset.target[2] = new_target[2];

        dataset.gain_k.rows = new_rows;
        dataset.gain_k.cols = new_cols;
        dataset.gain_k.size = new_gain_k.size();
        size_t copy_size = std::min(new_gain_k.size(), (size_t)MAX_MATRIX_ELEMENTS);
        for (size_t i = 0; i < copy_size; ++i) {
            dataset.gain_k.values[i] = new_gain_k[i];
        }
    };

    if (xSemaphoreTake(g_signal_mutex, portMAX_DELAY) == pdTRUE) {
        if (g_active_set == SignalSet::SET_A) {
            helper::println("updating SET_B...");
            // Update SET_B while SET_A is active
            dataset_helper(g_dataset_b);
        }
        else {
            helper::println("updating SET_A...");
            // Update SET_A while SET_B is active
            dataset_helper(g_dataset_a);
        }
        g_num_timings = new_timings.size();
        g_switch_set_pending = true; // Mark for set switching
        xSemaphoreGive(g_signal_mutex);
    }

    return ERROR_CODE::OK;
}

/**
 * Initialize signal controller
 */
void initialize_signal_controller() {
    // Create mutex for thread-safe signal data access
    g_signal_mutex = xSemaphoreCreateMutex();

    // Populate datasets with valid data
    DataSet *active = get_dataset_active();
    DataSet *not_active = get_dataset_not_active();
    helper_set_dataset_from_alpha(active, 0.5);
    helper_set_dataset_from_alpha(not_active, 0.5);
    g_num_timings = active->size_vec;

    // Configure GPIO pins as outputs and set initial low state
    pinMode(GPIO_DI1, OUTPUT);
    pinMode(GPIO_DI2, OUTPUT);
    pinMode(GPIO_DI3, OUTPUT);
    pinMode(GPIO_DI4, OUTPUT);
    pinMode(GPIO_DI5, OUTPUT);
    pinMode(GPIO_DI6, OUTPUT);
    set_all_outputs_low();
}

/**
 * Signal Generation Task
 * Runs on Core 1 and manages:
 * - Signal generation state machine
 * - Double-buffered signal set switching
 * - GPIO output control based on current state
 *
 * @param arg Unused task parameter
 */
void signal_task(void *arg) {
    esp_task_wdt_add(NULL); // Register with watchdog timer

    // NOTE: signal task loop
    while (1) {
        switch (g_signal_task_state) {
        case SignalTaskState::IDLE:
            // All outputs low when idle
            GPIO.out_w1tc = (1 << 2) | GPIO_DI4_MASK | GPIO_DI5_MASK | GPIO_DI6_MASK; // Include LED
            break;

        case SignalTaskState::HIGH_ALL:
            // All outputs high in HIGH_ALL mode
            GPIO.out_w1ts = (1 << 2) | GPIO_DI4_MASK | GPIO_DI5_MASK | GPIO_DI6_MASK; // Include LED
            break;

        case SignalTaskState::SIGNAL_RUN:
            // Check if switch is pending
            if (!g_switch_set_pending) {
                break;
            }
            // Switch occurs at the end of current pattern to avoid glitches
            if (g_current_state == g_active_num_timings - 1) {
                if (xSemaphoreTake(g_signal_mutex, pdMS_TO_TICKS(10)) == pdTRUE) {
                    // NOTE: 3 -> Toggle between SET_A and SET_B
                    ble_router_toggle_signal_dataset();

                    g_active_num_timings = g_num_timings; // Update to new pattern length
                    g_switch_set_pending = false;
                    xSemaphoreGive(g_signal_mutex);
                }
            }
            break;

        default:
            break;
        }

        esp_task_wdt_reset();          // Reset watchdog timer
        vTaskDelay(pdMS_TO_TICKS(10)); // 10ms task period
    }
}
