#include "signal_controller.h"
#include "ble_controller.h"
#include "esp_task_wdt.h"

// External references from BLE controller
extern BLETaskState ble_task_state;

// Default signal pattern configuration
std::vector<uint64_t> timings = {50, 50, 50, 50, 50, 50};        // Timing intervals in timer ticks
std::vector<uint64_t> modes = {7, 0, 7, 0, 7, 0};               // Combined mode patterns (binary representation)
std::vector<uint64_t> modes_di4 = {1, 0, 1, 0, 1, 0};           // Individual pin states for DI4
std::vector<uint64_t> modes_di5 = {1, 0, 1, 0, 1, 0};           // Individual pin states for DI5
std::vector<uint64_t> modes_di6 = {1, 0, 1, 0, 1, 0};           // Individual pin states for DI6

// Double-buffered signal storage for seamless pattern switching


SetData set_a_data; // Signal set A
SetData set_b_data; // Signal set B

// std::vector<uint64_t> time_vec_a, d4_vec_a, d5_vec_a, d6_vec_a;  // Signal set A
// std::vector<uint64_t> time_vec_b, d4_vec_b, d5_vec_b, d6_vec_b; // Signal set B

// Task state management
SignalTaskState signal_task_state = SignalTaskState::IDLE;

// Timer and signal control variables (volatile for ISR access)
volatile uint8_t current_state = 0;
volatile uint32_t cycle_count = 0;
volatile bool timer_initialized = false;
volatile uint8_t num_timings = 0;
volatile uint8_t active_num_timings = 0;
volatile ActiveSignalSet active_set = ActiveSignalSet::SET_A;
volatile bool switch_set_pending = false;

// Cycle configuration
uint32_t cycle_nrun = 10;

// Mutex for thread-safe access to shared signal data
SemaphoreHandle_t signal_mutex = NULL;

// Pre-calculated GPIO masks for efficient bit manipulation
const uint32_t gpio_di4_mask = 1 << GPIO_DI4;
const uint32_t gpio_di5_mask = 1 << GPIO_DI5;
const uint32_t gpio_di6_mask = 1 << GPIO_DI6;
const uint32_t gpio_pin_mask = gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;


/**
 * Hardware Timer Interrupt Service Routine (ISR)
 * 
 * This ISR executes at precise timing intervals to generate digital signals.
 * It runs in IRAM for maximum performance and minimal jitter.
 * 
 * @param args Unused parameter (required by timer callback signature)
 * @return true to continue timer operation
 */
bool IRAM_ATTR timer_group_isr_callback(void *args) {
    // Re-enable timer alarm for next interrupt
    timer_group_enable_alarm_in_isr(TIMER_GROUP, TIMER_IDX);

    // Only execute signal generation when in SIGNAL_RUN state
    if (signal_task_state != SignalTaskState::SIGNAL_RUN) {
        return true;
    }

    // Pre-calculate next state
    uint8_t next_state = (current_state + 1) % active_num_timings;

    uint32_t new_gpio_out_value = 0;

    // Build pin state mask based on active signal pattern
    if (active_set == ActiveSignalSet::SET_A) {
        new_gpio_out_value = (set_a_data.d4_vec[next_state] ? gpio_di4_mask : 0) |
                             (set_a_data.d5_vec[next_state] ? gpio_di5_mask : 0) |
                             (set_a_data.d6_vec[next_state] ? gpio_di6_mask : 0);
    } else {
        new_gpio_out_value = (set_b_data.d4_vec[next_state] ? gpio_di4_mask : 0) |
                             (set_b_data.d5_vec[next_state] ? gpio_di5_mask : 0) |
                             (set_b_data.d6_vec[next_state] ? gpio_di6_mask : 0);
    }

    // Atomic GPIO update: Write directly to the GPIO_OUT_REG for simultaneous update
    GPIO.out = (GPIO.out & ~gpio_pin_mask) | new_gpio_out_value;

    // Update state
    current_state = next_state;

    // Set next alarm
    if (active_set == ActiveSignalSet::SET_A) {
        timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, set_a_data.time_vec[current_state]);
    } else {
        timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, set_b_data.time_vec[current_state]);
    }

    // Check for cycle completion and trigger analog reading if needed
    if (current_state == 0) {
        cycle_count++;
        if (cycle_count % cycle_nrun == 0) {
            ble_task_state = BLETaskState::ANALOG_READ;
        }
    }

    return true;
}

/**
 * Initialize the hardware timer for signal generation
 * Configures timer with appropriate prescaler and interrupt settings
 */
void initialize_timer() {
    timer_config_t config = {
        .alarm_en = TIMER_ALARM_EN,      // Enable alarm functionality
        .counter_en = TIMER_PAUSE,       // Start in paused state
        .intr_type = TIMER_INTR_LEVEL,   // Level-triggered interrupt
        .counter_dir = TIMER_COUNT_UP,   // Count upward
        .auto_reload = TIMER_AUTORELOAD_EN,  // Auto-reload on alarm
        .divider = TIMER_DIVIDER         // Prescaler: 240MHz / 80 = 3MHz
    };
    
    timer_init(TIMER_GROUP, TIMER_IDX, &config);
    timer_set_counter_value(TIMER_GROUP, TIMER_IDX, 0);
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, set_a_data.time_vec[0]);
    timer_enable_intr(TIMER_GROUP, TIMER_IDX);
    timer_isr_callback_add(TIMER_GROUP, TIMER_IDX, timer_group_isr_callback, NULL, 0);
    timer_initialized = true;
}

/**
 * Start the signal generation timer
 * Initializes timer if needed and begins signal output
 */
void startSignalTimer() {
    if (!timer_initialized) {
        initialize_timer();
    }
    
    // Reset state variables
    current_state = 0;
    cycle_count = 0;
    timer_set_counter_value(TIMER_GROUP, TIMER_IDX, 0);
    
    // Get references to active signal set
    std::vector<uint64_t>& time_vec = (active_set == ActiveSignalSet::SET_A) ? set_a_data.time_vec : set_b_data.time_vec;
    std::vector<uint64_t>& d4_vec = (active_set == ActiveSignalSet::SET_A) ? set_a_data.d4_vec : set_b_data.d4_vec;
    std::vector<uint64_t>& d5_vec = (active_set == ActiveSignalSet::SET_A) ? set_a_data.d5_vec : set_b_data.d5_vec;
    std::vector<uint64_t>& d6_vec = (active_set == ActiveSignalSet::SET_A) ? set_a_data.d6_vec : set_b_data.d6_vec;

    // Update active signal length
    active_num_timings = (active_set == ActiveSignalSet::SET_A) ? set_a_data.time_vec.size() : set_a_data.time_vec.size();

    // Set initial pin states for first signal step using atomic GPIO update
    uint32_t initial_pin_states = 
        (d4_vec[0] ? gpio_di4_mask : 0) |
        (d5_vec[0] ? gpio_di5_mask : 0) |
        (d6_vec[0] ? gpio_di6_mask : 0);
    
    // Atomic GPIO update: Write directly to the GPIO_OUT_REG for simultaneous update
    GPIO.out = (GPIO.out & ~gpio_pin_mask) | initial_pin_states;

    // Set first timer alarm and start timer
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, time_vec[0]);
    timer_start(TIMER_GROUP, TIMER_IDX);
}

/**
 * Stop the signal generation timer
 */
void stopSignalTimer() {
    timer_pause(TIMER_GROUP, TIMER_IDX);
}

/**
 * Set all digital outputs to high
 */
void setAllOutputsHigh() {
    GPIO.out_w1ts = gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
}

/**
 * Set all digital outputs to low
 */
void setAllOutputsLow() {
    GPIO.out_w1tc = gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
}

/**
 * Get the size of a signal set
 */
int getSignalSetSize(ActiveSignalSet set) {
    if (set == ActiveSignalSet::SET_A) {
        return set_a_data.time_vec.size();
    } else {
        return set_b_data.time_vec.size();
    }
}

/**
 * Update signal pattern from string
 */
void updateSignalPattern(const std::string& signal) {
    std::vector<uint64_t> new_timings, new_modes;
    parseSignal(signal, new_timings, new_modes);

    // Convert combined modes to individual pin states
    std::vector<uint64_t> new_d4_vec, new_d5_vec, new_d6_vec;
    for (uint64_t mi : new_modes) {
        Bin bin = Num2Bin(mi);  // Convert number to binary representation
        new_d4_vec.push_back(bin.b1);
        new_d5_vec.push_back(bin.b2);
        new_d6_vec.push_back(bin.b3);
    }

    // Debug output of parsed signal
    Serial.print("time: ");
    for (auto ti : new_timings) {
        Serial.printf("%d, ", ti);
    }
    Serial.println(" ");
    Serial.print("mode: ");
    for (auto mi : new_modes) {
        Serial.printf("%d, ", mi);
    }
    Serial.println(" ");

    // Update the inactive signal set (double buffering)
    if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
        if (active_set == ActiveSignalSet::SET_A) {
            Serial.println("updating SET_B...");
            // Update SET_B while SET_A is active
            set_b_data.time_vec = new_timings;
            set_b_data.d4_vec = new_d4_vec;
            set_b_data.d5_vec = new_d5_vec;
            set_b_data.d6_vec = new_d6_vec;
        } else {
            Serial.println("updating SET_A...");
            // Update SET_A while SET_B is active
            set_a_data.time_vec = new_timings;
            set_a_data.d4_vec = new_d4_vec;
            set_a_data.d5_vec = new_d5_vec;
            set_a_data.d6_vec = new_d6_vec;
        }
        num_timings = new_timings.size();
        switch_set_pending = true;  // Mark for set switching
        xSemaphoreGive(signal_mutex);
    }
}

void updateSignalControl(const std::string& str_control_message) {

    int new_m,new_n;
    std::vector<double> new_gain_k;
    std::vector<uint64_t> new_timings;
    std::vector<uint64_t> new_modes;
    std::vector<double> new_target;
    ERROR_CODE err;

    parse_control_message(str_control_message, new_m, new_n, new_gain_k, new_timings, new_modes, new_target);

    // if (err != ERROR_CODE::OK) {
    //     print_error_code(err);
    // } else {
    //     Serial.println("VALUES PARSED:\n");
    //     Matrix gain_matrix(m, n, gain_k);
    //     Serial.println("");
    //     gain_matrix.print();
    //     Serial.println("\n");
    //     Serial.println("times:");
    //     for (auto el : new_timings) {
    //         Serial.printf("%d, ", el);
    //     }
    //     Serial.println("\n");
    //     Serial.println("modes:");
    //     for (auto el : new_modes) {
    //         Serial.printf("%d, ", el);
    //     }
    //     Serial.println("\n");
    //     Serial.println("target:");
    //     for (auto el : target) {
    //         Serial.printf("%f, ", el);
    //     }
    //     Serial.println("\n");
    // }


    if (err != ERROR_CODE::OK) {
        print_error_code(err);
    } else {
        // Convert combined modes to individual pin states
        std::vector<uint64_t> new_d4_vec, new_d5_vec, new_d6_vec;
        for (uint64_t mi : new_modes) {
            Bin bin = Num2Bin(mi);  // Convert number to binary representation
            new_d4_vec.push_back(bin.b1);
            new_d5_vec.push_back(bin.b2);
            new_d6_vec.push_back(bin.b3);
        }

        // Update the inactive signal set (double buffering)
        if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
            if (active_set == ActiveSignalSet::SET_A) {
                Serial.println("updating SET_B...");
                // Update SET_B while SET_A is active
                set_b_data.time_vec = new_timings;
                set_b_data.d4_vec = new_d4_vec;
                set_b_data.d5_vec = new_d5_vec;
                set_b_data.d6_vec = new_d6_vec;
                set_b_data.target = new_target;
                set_b_data.m = new_m;
                set_b_data.n = new_n;
                set_b_data.gain_k = new_gain_k;
            }
            else {
                Serial.println("updating SET_A...");
                // Update SET_A while SET_B is active
                set_a_data.time_vec = new_timings;
                set_a_data.d4_vec = new_d4_vec;
                set_a_data.d5_vec = new_d5_vec;
                set_a_data.d6_vec = new_d6_vec;
                set_a_data.target = new_target;
                set_a_data.m = new_m;
                set_a_data.n = new_n;
                set_a_data.gain_k = new_gain_k;
            }
            num_timings = new_timings.size();
            switch_set_pending = true; // Mark for set switching
            xSemaphoreGive(signal_mutex);
        }
    }
    
}


/**
 * Initialize signal controller
 */
void initializeSignalController() {
    // Create mutex for thread-safe signal data access
    signal_mutex = xSemaphoreCreateMutex();

    // Pre-allocate vector memory to avoid dynamic allocation during operation
    set_a_data.time_vec.reserve(MAX_ELEMENTS_SIGNAL);
    set_a_data.d4_vec.reserve(MAX_ELEMENTS_SIGNAL);
    set_a_data.d5_vec.reserve(MAX_ELEMENTS_SIGNAL);
    set_a_data.d6_vec.reserve(MAX_ELEMENTS_SIGNAL);
    set_b_data.time_vec.reserve(MAX_ELEMENTS_SIGNAL);
    set_b_data.d4_vec.reserve(MAX_ELEMENTS_SIGNAL);
    set_b_data.d5_vec.reserve(MAX_ELEMENTS_SIGNAL);
    set_b_data.d6_vec.reserve(MAX_ELEMENTS_SIGNAL);
    
    // Initialize signal sets with default patterns
    set_a_data.time_vec = timings;
    set_a_data.d4_vec = modes_di4;
    set_a_data.d5_vec = modes_di5;
    set_a_data.d6_vec = modes_di6;
    num_timings = timings.size();
    active_num_timings = num_timings;

    // Initialize backup signal set with same default pattern
    set_b_data.time_vec = timings;
    set_b_data.d4_vec = modes_di4;
    set_b_data.d5_vec = modes_di5;
    set_b_data.d6_vec = modes_di6;

    // Configure GPIO pins as outputs and set initial low state
    pinMode(GPIO_DI4, OUTPUT);
    pinMode(GPIO_DI5, OUTPUT);
    pinMode(GPIO_DI6, OUTPUT);
    setAllOutputsLow();
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
void signalTask(void* arg) {
    esp_task_wdt_add(NULL);  // Register with watchdog timer
    
    // Main signal task loop
    while (1) {
        switch (signal_task_state) {
            case SignalTaskState::IDLE:
                // All outputs low when idle
                GPIO.out_w1tc = (1 << 2) | gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;  // Include LED
                break;
                
            case SignalTaskState::HIGH_RUN:
                // All outputs high in HIGH_RUN mode
                GPIO.out_w1ts = (1 << 2) | gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;  // Include LED
                break;
                
            case SignalTaskState::SIGNAL_RUN:
                // Handle seamless signal set switching during signal generation
                // Switch occurs at the end of current pattern to avoid glitches
                if (switch_set_pending && current_state == active_num_timings - 1) {
                    if (xSemaphoreTake(signal_mutex, pdMS_TO_TICKS(10)) == pdTRUE) {
                        // Toggle between SET_A and SET_B
                        if (active_set == ActiveSignalSet::SET_A) {
                            active_set = ActiveSignalSet::SET_B;
                        } else {
                            active_set = ActiveSignalSet::SET_A;
                        }

                        active_num_timings = num_timings; // Update to new pattern length
                        switch_set_pending = false;
                        xSemaphoreGive(signal_mutex);
                    }
                }
                break;
                
            default:
                break;
        }
        
        esp_task_wdt_reset();  // Reset watchdog timer
        vTaskDelay(pdMS_TO_TICKS(10));  // 10ms task period
    }
}
