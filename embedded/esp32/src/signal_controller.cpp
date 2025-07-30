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
std::vector<uint64_t> time_vec_a, d4_vec_a, d5_vec_a, d6_vec_a;  // Signal set A
std::vector<uint64_t> time_vec_b, d4_vec_b, d5_vec_b, d6_vec_b;  // Signal set B

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
        new_gpio_out_value = (d4_vec_a[next_state] ? gpio_di4_mask : 0) |
                             (d5_vec_a[next_state] ? gpio_di5_mask : 0) |
                             (d6_vec_a[next_state] ? gpio_di6_mask : 0);
    } else {
        new_gpio_out_value = (d4_vec_b[next_state] ? gpio_di4_mask : 0) |
                             (d5_vec_b[next_state] ? gpio_di5_mask : 0) |
                             (d6_vec_b[next_state] ? gpio_di6_mask : 0);
    }

    // Atomic GPIO update: Write directly to the GPIO_OUT_REG for simultaneous update
    GPIO.out = (GPIO.out & ~gpio_pin_mask) | new_gpio_out_value;

    // Update state
    current_state = next_state;

    // Set next alarm
    if (active_set == ActiveSignalSet::SET_A) {
        timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, time_vec_a[current_state]);
    } else {
        timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, time_vec_b[current_state]);
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
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, time_vec_a[0]);
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
    std::vector<uint64_t>& time_vec = (active_set == ActiveSignalSet::SET_A) ? time_vec_a : time_vec_b;
    std::vector<uint64_t>& d4_vec = (active_set == ActiveSignalSet::SET_A) ? d4_vec_a : d4_vec_b;
    std::vector<uint64_t>& d5_vec = (active_set == ActiveSignalSet::SET_A) ? d5_vec_a : d5_vec_b;
    std::vector<uint64_t>& d6_vec = (active_set == ActiveSignalSet::SET_A) ? d6_vec_a : d6_vec_b;

    // Update active signal length
    active_num_timings = (active_set == ActiveSignalSet::SET_A) ? time_vec_a.size() : time_vec_b.size();

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
        return time_vec_a.size();
    } else {
        return time_vec_b.size();
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
            time_vec_b = new_timings;
            d4_vec_b = new_d4_vec;
            d5_vec_b = new_d5_vec;
            d6_vec_b = new_d6_vec;
        } else {
            Serial.println("updating SET_A...");
            // Update SET_A while SET_B is active
            time_vec_a = new_timings;
            d4_vec_a = new_d4_vec;
            d5_vec_a = new_d5_vec;
            d6_vec_a = new_d6_vec;
        }
        num_timings = new_timings.size();
        switch_set_pending = true;  // Mark for set switching
        xSemaphoreGive(signal_mutex);
    }
}

/**
 * Initialize signal controller
 */
void initializeSignalController() {
    // Create mutex for thread-safe signal data access
    signal_mutex = xSemaphoreCreateMutex();

    // Pre-allocate vector memory to avoid dynamic allocation during operation
    time_vec_a.reserve(MAX_ELEMENTS_SIGNAL);
    d4_vec_a.reserve(MAX_ELEMENTS_SIGNAL);
    d5_vec_a.reserve(MAX_ELEMENTS_SIGNAL);
    d6_vec_a.reserve(MAX_ELEMENTS_SIGNAL);
    time_vec_b.reserve(MAX_ELEMENTS_SIGNAL);
    d4_vec_b.reserve(MAX_ELEMENTS_SIGNAL);
    d5_vec_b.reserve(MAX_ELEMENTS_SIGNAL);
    d6_vec_b.reserve(MAX_ELEMENTS_SIGNAL);
    
    // Initialize signal sets with default patterns
    time_vec_a = timings;
    d4_vec_a = modes_di4;
    d5_vec_a = modes_di5;
    d6_vec_a = modes_di6;
    num_timings = timings.size();
    active_num_timings = num_timings;

    // Initialize backup signal set with same default pattern
    time_vec_b = timings;
    d4_vec_b = modes_di4;
    d5_vec_b = modes_di5;
    d6_vec_b = modes_di6;

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
