#include <Arduino.h>
#include <NimBLEDevice.h>
#include <NimBLEServer.h>
#include "helpers.h"

// Pin definitions
#define LED_PIN 2
#define CORE_0 0  // Communication core
#define CORE_1 1  // LED control core

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Shared variables between cores
bool deviceConnected = false;
bool isBlinking = false;
int blinkInterval = 500;

// time and mode variables
bool signalIsRunning = false;
std::vector<int32_t> timeValues;
std::vector<int32_t> modeValues;

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
            Serial.print("\nReceived command: ");
            Serial.println(value.c_str());
            
            portENTER_CRITICAL(&mux);
            if (value == "START") {
                isBlinking = true;
                Serial.println("LED Blinking Started");
            }
            else if (value == "STOP") {
                isBlinking = false;
                digitalWrite(LED_PIN, LOW);
                Serial.println("LED Blinking Stopped");
            }
            else if (value.substr(0, 8) == "INTERVAL") {
                String intervalStr = String(value.c_str()).substring(9);
                blinkInterval = intervalStr.toInt();
                Serial.printf("Blink interval set to: %d ms\n", blinkInterval);
            }
            else if (value == "SIGNAL_ON") {
                signalIsRunning = true;
                Serial.printf("value received: `%s` signalIsRunning: %d\n", value.c_str(), signalIsRunning);
            }
            else if (value == "SIGNAL_OFF") {
                signalIsRunning = false;
                Serial.printf("value received: `%s` signalIsRunning: %d\n", value.c_str(), signalIsRunning);
            }
            else if (value.substr(0, 6) == "SIGNAL") {
                String signal = String(value.c_str()).substring(7);
                Serial.printf("signal received: `%s`\n", signal.c_str());
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
        std::vector<int32_t> currentTimeValues;
        std::vector<int32_t> currentModeValues;
        
        // Safely read shared variables
        portENTER_CRITICAL(&mux);
        shouldBlink = isBlinking;
        shouldRunSignal = signalIsRunning;
        currentInterval = blinkInterval;
        portEXIT_CRITICAL(&mux);
        
        if (shouldRunSignal) {
            auto start = std::chrono::high_resolution_clock::now();

        }
        else if (shouldBlink) {
            ledState = !ledState;
            digitalWrite(LED_PIN, ledState);
            vTaskDelay(currentInterval / portTICK_PERIOD_MS);
        } else {
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
    blink_n(5);

    // Keep the task alive
    while(true) {
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}

// .. setup
void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    
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
    vTaskDelay(1000 / portTICK_PERIOD_MS);
}