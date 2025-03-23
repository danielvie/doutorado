#include <Arduino.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/timer.h"
#include <NimBLEDevice.h>
#include "helpers.h"

#define CORE_0 0
#define CORE_1 1

#define LED 2
#define MAX_ELEMENTS_SIGNAL 30

// define IO's
#define GPIO_DI1 4
#define GPIO_DI2 17
#define GPIO_DI3 18
#define GPIO_DI4 21
#define GPIO_DI5 22
#define GPIO_DI6 23

#define CPU_FREQ_MHZ 240  // ESP32 running at 240MHz

// Timer configuration
#define TIMER_DIVIDER         80  // Hardware timer clock divider
#define TIMER_GROUP           TIMER_GROUP_0  // Test on timer group 0
#define TIMER_IDX             TIMER_0  // Timer index as proper enum value

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// signal timing
std::vector<uint64_t> timings = {
    50, 25, 50, 25, 50, 25,
};

// signal modes
uint32_t cycle_nrun = 10; // number of cycles to read and notify MATLAB
std::vector<uint64_t> modes = {
    7, 0, 7, 0, 7, 0
};

std::vector<uint64_t> modes_di4 = { 1, 0, 1, 0, 1, 0 };
std::vector<uint64_t> modes_di5 = { 1, 0, 1, 0, 1, 0 };
std::vector<uint64_t> modes_di6 = { 1, 0, 1, 0, 1, 0 };

// Signal states
SignalTaskState::State signal_task_state = SignalTaskState::IDLE;
BLETaskState::State ble_task_state = BLETaskState::IDLE;

// Timer variables
volatile uint8_t current_state = 0;
volatile uint32_t cycle_count = 0;
volatile bool timer_initialized = false;
std::vector<uint64_t> time_vec, d4_vec, d5_vec, d6_vec;
volatile uint8_t num_timings = 0;

// Mutex for signal array access
SemaphoreHandle_t signal_mutex = NULL;

// GPIO bit masks
const uint32_t gpio_di4_mask = 1 << GPIO_DI4;
const uint32_t gpio_di5_mask = 1 << GPIO_DI5;
const uint32_t gpio_di6_mask = 1 << GPIO_DI6;

// blink helper
void blink(uint8_t N) {
    for (uint8_t i = 0; i < N; i++)
    {
        GPIO.out_w1ts = (1 << LED);
        vTaskDelay(pdMS_TO_TICKS(100));
        GPIO.out_w1tc = (1 << LED);
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// Timer ISR
bool IRAM_ATTR timer_group_isr_callback(void *args)
{
    // Reset the timer alarm
    timer_group_enable_alarm_in_isr(TIMER_GROUP, TIMER_IDX);

    if (signal_task_state != SignalTaskState::SIGNAL_RUN && 
        signal_task_state != SignalTaskState::SIGNAL_RUN_CHANGED) {
        return true;
    }

    // Process state change for signal pins
    uint32_t pin_states =
        (d4_vec[current_state] ? gpio_di4_mask : 0) |
        (d5_vec[current_state] ? gpio_di5_mask : 0) |
        (d6_vec[current_state] ? gpio_di6_mask : 0);

    // Set pins HIGH
    GPIO.out_w1ts = pin_states;

    // Set pins LOW
    GPIO.out_w1tc = ~pin_states & (gpio_di4_mask | gpio_di5_mask | gpio_di6_mask);

    // Set up next interval
    uint64_t next_alarm_us = time_vec[current_state];
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, next_alarm_us * TIMER_DIVIDER);

    // Move to next state
    current_state = (current_state + 1) % num_timings;
    
    // Count cycles when we loop back to state 0
    if (current_state == 0) {
        cycle_count++;
        
        // Allow read signals and notify MATLAB
        if (cycle_count % cycle_nrun == 0) {
            ble_task_state = BLETaskState::ANALOG_READ;
        }
    }

    return true;
}

// Function to initialize timer
void initialize_timer() {
    timer_config_t config = {
        .alarm_en = TIMER_ALARM_EN,
        .counter_en = TIMER_PAUSE,
        .intr_type = TIMER_INTR_LEVEL,
        .counter_dir = TIMER_COUNT_UP,
        .auto_reload = TIMER_AUTORELOAD_EN,
        .divider = TIMER_DIVIDER
    };
    
    timer_init(TIMER_GROUP, TIMER_IDX, &config);
    timer_set_counter_value(TIMER_GROUP, TIMER_IDX, 0);
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, time_vec[0] * TIMER_DIVIDER);
    timer_enable_intr(TIMER_GROUP, TIMER_IDX);
    timer_isr_callback_add(TIMER_GROUP, TIMER_IDX, timer_group_isr_callback, NULL, 0);
    timer_initialized = true;
}

// Function to start timer
void start_timer() {
    if (!timer_initialized) {
        initialize_timer();
    }
    current_state = 0;
    cycle_count = 0;
    timer_set_counter_value(TIMER_GROUP, TIMER_IDX, 0);
    timer_set_alarm_value(TIMER_GROUP, TIMER_IDX, time_vec[0] * TIMER_DIVIDER);
    timer_start(TIMER_GROUP, TIMER_IDX);
}

// Function to stop timer
void stop_timer() {
    timer_pause(TIMER_GROUP, TIMER_IDX);
}

// BLE Server callbacks
class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
        blink(3);
        Serial.println("Device connected");
    }
    
    void onDisconnect(NimBLEServer* pServer) {
        blink(2);
        Serial.println("Device disconnected");
        NimBLEDevice::startAdvertising();
    }
};

// BLE Characteristic callbacks
class CharacteristicCallbacks: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *characteristic) {
        std::string value = characteristic->getValue();
        if (value == "START") {
            if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
                signal_task_state = SignalTaskState::SIGNAL_RUN;
                xSemaphoreGive(signal_mutex);
            }
            Serial.println("Signals started");
            digitalWrite(LED, HIGH);
            start_timer();
        } else if (value == "HIGH") {
            if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
                signal_task_state = SignalTaskState::HIGH_RUN;
                xSemaphoreGive(signal_mutex);
            }
            stop_timer();
            Serial.println("Signals high");
            digitalWrite(LED, LOW);
            GPIO.out_w1ts = gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
        } else if (value == "STOP" || value == "LOW") {
            if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
                signal_task_state = SignalTaskState::IDLE;
                xSemaphoreGive(signal_mutex);
            }
            stop_timer();
            Serial.println("Signals stopped");
            digitalWrite(LED, LOW);
            GPIO.out_w1tc = gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
        } else if (value.substr(0,8) == "CYCLE_NRUN:") {
            std::string payload = value.substr(11);
            cycle_nrun = std::stoi(payload);
            Serial.printf("updating ncycles to `%d`!\n", cycle_nrun);
        } else if (value.substr(0,7) == "SIGNAL:") {
            std::string signal = value.substr(7);
            Serial.println("Signals received:");
            Serial.println(value.c_str());

            try {
                ble_task_state = BLETaskState::SIGNAL_READING;
                parseSignal(signal, timings, modes);
                
                // converting values of modes to binary
                modes_di4.clear();
                modes_di5.clear();
                modes_di6.clear();
                for (uint64_t mi : modes) {
                    Bin bin = Num2Bin(mi);
                    modes_di4.push_back(bin.b1);
                    modes_di5.push_back(bin.b2);
                    modes_di6.push_back(bin.b3);
                }

                // printing values
                Serial.print("time: ");
                for (auto ti : timings) {
                    Serial.printf("%d, ", ti);
                }
                Serial.println(" ");

                Serial.print("mode: ");
                for (auto mi : modes) {
                    Serial.printf("%d, ", mi);
                }
                Serial.println(" ");

                // Update timer signal values safely
                if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
                    // Clear and update vectors
                    time_vec.clear();
                    d4_vec.clear();
                    d5_vec.clear();
                    d6_vec.clear();
                    
                    time_vec = timings;
                    d4_vec = modes_di4;
                    d5_vec = modes_di5;
                    d6_vec = modes_di6;
                    
                    num_timings = timings.size();
                    
                    if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
                        signal_task_state = SignalTaskState::SIGNAL_RUN_CHANGED;
                        // If we are already running, we need to restart the timer with new values
                        stop_timer();
                        start_timer();
                    }
                    
                    xSemaphoreGive(signal_mutex);
                }
            }
            catch (std::exception &e) {
                Serial.printf("Error parsing signal: %s\n", e.what());
                Serial.printf("Signal sent to parse: '%s'\n", signal.c_str());
            }
        }
    }
};

// Task for BLE communication
void bleTask(void* parameter) {
    Serial.print("BLE Task running on core: ");
    Serial.println(xPortGetCoreID());
    
    NimBLEDevice::init("ESP32 Signal Controller");
    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    
    NimBLEService *pService = pServer->createService(SERVICE_UUID);
    NimBLECharacteristic *pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        NIMBLE_PROPERTY::READ |
        NIMBLE_PROPERTY::WRITE |
        NIMBLE_PROPERTY::NOTIFY
    );
    
    pCharacteristic->setCallbacks(new CharacteristicCallbacks());
    pCharacteristic->setValue("Hello");
    pService->start();
    
    NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
    
    // start blink
    blink(5);

    // keep task alive
    while(1) {
        if (ble_task_state == BLETaskState::ANALOG_READ) {
            ble_task_state = BLETaskState::ANALOG_READING;

            // float voltage_02 = read_analog(AnalogPort::AN2);
            float voltage_03 = read_analog(AnalogPort::AN3);
            // float voltage_04 = read_analog(AnalogPort::AN4);
            float voltage_05 = read_analog(AnalogPort::AN5);
            float voltage_06 = read_analog(AnalogPort::AN6);

            String message = "an3:" + String(voltage_03, 3) + ", " +
                             "an5:" + String(voltage_05, 3) + ", " +
                             "an6:" + String(voltage_06, 3);

            // Convert the message to a char array
            const char *messageCStr = message.c_str();

            // Set the value of the characteristic
            pCharacteristic->setValue((uint8_t *)messageCStr, strlen(messageCStr));
            pCharacteristic->notify();

            ble_task_state = BLETaskState::IDLE;
        }

        vTaskDelay(pdMS_TO_TICKS(50));
    }
}

// Signal task now just monitors state changes and handles any work not done by timer
void signalTask(void* arg) {
    while (1) {
        switch (signal_task_state)
        {
        // command all LOW when state IDLE
        case SignalTaskState::IDLE:
            GPIO.out_w1tc = (1 << LED) | gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
            vTaskDelay(pdMS_TO_TICKS(100));
            break;
        case SignalTaskState::HIGH_RUN:
            GPIO.out_w1ts = (1 << LED) | gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
            vTaskDelay(pdMS_TO_TICKS(100));
            break;
        default:
            vTaskDelay(pdMS_TO_TICKS(100));
            break;
        }
    }
}

void setup() {
    // configure serial
    Serial.begin(115200);

    // Create mutex for signal array access
    signal_mutex = xSemaphoreCreateMutex();

    // Initialize vectors
    time_vec.reserve(MAX_ELEMENTS_SIGNAL);
    d4_vec.reserve(MAX_ELEMENTS_SIGNAL);
    d5_vec.reserve(MAX_ELEMENTS_SIGNAL);
    d6_vec.reserve(MAX_ELEMENTS_SIGNAL);
    
    // Initial vector values
    time_vec = timings;
    d4_vec = modes_di4;
    d5_vec = modes_di5;
    d6_vec = modes_di6;
    num_timings = timings.size();

    // Configure ADC1 pins
    adc1_config_width(ADC_WIDTH_BIT_12); // 12-bit resolution
    adc1_config_channel_atten(ADC1_CHANNEL_0, ADC_ATTEN_DB_12); // {A6} GPIO_AN6 (GPIO36)
    adc1_config_channel_atten(ADC1_CHANNEL_3, ADC_ATTEN_DB_12); // {}   GPIO_AN3 (GPIO39)
    adc1_config_channel_atten(ADC1_CHANNEL_6, ADC_ATTEN_DB_12); // {A5} GPIO_AN5 (GPIO34)
    adc1_config_channel_atten(ADC1_CHANNEL_7, ADC_ATTEN_DB_12); // {A4} GPIO_AN7 (GPIO35)
    adc1_config_channel_atten(ADC1_CHANNEL_4, ADC_ATTEN_DB_12); // {A3} GPIO_AN4 (GPIO32)
    adc1_config_channel_atten(ADC1_CHANNEL_5, ADC_ATTEN_DB_12); // {A2} GPIO_AN5 (GPIO33)

    // configure pin
    pinMode(LED, OUTPUT);
    pinMode(GPIO_DI4, OUTPUT);
    pinMode(GPIO_DI5, OUTPUT);
    pinMode(GPIO_DI6, OUTPUT);

    // start with LOW
    GPIO.out_w1tc = (1 << LED) | gpio_di4_mask | gpio_di5_mask | gpio_di6_mask;
    
    // create BLE task
    xTaskCreatePinnedToCore(
        bleTask,    // Task function
        "BLE Task", // Task name
        4096,       // Stack size (bytes)
        NULL,       // Task parameters
        1,          // Highest priority
        NULL,       // Task handle
        CORE_0      // Core ID (0 = first core)
    );
    
    // create signal task
    xTaskCreatePinnedToCore(
        signalTask,               // Task function
        "Signal Task",            // Task name
        2048,                     // Stack size (bytes)
        NULL,                     // Task parameters
        configMAX_PRIORITIES - 2, // Lower priority than timer ISR
        NULL,                     // Task handle
        CORE_1                    // Core ID (1 = second core)
    );
}

void loop() {
    // Main loop remains empty as signal generation is handled by hardware timer and FreeRTOS tasks
    vTaskDelay(pdMS_TO_TICKS(1000));
}