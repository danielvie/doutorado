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
#include "driver/timer.h"
#include <NimBLEDevice.h>
#include "helpers.h"

// CPU Core definitions for task assignment
#define CORE_0 0
#define CORE_1 1

// GPIO Pin definitions
#define LED 2                    // Built-in LED for status indication
#define MAX_ELEMENTS_SIGNAL 30   // Maximum number of timing elements in a signal pattern

// Digital output pins for signal generation
#define GPIO_DI1 4
#define GPIO_DI2 17
#define GPIO_DI3 18
#define GPIO_DI4 21              // Primary digital output pin 4
#define GPIO_DI5 22              // Primary digital output pin 5
#define GPIO_DI6 23              // Primary digital output pin 6

// Timer configuration for precise signal timing
#define CPU_FREQ_MHZ 240         // ESP32 CPU frequency
#define TIMER_DIVIDER 80         // Timer prescaler (240MHz / 80 = 3MHz timer clock)
#define TIMER_GROUP TIMER_GROUP_0
#define TIMER_IDX TIMER_0

// BLE Service and Characteristic UUIDs for remote control
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Default signal pattern configuration
// These vectors define the initial timing and output patterns
std::vector<uint64_t> timings = {50, 50, 50, 50, 50, 50};        // Timing intervals in timer ticks
uint32_t cycle_nrun = 10;                                         // Number of cycles before analog reading
std::vector<uint64_t> modes = {7, 0, 7, 0, 7, 0};               // Combined mode patterns (binary representation)
std::vector<uint64_t> modes_di4 = {1, 0, 1, 0, 1, 0};           // Individual pin states for DI4
std::vector<uint64_t> modes_di5 = {1, 0, 1, 0, 1, 0};           // Individual pin states for DI5
std::vector<uint64_t> modes_di6 = {1, 0, 1, 0, 1, 0};           // Individual pin states for DI6

// Double-buffered signal storage for seamless pattern switching
// SET_A and SET_B allow updating one set while the other is active
std::vector<uint64_t> time_vec_a, d4_vec_a, d5_vec_a, d6_vec_a;  // Signal set A
std::vector<uint64_t> time_vec_b, d4_vec_b, d5_vec_b, d6_vec_b;  // Signal set B

// Task state management
SignalTaskState signal_task_state = SignalTaskState::IDLE;       // Current signal generation state
BLETaskState ble_task_state = BLETaskState::IDLE;                // Current BLE communication state

// Timer and signal control variables (volatile for ISR access)
volatile uint8_t current_state = 0;                              // Current position in signal pattern
volatile uint32_t cycle_count = 0;                               // Number of completed signal cycles
volatile bool timer_initialized = false;                         // Timer initialization flag
volatile uint8_t num_timings = 0;                                // Length of new signal pattern
volatile uint8_t active_num_timings = 0;                         // Length of currently active signal pattern
volatile ActiveSignalSet active_set = ActiveSignalSet::SET_A;    // Currently active signal set (A or B)
volatile bool switch_set_pending = false;                        // Flag indicating pending signal set switch

// Mutex for thread-safe access to shared signal data
SemaphoreHandle_t signal_mutex = NULL;

// Pre-calculated GPIO masks for efficient bit manipulation
const uint32_t gpio_di4_mask = 1 << GPIO_DI4;
const uint32_t gpio_di5_mask = 1 << GPIO_DI5;
const uint32_t gpio_di6_mask = 1 << GPIO_DI6;

// Forward declarations
void bleTask(void* parameter);
void signalTask(void* arg);
void readAndSendAnalogData(NimBLECharacteristic* pCharacteristic);
void sendMessageStatus(NimBLECharacteristic* pCharacteristic);

/**
 * LED blink utility function for status indication
 * @param N Number of blinks to perform
 */
void blink(uint8_t N) {
    for (uint8_t i = 0; i < N; i++) {
        GPIO.out_w1ts = (1 << LED);  // Turn LED on
        vTaskDelay(pdMS_TO_TICKS(100));
        GPIO.out_w1tc = (1 << LED);  // Turn LED off
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// .. TIMER SETTINGS
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

    const uint32_t pin_mask = gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
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
    GPIO.out = (GPIO.out & ~pin_mask) | new_gpio_out_value;

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
void start_timer() {
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

    // Set initial pin states for first signal step
    uint32_t pin_states =
        (d4_vec[0] ? gpio_di4_mask : 0) |
        (d5_vec[0] ? gpio_di5_mask : 0) |
        (d6_vec[0] ? gpio_di6_mask : 0);
    GPIO.out_w1ts = pin_states;
    GPIO.out_w1tc = ~pin_states & (gpio_di4_mask | gpio_di5_mask | gpio_di6_mask);

    // Set first timer alarm and start timer
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, time_vec[0]);
    timer_start(TIMER_GROUP, TIMER_IDX);
}

/**
 * Stop the signal generation timer
 */
void stop_timer() {
    timer_pause(TIMER_GROUP, TIMER_IDX);
}

// .. BLE connect AND disconnect CALLBACKS
/**
 * BLE Server Callbacks
 * Handles client connection and disconnection events
 */
class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
        blink(3);  // Visual indication of connection
        Serial.println("Device connected");
    }
    void onDisconnect(NimBLEServer* pServer) {
        blink(2);  // Visual indication of disconnection
        Serial.println("Device disconnected");
        NimBLEDevice::startAdvertising();  // Resume advertising for new connections
    }
};

// .. BLE write CALLBACK
/**
 * BLE Characteristic Write Callbacks
 * Processes commands received via BLE characteristic writes
 * 
 * Supported commands:
 * - "START": Begin signal generation
 * - "HIGH": Set all outputs high (constant)
 * - "STOP"/"LOW": Stop signals and set outputs low
 * - "CYCLE_NRUN:N": Set cycle count for analog readings
 * - "SIGNAL:data": Load new signal pattern
 */
class CharacteristicCallbacks: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *characteristic) {
        std::string value = characteristic->getValue();
        
        Serial.print("received message: ");
        Serial.println(value.c_str());
        Serial.printf("Free heap: %d bytes\n", ESP.getFreeHeap());
        Serial.println("==================");

        
        // START command: Begin signal generation
        if (value == "START") {
            if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
                signal_task_state = SignalTaskState::SIGNAL_RUN;
                xSemaphoreGive(signal_mutex);
            }
            Serial.println("Signals started");
            digitalWrite(LED, HIGH);
            start_timer();
        } 
        // HIGH command: Set all outputs to constant high
        else if (value == "HIGH") {
            if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
                signal_task_state = SignalTaskState::HIGH_RUN;
                xSemaphoreGive(signal_mutex);
            }
            stop_timer();
            Serial.println("Signals high");
            digitalWrite(LED, LOW);
            GPIO.out_w1ts = gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
        } 
        // STOP/LOW commands: Stop signals and set outputs low
        else if (value == "STOP" || value == "LOW") {
            if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
                signal_task_state = SignalTaskState::IDLE;
                xSemaphoreGive(signal_mutex);
            }
            stop_timer();
            Serial.println("Signals stopped");
            digitalWrite(LED, LOW);
            GPIO.out_w1tc = gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
        } 
        // STATUS command: Returns the main status info from the system
        else if (value == "STATUS") {
            sendMessageStatus(characteristic);
        } 
        // CYCLE_NRUN command: Set analog reading frequency
        else if (value.substr(0,11) == "CYCLE_NRUN:") {
            std::string payload = value.substr(11);
            cycle_nrun = std::stoi(payload);
            Serial.printf("updating ncycles to `%d`!\n", cycle_nrun);
        } 
        // SIGNAL command: Load new signal pattern
        else if (value.substr(0,7) == "SIGNAL:") {
            std::string signal = value.substr(7);
            Serial.println("Signals received:");
            Serial.println(value.c_str());

            try {
                ble_task_state = BLETaskState::SIGNAL_READING;
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
            } catch (std::exception &e) {
                Serial.printf("Error parsing signal: %s\n", e.what());
                Serial.printf("Signal sent to parse: '%s'\n", signal.c_str());
            }
        }
    }
};

// .. MAIN BLE TASKS (updates matlab)
/**
 * BLE Communication Task
 * Runs on Core 1 and handles:
 * - BLE server initialization and advertising
 * - Periodic analog sensor readings
 * - Data transmission to connected clients
 * 
 * @param parameter Unused task parameter
 */
void bleTask(void* parameter) {
    Serial.print("BLE Task running on core: ");
    Serial.println(xPortGetCoreID());
    
    // Initialize BLE device and server
    NimBLEDevice::init("ESP32 Signal Controller");
    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    
    // Create service and characteristic for remote control
    NimBLEService *pService = pServer->createService(SERVICE_UUID);
    NimBLECharacteristic *pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY
    );
    
    pCharacteristic->setCallbacks(new CharacteristicCallbacks());
    pCharacteristic->setValue("Hello");
    pService->start();
    
    // Start advertising to make device discoverable
    NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
    
    blink(5);  // Indicate BLE initialization complete

    // Register task with watchdog timer
    esp_task_wdt_add(NULL);
    
    // Main BLE task loop
    while (1) {
        // Handle analog reading requests
        if (ble_task_state == BLETaskState::ANALOG_READ) {
            ble_task_state = BLETaskState::ANALOG_READING;
            readAndSendAnalogData(pCharacteristic);
            ble_task_state = BLETaskState::IDLE;
        }
        
        // Send signal if listen is ON without signal
        // if (signal_task_state != SignalTaskState::SIGNAL_RUN) {
        //     readAndSendAnalogData(pCharacteristic);
        //     vTaskDelay(pdMS_TO_TICKS(100));  // ms task period
        // }
        
        esp_task_wdt_reset();  // Reset watchdog timer
        
        // Use different delays based on signal state to give BLE more processing time during signal generation
        if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
            vTaskDelay(pdMS_TO_TICKS(5));   // Shorter delay when signal is running to handle BLE better
        } else {
            vTaskDelay(pdMS_TO_TICKS(10));  // Normal delay when not running signals
        }
    }
}

// .. MAIN SIGNAL TASK (signal statemachine and update_set logic)
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
                GPIO.out_w1tc = (1 << LED) | gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
                break;
                
            case SignalTaskState::HIGH_RUN:
                // All outputs high in HIGH_RUN mode
                GPIO.out_w1ts = (1 << LED) | gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
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

void add_time_and_mode_to_message(std::vector<uint64_t> &timings, 
                 std::vector<uint64_t> &d4, 
                 std::vector<uint64_t> &d5, 
                 std::vector<uint64_t> &d6, 
                 String &message) {

    // Debug output of parsed signal
    message += "time: ";
    for (auto ti : timings) {
        message += String(ti) + ", ";
    }
    message += "\n";
    message += "mode: ";
    for (int i = 0; i < d4.size(); i++) {
        message += String(d4[i]*1 + d5[i]*2 + d6[i]*4) + ", ";
    }
    message += "\n";
}

/**
 * Send Status info to main program
 * @param pCharacteristic Pointer to the BLE characteristic for sending data
 */
void sendMessageStatus(NimBLECharacteristic* pCharacteristic) {
    // Use static buffer to avoid heap allocation issues
    static char message_buffer[1024];  // Static buffer to avoid heap fragmentation
    int pos = 0;
    
    // Read analog values from multiple channels
    float voltage_03 = read_analog(AnalogPort::AN3);
    float voltage_05 = read_analog(AnalogPort::AN5);
    float voltage_06 = read_analog(AnalogPort::AN6);

    // Format message with sensor readings using snprintf for safety
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "status ");
    
    if (active_set == ActiveSignalSet::SET_A) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "(SET_A active)\n");
    } else {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "(SET_B active)\n");
    }

    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "state: ");
    if (signal_task_state == SignalTaskState::HIGH_RUN) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::HIGH_RUN\n");
    } else if (signal_task_state == SignalTaskState::IDLE) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::IDLE\n");
    } else if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::SIGNAL_RUN\n");
    }

    // Add analog readings
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                   "analog: an3:%.3f, an5:%.3f, an6:%.3f\n", 
                   voltage_03, voltage_05, voltage_06);

    // Add basic timing info without full vectors to prevent overflow
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                   "SET_A: %d elements, SET_B: %d elements\n", 
                   time_vec_a.size(), time_vec_b.size());
    
    // Add current state info if signal is running
    if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                       "current_state: %d, cycle_count: %d\n", 
                       current_state, cycle_count);
    }
    
    // Ensure null termination
    message_buffer[sizeof(message_buffer) - 1] = '\0';

    Serial.println(message_buffer);
    Serial.println("STATUS response sent successfully");
}

/**
 * Read analog values from multiple channels and send via BLE notification
 * @param pCharacteristic Pointer to the BLE characteristic for sending data
 */
void readAndSendAnalogData(NimBLECharacteristic* pCharacteristic) {
    // Use static buffer to avoid heap allocation issues
    static char analog_buffer[128];
    
    // Read analog values from multiple channels
    float voltage_03 = read_analog(AnalogPort::AN3);
    float voltage_05 = read_analog(AnalogPort::AN5);
    float voltage_06 = read_analog(AnalogPort::AN6);

    // Format message with sensor readings using snprintf for safety
    snprintf(analog_buffer, sizeof(analog_buffer), 
             "an3:%.3f, an5:%.3f, an6:%.3f", 
             voltage_03, voltage_05, voltage_06);
    
    // Ensure null termination
    analog_buffer[sizeof(analog_buffer) - 1] = '\0';

    // Send data via BLE notification
    pCharacteristic->setValue((uint8_t *)analog_buffer, strlen(analog_buffer));
    pCharacteristic->notify();
}

/**
 * System Setup Function
 * Initializes all hardware and software components:
 * - Serial communication
 * - Signal vectors and mutex
 * - ADC configuration
 * - GPIO configuration
 * - Watchdog timer
 * - FreeRTOS tasks
 */
void setup() {
    Serial.begin(115200);
    
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

    // Configure ADC channels for analog input reading
    adc1_config_width(ADC_WIDTH_BIT_12);  // 12-bit resolution (0-4095)
    adc1_config_channel_atten(ADC1_CHANNEL_0, ADC_ATTEN_DB_12);  // 0-3.3V range
    adc1_config_channel_atten(ADC1_CHANNEL_3, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_6, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_7, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_4, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_5, ADC_ATTEN_DB_12);

    // Configure GPIO pins as outputs and set initial low state
    pinMode(LED, OUTPUT);
    pinMode(GPIO_DI4, OUTPUT);
    pinMode(GPIO_DI5, OUTPUT);
    pinMode(GPIO_DI6, OUTPUT);
    GPIO.out_w1tc = (1 << LED) | gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;

    // Initialize watchdog timer (30 second timeout)
    esp_task_wdt_init(30, true);
    esp_task_wdt_add(NULL);

    // Create BLE task on Core 0 with higher stack size and higher priority for BLE operations and memory safety
    xTaskCreatePinnedToCore(
        bleTask,                    // Task function
        "BLE Task",                 // Task name
        10240,                      // Stack size (increased from 8192 to 10240 bytes)
        NULL,                       // Task parameter
        3,                          // Priority (increased from 2 to 3)
        NULL,                       // Task handle
        CORE_0                      // CPU core
    );
    
    // Create signal task on Core 1 with high priority for precise timing
    xTaskCreatePinnedToCore(
        signalTask,                 // Task function
        "Signal Task",              // Task name
        2048,                       // Stack size (bytes)
        NULL,                       // Task parameter
        configMAX_PRIORITIES - 2,   // High priority (second highest)
        NULL,                       // Task handle
        CORE_1                      // CPU core
    );
}

/**
 * Main Loop Function
 * Runs on Core 0 and serves as a simple watchdog reset loop
 * The actual work is done by the tasks created in setup()
 */
void loop() {
    esp_task_wdt_reset();           // Reset watchdog timer
    vTaskDelay(pdMS_TO_TICKS(1000)); // 1 second delay
}