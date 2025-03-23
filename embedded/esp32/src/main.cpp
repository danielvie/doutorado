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

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"


// Convert microseconds to CPU ticks
#define US_TO_TICKS(us) ((us) * CPU_FREQ_MHZ)

// signal timing
std::vector<uint64_t> timings = {
    50, 25, 50, 25, 50, 25,
};

// signal modes
uint32_t cycle_nrun = 10; // number of cycles to read and notify MATLAB
std::vector<uint64_t> modes = {
    // 5, 3, 4, 2, 5, 2
    7, 0, 7, 0, 7, 0
};

std::vector<uint64_t> modes_di4 = { 1, 0, 1, 0, 1, 0 };
std::vector<uint64_t> modes_di5 = { 1, 0, 1, 0, 1, 0 };
std::vector<uint64_t> modes_di6 = { 1, 0, 1, 0, 1, 0 };

// Signal states
SignalTaskState::State signal_task_state = SignalTaskState::IDLE;
BLETaskState::State ble_task_state = BLETaskState::IDLE;

// flag
// SIGNAL:50, 25, 50, 25, 50, 25; 5, 3, 4, 2, 5, 2
// SIGNAL:50, 50, 50, 50, 50, 50; 1, 0, 1, 0, 1, 0

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
            // signalsEnabled = 1;
            signal_task_state = SignalTaskState::SIGNAL_RUN;
            Serial.println("Signals started");
            digitalWrite(LED, HIGH);
        } else if (value == "HIGH") {
            // signalsEnabled = 2;
            signal_task_state = SignalTaskState::HIGH_RUN;
            Serial.println("Signals high");
            digitalWrite(LED, LOW);
        } else if (value == "STOP" || value == "LOW") {
            // signalsEnabled = 0;
            signal_task_state = SignalTaskState::IDLE;
            Serial.println("Signals stopped");
            digitalWrite(LED, LOW);
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

                if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
                    signal_task_state = SignalTaskState::SIGNAL_RUN_CHANGED;
                } else {
                    signal_task_state = SignalTaskState::SIGNAL_CHANGED;
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

            float voltage_02 = read_analog(AnalogPort::AN2);
            float voltage_03 = read_analog(AnalogPort::AN3);
            float voltage_04 = read_analog(AnalogPort::AN4);
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

void IRAM_ATTR signalTask(void* arg) {

    // precalculate GPIO bit masks
    const uint32_t gpio_di4_mask = 1 << GPIO_DI4;
    const uint32_t gpio_di5_mask = 1 << GPIO_DI5;
    const uint32_t gpio_di6_mask = 1 << GPIO_DI6;

    // variables to generate the sinal during a cycle
    std::vector<uint64_t> time_, d4_, d5_, d6_;
    time_.reserve(MAX_ELEMENTS_SIGNAL);
    d4_.reserve(MAX_ELEMENTS_SIGNAL);
    d5_.reserve(MAX_ELEMENTS_SIGNAL);
    d6_.reserve(MAX_ELEMENTS_SIGNAL);

    // update values
    auto print = [](std::vector<uint64_t> &v){
        for (auto vi : v) {
            Serial.printf("%d, ", vi);
        }
        Serial.println(";");
    };

    uint8_t num_timings_;
    auto UpdateSignalValues = [&time_, &d4_, &d5_, &d6_, &num_timings_]() {
        // clearing previous values
        time_.clear();
        d4_.clear();
        d5_.clear();
        d6_.clear();

        // updating arrays
        time_ = timings;
        d4_ = modes_di4;
        d5_ = modes_di5;
        d6_ = modes_di6;

        // updating number of elements
        num_timings_ = timings.size();
    };

    UpdateSignalValues();

    // signal loop
    uint8_t state = 0;
    uint32_t cycle_count = 0;
    uint64_t startTicks;

    auto SignalRun = [&state, &cycle_count, &UpdateSignalValues, &d4_, &d5_, &d6_, &startTicks, &num_timings_, &time_] {
        // command SIGNAL
        if (state == 0) {
            cycle_count++;

            // update values when something is changed
            if (signal_task_state == SignalTaskState::SIGNAL_RUN_CHANGED) {
                UpdateSignalValues();
            }

            // allow read signals and notify MATLAB
            if (cycle_count % cycle_nrun == 0) {
                ble_task_state = BLETaskState::ANALOG_READ;
            }
        }

        // prepare signal
        uint32_t pin_states =
            (d4_[state] ? gpio_di4_mask : 0) |
            (d5_[state] ? gpio_di5_mask : 0) |
            (d6_[state] ? gpio_di6_mask : 0);

        // set pins HIGH
        GPIO.out_w1ts = pin_states;

        // set pins LOW
        GPIO.out_w1tc = ~pin_states & (gpio_di4_mask | gpio_di5_mask | gpio_di6_mask);

        // count CPU ticks
        while ((esp_timer_get_time() * CPU_FREQ_MHZ) - startTicks < US_TO_TICKS(time_[state])) {}

        // move to next state
        state = (state + 1) % num_timings_;
    };

    while (1) {
        startTicks = esp_timer_get_time() * CPU_FREQ_MHZ;  // Current time in CPU ticks
        
        // ignore if there are no signal to run
        if (d4_.size() == 0) {
            continue;
        }

        switch (signal_task_state)
        {
        // command all LOW when state IDLE
        case SignalTaskState::IDLE:
            GPIO.out_w1tc = (1 << LED) | (1 << GPIO_DI4) | (1 << GPIO_DI5) | (1 << GPIO_DI6);
            vTaskDelay(pdMS_TO_TICKS(100));
            break;
        case SignalTaskState::HIGH_RUN:
            GPIO.out_w1ts = (1 << LED) | (1 << GPIO_DI4) | (1 << GPIO_DI5) | (1 << GPIO_DI6);
            vTaskDelay(pdMS_TO_TICKS(100));
            break;
        case SignalTaskState::SIGNAL_CHANGED:
            UpdateSignalValues();
            signal_task_state == SignalTaskState::IDLE;
            break;
        case SignalTaskState::SIGNAL_RUN_CHANGED:
            UpdateSignalValues();
            signal_task_state == SignalTaskState::SIGNAL_RUN;
            SignalRun();
            break;
        case SignalTaskState::SIGNAL_RUN:
            SignalRun();
            break;
        default:
            Serial.println("STATE NOT FOUND!!!");
            break;
        }
    }
}

void setup() {
    // configure serial
    Serial.begin(115200);

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
    GPIO.out_w1tc = (1 << LED) | (1 << GPIO_DI4) | (1 << GPIO_DI5) | (1 << GPIO_DI6);
    
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
        signalTask,           // Task function
        "Signal Task",            // Task name
        2048,                     // Stack size (bytes)
        NULL,                     // Task parameters
        configMAX_PRIORITIES - 1, // Highest priority
        NULL,                     // Task handle
        CORE_1                    // Core ID (1 = second core)
    );
}

void loop() {
    // Main loop remains empty as signal generation is handled by FreeRTOS task
    vTaskDelay(pdMS_TO_TICKS(1000));  // Corrected from pdMS_TO_DELAY to pdMS_TO_TICKS
}