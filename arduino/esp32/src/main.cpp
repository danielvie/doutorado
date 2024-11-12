#include <Arduino.h>
#include <NimBLEDevice.h>
#include <NimBLEServer.h>
#include "helpers.h"
#include "esp_log.h"

// Pin definitions
#define LED_PIN 2
#define CORE_0 0  // Communication core
#define CORE_1 1  // LED control core

// Diginal Pins
#define DI1 4
#define DI2 17
#define DI3 18
#define DI4 21
#define DI5 22
#define DI6 23

// BLE UUIDs
#define SERVICE_UUID        "4b887ab9-7677-4b0a-8371-113d46b91c1d"
#define CHARACTERISTIC_UUID "2ef72a2d-22cb-4ab8-8c03-affce243d888"

// Shared variables between cores
bool deviceConnected = false;
bool isBlinking = false;
bool hasLog = false;
int blinkInterval = 500;

// time and mode variables
auto start = std::chrono::high_resolution_clock::now();
bool signalIsRunning = false;
std::vector<int64_t> timeValues;
std::vector<int64_t> modeValues;

// command digital out
uint16_t digitalOut = 0;

// Task handles
TaskHandle_t blinkTaskHandle = NULL;
TaskHandle_t bleTaskHandle = NULL;

// Mutex for shared variables
portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;


// .. helpers
void blink_n(const int& n) {
    for(int i = 0; i < n; i++) {
        digitalWrite(LED_PIN, HIGH);
        vTaskDelay(100 / portTICK_PERIOD_MS);
        digitalWrite(LED_PIN, LOW);
        vTaskDelay(100 / portTICK_PERIOD_MS);
    }
}

// .. connect events
class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
        portENTER_CRITICAL(&mux);
        deviceConnected = true;
        portEXIT_CRITICAL(&mux);
        Serial.println("MATLAB Connnnected!");

        // signal connection on LED2
        blink_n(3);
    }
    void onDisconnect(NimBLEServer* pServer) {
        portENTER_CRITICAL(&mux);
        deviceConnected = false;
        portEXIT_CRITICAL(&mux);
        Serial.println("MATLAB Disconnected!");
        pServer->startAdvertising();

        // signal disconnection on LED2
        blink_n(2);
    }
};

// .. command handlers
class CharacteristicCallbacks: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pCharacteristic) {
        std::string value = pCharacteristic->getValue();
        
        if (value.length() > 0) {
            if (hasLog) {
                Serial.print("\nReceived command: ");
                Serial.println(value.c_str());
            }
            

            portENTER_CRITICAL(&mux);
            if (value == "START") {
                isBlinking = true;
                if (hasLog) {
                    Serial.println("LED Blinking Started");
                }
            }
            else if (value == "STOP") {
                isBlinking = false;

                digitalWrite(LED_PIN, LOW);
                if (hasLog) {
                    Serial.println("LED Blinking Stopped");
                }
            }
            else if (value.substr(0, 8) == "INTERVAL") {
                String intervalStr = String(value.c_str()).substring(9);
                blinkInterval = intervalStr.toInt();
                if (hasLog) {
                    Serial.printf("Blink interval set to: %d ms\n", blinkInterval);
                }
            }
            else if (value == "SIGNAL_ON") {
                signalIsRunning = true;
                start = std::chrono::high_resolution_clock::now();
                if (hasLog) {
                Serial.printf("value received: `%s` signalIsRunning: %d\n", value.c_str(), signalIsRunning);
                }
            }
            else if (value == "SIGNAL_OFF") {
                signalIsRunning = false;

                digitalWrite(LED_PIN, LOW);
                digitalWrite(DI4, LOW);
                digitalWrite(DI5, LOW);
                digitalWrite(DI6, LOW);

                if (hasLog) {
                    Serial.printf("value received: `%s` signalIsRunning: %d\n", value.c_str(), signalIsRunning);
                }
            }
            else if (value == "0") {
                digitalOut = 0;
                if (hasLog) {
                    Serial.printf("value received: `%s`\n", value.c_str());
                }
            }
            else if (value == "D4") {
                digitalOut = 4;
                if (hasLog) {
                    Serial.printf("value received: `%s`\n", value.c_str());
                }
            }
            else if (value == "D5") {
                digitalOut = 5;
                if (hasLog) {
                    Serial.printf("value received: `%s`\n", value.c_str());
                }
            }
            else if (value == "D6") {
                digitalOut = 6;
                if (hasLog) {
                    Serial.printf("value received: `%s`\n", value.c_str());
                }
            }
            else if (value == "LOG_ON") {
                hasLog = true;
                if (hasLog) {
                    Serial.printf("value received: `%s`\n", value.c_str());
                }
            }
            else if (value == "LOG_OFF") {
                hasLog = false;
                if (hasLog) {
                    Serial.printf("value received: `%s`\n", value.c_str());
                }
            }
            else if (value.substr(0, 6) == "SIGNAL") {
                String signal = String(value.c_str()).substring(7);
                // Serial.printf("signal received: `%s`\n", signal.c_str());
                // Serial.println("new signal received!\n");
                if (hasLog) {
                    Serial.println("new signal received");
                }
                // Serial.println(signal.c_str());

                // parse values of time and mode
                parseString(signal.c_str(), timeValues, modeValues);
            }
            portEXIT_CRITICAL(&mux);
        }
    }
};

// .. Blink Task
void blinkTask(void *parameter) {
    Serial.print("Blink Task running on core: ");
    Serial.println(xPortGetCoreID());
    
    bool ledState = false;
    
    while(true) {
        bool shouldBlink;
        bool shouldRunSignal;
        int currentInterval;
        std::vector<int64_t> currentTimeValues;
        std::vector<int64_t> currentModeValues;
        
        // Safely read shared variables
        portENTER_CRITICAL(&mux);
        shouldBlink = isBlinking;
        shouldRunSignal = signalIsRunning;
        currentInterval = blinkInterval;

        currentTimeValues = timeValues;
        currentModeValues = modeValues;
        portEXIT_CRITICAL(&mux);
        
        if (shouldRunSignal) {
            // RunSignals(currentTimeValues, currentModeValues);

            // track starting time
            start = std::chrono::high_resolution_clock::now();
            if (hasLog) {
                Serial.println("\nnew loop... (elapsed time 0)\n");
            }

            // current index
            size_t index = 0;
            size_t N = currentTimeValues.size();
            
            // iterate through arrays
            while(index < N) {
                // calculate elapsed time
                auto now = std::chrono::high_resolution_clock::now();
                auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(now - start).count();
                
                // check if time has reached
                uint64_t time_microsec = currentTimeValues[index];
                if (elapsed >= time_microsec) {
                    // update mode
                    int mode = currentModeValues[index];

                    Bin mode_bin = Num2Bin(mode);
                    // struct Bin Num2Bin(int num)
                    
                    digitalWrite(LED_PIN, mode_bin.b1);
                    digitalWrite(DI4, mode_bin.b1);
                    digitalWrite(DI5, mode_bin.b2);
                    digitalWrite(DI6, mode_bin.b3);

                    int cur_time = currentTimeValues[index];
                    if (hasLog) {
                        Serial.printf("elapsed time: %d .. mode: %d\n", cur_time, mode);
                    }
                    // Serial.printf(" .. (di4, di5, di6) -> Bin(%d, %d, %d)\n", mode_bin.b3, mode_bin.b2, mode_bin.b1);
                    
                    // update index
                    ++index;
                    
                    // break if is last element
                    if (index == currentTimeValues.size()) {
                        break;
                    }
                }
            }
            if (hasLog) {
                Serial.println("\n...end of loop");
            }
        }
        else if (shouldBlink) {
            ledState = !ledState;
            digitalWrite(LED_PIN, ledState);
            digitalWrite(DI4, ledState);
            // digitalWrite(LED_PIN, ledState);
            // digitalWrite(LED_PIN, ledState);
            // vTaskDelay(currentInterval / portTICK_PERIOD_MS);
            vTaskDelay(currentInterval / portTICK_PERIOD_MS);
        }
        else if (digitalOut == 0) {
            digitalWrite(LED_PIN, LOW);
            digitalWrite(DI4, LOW);
            digitalWrite(DI5, LOW);
            digitalWrite(DI6, LOW);
        }
        else if (digitalOut == 4) {
            digitalWrite(DI4, HIGH);
            digitalWrite(DI5, LOW);
            digitalWrite(DI6, LOW);
        }
        else if (digitalOut == 5) {
            digitalWrite(DI4, LOW);
            digitalWrite(DI5, HIGH);
            digitalWrite(DI6, LOW);
        } 
        else if (digitalOut == 6) {
            digitalWrite(DI4, LOW);
            digitalWrite(DI5, LOW);
            digitalWrite(DI6, HIGH);
        } 
        else {
            digitalWrite(LED_PIN, LOW);
            vTaskDelay(100 / portTICK_PERIOD_MS);
        }
    }
}

// .. Comunication Task
void bleTask(void *parameter) {
    Serial.print("BLE Task running on core: ");
    Serial.println(xPortGetCoreID());
    
    // Initialize BLE
    NimBLEDevice::init("ESP32_BLINK");
    
    // Create the BLE Server
    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    // Create the BLE Service
    NimBLEService *pService = pServer->createService(SERVICE_UUID);

    // Create BLE Characteristic
    NimBLECharacteristic *pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        NIMBLE_PROPERTY::WRITE
    );
    pCharacteristic->setCallbacks(new CharacteristicCallbacks());

    // Start the service
    pService->start();

    // Start advertising
    NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    NimBLEDevice::startAdvertising();
    
    Serial.println("BLE initialized and advertising!");
    ESP_LOGI("TAG", "BLE initialized and advertising!");
    blink_n(5);

    // Keep the task alive
    while(true) {
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}

// .. setup
void setup() {
    Serial.begin(115200);

    // Example logging messages with different levels
    ESP_LOGE("DANIEL", "teste mais uma vez");
    ESP_LOGE("TAG", "This is an error message");
    ESP_LOGW("TAG", "This is a warning message");
    ESP_LOGI("TAG", "This is an info message");
    ESP_LOGD("TAG", "This is a debug message");
    ESP_LOGV("TAG", "This is a verbose message");


    pinMode(LED_PIN, OUTPUT);

    pinMode(DI1, OUTPUT);
    pinMode(DI2, OUTPUT);
    pinMode(DI3, OUTPUT);
    pinMode(DI4, OUTPUT);
    pinMode(DI5, OUTPUT);
    pinMode(DI6, OUTPUT);
    
    // Create tasks for each core
    xTaskCreatePinnedToCore(
        blinkTask,        // Task function
        "BlinkTask",      // Task name
        4096,             // Stack size (bytes)
        NULL,             // Parameter to pass
        1,                // Task priority
        &blinkTaskHandle, // Task handle
        CORE_1            // Core to run task on
    );

    xTaskCreatePinnedToCore(
        bleTask,          // Task function
        "BLETask",        // Task name
        4096,             // Stack size (bytes)
        NULL,             // Parameter to pass
        1,                // Task priority
        &bleTaskHandle,   // Task handle
        CORE_0            // Core to run task on
    );

    Serial.println("Both tasks created successfully!");
}

void loop() {
    // Empty loop as tasks handle everything
    digitalWrite(LED_PIN, 1);
    vTaskDelay(1000 / portTICK_PERIOD_MS);
}