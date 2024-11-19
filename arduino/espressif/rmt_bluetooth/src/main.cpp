#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <driver/rmt.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

// 
#define LED 2

// Core definitions
#define CORE_0 0  // Protocol core
#define CORE_1 1  // Application core

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// RMT configuration
#define RMT_TX_CHANNEL_21    RMT_CHANNEL_0
#define RMT_TX_CHANNEL_22    RMT_CHANNEL_1
#define RMT_TX_CHANNEL_23    RMT_CHANNEL_2
#define RMT_TX_GPIO_21       21
#define RMT_TX_GPIO_22       22
#define RMT_TX_GPIO_23       23

// Signal states
volatile bool signalsEnabled = false;

// Task handles
TaskHandle_t bleTaskHandle = NULL;
TaskHandle_t rmtTaskHandle = NULL;

// BLE Server callbacks
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        Serial.println("Device connected");
    }
    
    void onDisconnect(BLEServer* pServer) {
        Serial.println("Device disconnected");
        BLEDevice::startAdvertising();
    }
};

// BLE Characteristic callbacks
class CharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *characteristic) {
        std::string value = characteristic->getValue();
        if (value == "START") {
            signalsEnabled = true;
            Serial.println("Signals started");
        } else if (value == "STOP") {
            signalsEnabled = false;
            Serial.println("Signals stopped");
        }
    }
};

// Configure RMT channel
void configureRMTChannel(rmt_channel_t channel, gpio_num_t gpio) {
    rmt_config_t config = RMT_DEFAULT_CONFIG_TX(gpio, channel);
    config.tx_config.carrier_en = false;
    config.tx_config.loop_en = true;
    config.tx_config.idle_output_en = true;
    config.tx_config.idle_level = RMT_IDLE_LEVEL_LOW;
    config.clk_div = 80; // 1 tick = 1 microsecond with 80MHz APB clock

    rmt_config(&config);
    rmt_driver_install(channel, 0, 0);
}

// Create RMT signal items
void createRMTItems(rmt_item32_t* items, uint16_t high1, uint16_t low1, 
                    uint16_t high2, uint16_t low2, uint16_t high3, uint16_t low3) {
    items[0].duration0 = high1;
    items[0].level0 = 1;
    items[0].duration1 = low1;
    items[0].level1 = 0;
    
    items[1].duration0 = high2;
    items[1].level0 = 1;
    items[1].duration1 = low2;
    items[1].level1 = 0;

    items[2].duration0 = high3;
    items[2].level0 = 1;
    items[2].duration1 = low3;
    items[2].level1 = 0;
}

// Task for BLE communication
void bleTask(void* parameter) {
    // Print task core
    Serial.print("BLE Task running on core: ");
    Serial.println(xPortGetCoreID());
    
    // Initialize BLE
    BLEDevice::init("ESP32 Signal Controller");
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    
    BLEService *pService = pServer->createService(SERVICE_UUID);
    BLECharacteristic *pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE
    );
    
    pCharacteristic->setCallbacks(new CharacteristicCallbacks());
    pCharacteristic->setValue("Hello");
    pService->start();
    
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
    
    while(1) {
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// Task for RMT signal generation
void rmtTask(void* parameter) {
    // Print task core
    Serial.print("RMT Task running on core: ");
    Serial.println(xPortGetCoreID());
    
    // Configure RMT channels
    configureRMTChannel(RMT_TX_CHANNEL_21, (gpio_num_t)RMT_TX_GPIO_21);
    configureRMTChannel(RMT_TX_CHANNEL_22, (gpio_num_t)RMT_TX_GPIO_22);
    configureRMTChannel(RMT_TX_CHANNEL_23, (gpio_num_t)RMT_TX_GPIO_23);
    
    // Create RMT items for each signal
    rmt_item32_t items21[3];
    rmt_item32_t items22[3];
    rmt_item32_t items23[3];
    
    createRMTItems(items21, 5, 10, 5, 15, 20, 30);  // Signal for GPIO 21
    createRMTItems(items22, 10, 10, 5, 15, 20, 30); // Signal for GPIO 22
    createRMTItems(items23, 50, 10, 5, 15, 20, 30); // Signal for GPIO 23
    
    while(1) {
        if (signalsEnabled) {
            rmt_write_items(RMT_TX_CHANNEL_21, items21, 3, true);
            rmt_write_items(RMT_TX_CHANNEL_22, items22, 3, true);
            rmt_write_items(RMT_TX_CHANNEL_23, items23, 3, true);
        }
        vTaskDelay(pdMS_TO_TICKS(1)); // Small delay to prevent watchdog triggers
    }
}

void setup() {
    Serial.begin(115200);
    
    pinMode(LED, OUTPUT);
    
    // Create FreeRTOS tasks on specific cores
    xTaskCreatePinnedToCore(
        bleTask,        // Task function
        "BLE Task",     // Task name
        4096,           // Stack size (bytes)
        NULL,           // Parameter
        1,              // Priority
        &bleTaskHandle, // Task handle
        CORE_0          // Core ID (Protocol core)
    );
    
    xTaskCreatePinnedToCore(
        rmtTask,
        "RMT Task",
        4096,
        NULL,
        1,
        &rmtTaskHandle,
        CORE_1      // Core ID (Application core)
    );
    
    vTaskDelay(pdMS_TO_TICKS(1000));
    digitalWrite(LED, HIGH);
}

void loop() {
    // Empty as we're using FreeRTOS tasks
    vTaskDelete(NULL);
}