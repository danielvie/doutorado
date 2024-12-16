#include <Arduino.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/timer.h"
#include <NimBLEDevice.h>
#include "helpers.h"

#define CORE_0 0
#define CORE_1 1

#define LED 2
#define GPIO_DI4 21
#define GPIO_DI5 22
#define GPIO_DI6 23
#define CPU_FREQ_MHZ 240  // ESP32 running at 240MHz

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Signal states
volatile int signalsEnabled = 0;

// Convert microseconds to CPU ticks
#define US_TO_TICKS(us) ((us) * CPU_FREQ_MHZ)

// signal timing
std::vector<uint64_t> timings = {
    50, 25, 50, 25, 50, 25,
};

// signal modes
std::vector<uint64_t> modes = {
    // 5, 3, 4, 2, 5, 2
    1, 0, 1, 0, 1, 0
};

SignalState::State signalState = SignalState::NORMAL;

// flag

// SIGNAL:50, 25, 50, 25, 50, 25; 5, 3, 4, 2, 5, 2
// SIGNAL:50, 50, 50, 50, 50, 50; 1, 0, 1, 0, 1, 0

// number of elements in the timing sequence
const uint8_t NUM_TIMINGS = timings.size();

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
            signalsEnabled = 1;
            Serial.println("Signals started");
            digitalWrite(LED, HIGH);
        } else if (value == "HIGH") {
            signalsEnabled = 2;
            Serial.println("Signals high");
            digitalWrite(LED, LOW);
        } else if (value == "STOP" || value == "LOW") {
            signalsEnabled = 0;
            Serial.println("Signals stopped");
            digitalWrite(LED, LOW);
        } else if (value.substr(0,7) == "SIGNAL:") {
            // signalsEnabled = 1;
            std::string command = value.substr(0,7);
            std::string signal = value.substr(7);
            Serial.println("Signals received:");
            Serial.println(command.c_str());
            Serial.println(signal.c_str());

            // std::vector<uint64_t> time, mode;
            
            try {
                signalState = SignalState::CHANGING;
                parseSignal(signal, timings, modes);
                
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

                digitalWrite(LED, LOW);
                signalState = SignalState::CHANGED;
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
        NIMBLE_PROPERTY::WRITE
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
        vTaskDelay(pdMS_TO_TICKS(1));
    }
}


void IRAM_ATTR generateSignal(void* arg) {
    uint8_t state = 0;
    uint64_t startTicks;

    // precalculate GPIO bit masks
    const uint32_t gpio_di4_mask = 1 << GPIO_DI4;
    const uint32_t gpio_di5_mask = 1 << GPIO_DI5;
    const uint32_t gpio_di6_mask = 1 << GPIO_DI6;

    // variables to generate the sinal during a cycle
    std::vector<uint64_t> time_, d4_, d5_, d6_;

    // update values
    auto update_bin_values = [&time_, &d4_, &d5_, &d6_]() {
        time_.clear();
        d4_.clear();
        d5_.clear();
        d6_.clear();
        
        time_ = timings;
        for (uint64_t mi : modes) {
            Bin bin = Num2Bin(mi);
            d4_.push_back((uint64_t)bin.b1);
            d5_.push_back((uint64_t)bin.b2);
            d6_.push_back((uint64_t)bin.b3);
        }
    };
    update_bin_values();

    // signal loop
    while (1) {
        startTicks = esp_timer_get_time() * CPU_FREQ_MHZ;  // Current time in CPU ticks

        // command all LOW
        if (signalsEnabled == 0)
        {
            GPIO.out_w1tc = (1 << LED) | (1 << GPIO_DI4) | (1 << GPIO_DI5) | (1 << GPIO_DI6);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        
        // command all HIGH
        if (signalsEnabled == 2)
        {
            GPIO.out_w1ts = (1 << LED) | (1 << GPIO_DI4) | (1 << GPIO_DI5) | (1 << GPIO_DI6);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        
        // command SIGNAL
        if (state == 0 && signalState == SignalState::CHANGED) {
            update_bin_values();
            signalState = SignalState::NORMAL;
        }
        
        // prepare signal
        uint32_t pin_states = 
            (d4_[state]? gpio_di4_mask : 0) |
            (d5_[state]? gpio_di5_mask : 0) |
            (d6_[state]? gpio_di6_mask : 0);
            
        // set pins HIGH
        GPIO.out_w1ts = pin_states;
        
        // set pins LOW
        GPIO.out_w1tc = ~pin_states & (gpio_di4_mask | gpio_di5_mask | gpio_di6_mask);

        // count CPU ticks
        while ((esp_timer_get_time() * CPU_FREQ_MHZ) - startTicks < US_TO_TICKS(time_[state])) {}
        
        // move to next state
        state = (state + 1) % NUM_TIMINGS;
    }
}

void setup() {
    // configure serial
    Serial.begin(115200);

    // configure pin
    pinMode(LED, OUTPUT);
    pinMode(GPIO_DI4, OUTPUT);
    pinMode(GPIO_DI5, OUTPUT);
    pinMode(GPIO_DI6, OUTPUT);

    // start with LOW
    GPIO.out_w1tc = (1 << LED) | (1 << GPIO_DI4) | (1 << GPIO_DI5) | (1 << GPIO_DI6);
    
    // create BLE task
    xTaskCreatePinnedToCore(
        bleTask,
        "BLE Task",
        2048,
        NULL,
        1,
        NULL,
        CORE_0
    );
    
    // create signal task
    xTaskCreatePinnedToCore(
        generateSignal,           // Task function
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