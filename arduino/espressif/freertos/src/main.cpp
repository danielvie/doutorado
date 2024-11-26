#include <Arduino.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/timer.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

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
volatile bool signalsEnabled = false;

// Convert microseconds to CPU ticks
#define US_TO_TICKS(us) ((us) * CPU_FREQ_MHZ)

// Timing sequence in microseconds
const uint32_t timings[] = {
    75,  // duration 1
    18,  // duration 2
    75,  // duration 3
    18,  // duration 4
    75,  // duration 5
    18,  // duration 6
};

const uint32_t modes_di6[] = {
    1, 0, 1, 1, 1, 0,
};

const uint32_t modes_di5[] = {
    0, 1, 1, 0, 1, 1,
};

const uint32_t modes_di4[] = {
    0, 0, 0, 1, 1, 1,
};

// Number of elements in the timing sequence
const uint8_t NUM_TIMINGS = sizeof(timings) / sizeof(timings[0]);

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
            digitalWrite(LED, HIGH);
        } else if (value == "STOP") {
            signalsEnabled = false;
            Serial.println("Signals stopped");
            digitalWrite(LED, LOW);
        }
    }
};

// Task for BLE communication
void bleTask(void* parameter) {
    Serial.print("BLE Task running on core: ");
    Serial.println(xPortGetCoreID());
    
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


void IRAM_ATTR generateSignal(void* arg) {
    uint8_t state = 0;
    uint64_t startTicks;
    
    // Ts (us):
    //  0   74.6667   93.3333  168.0000  186.6667  261.3333  280.0000
    // 
    // dTs (us):
    //  74.6667   18.6667   74.6667   18.6667   74.6667   18.6667
    //  74.6   18.6   74.6   18.6   74.6   18.6
    // modes:
    //     4      2      6      5      7      3
    //
    //     1      0      1      1      1      0 : di6
    //     0      1      1      0      1      1 : di5
    //     0      0      0      1      1      1 : di4

    // Precalculate GPIO bit masks for faster manipulation
    const uint32_t gpio_di4_mask = 1 << GPIO_DI4;
    const uint32_t gpio_di5_mask = 1 << GPIO_DI5;
    const uint32_t gpio_di6_mask = 1 << GPIO_DI6;

    // mi6
    // 75; high
    // 18; low
    // 75+18+75=168; high
    // 18; low

    // mi5
    // 75; low
    // 18+75=93; high
    // 18; low
    // 75+18=93; high

    // mi4
    // 75+18+75=168; low
    // 18+75+18=111; high

    while (1) {
        startTicks = esp_timer_get_time() * CPU_FREQ_MHZ;  // Current time in CPU ticks
        
        // Set pin state (even indices are HIGH, odd are LOW)
        // mi4 = modes_di4[state];
        // mi5 = modes_di5[state];
        // mi6 = modes_di6[state];
        // digitalWrite(GPIO_DI4, (state % 2 == 0) ? HIGH : LOW);
        // digitalWrite(GPIO_DI4, mi4);
        // digitalWrite(GPIO_DI5, mi5);
        // digitalWrite(GPIO_DI6, mi6);

        if (!signalsEnabled)
        {
            GPIO.out_w1tc = (1 << LED) | (1 << GPIO_DI4) | (1 << GPIO_DI5) | (1 << GPIO_DI6);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        // Fast GPIO manipulation using direct register access
        if (modes_di4[state]) {
            GPIO.out_w1ts = gpio_di4_mask;  // Set pin HIGH
        } else {
            GPIO.out_w1tc = gpio_di4_mask;  // Set pin LOW
        }
        
        if (modes_di5[state]) {
            GPIO.out_w1ts = gpio_di5_mask;  // Set pin HIGH
        } else {
            GPIO.out_w1tc = gpio_di5_mask;  // Set pin LOW
        }
        
        if (modes_di6[state]) {
            GPIO.out_w1ts = gpio_di6_mask;  // Set pin HIGH
        } else {
            GPIO.out_w1tc = gpio_di6_mask;  // Set pin LOW
        }
        

        // Wait for precise duration using CPU ticks
        while ((esp_timer_get_time() * CPU_FREQ_MHZ) - startTicks < US_TO_TICKS(timings[state])) {
            // Tight loop for precise timing
            // We don't yield here to maintain timing accuracy
        }
        
        // Move to next state
        state = (state + 1) % NUM_TIMINGS;
    }
}

void setup() {
    // Configure signal pin
    pinMode(LED, OUTPUT);
    pinMode(GPIO_DI4, OUTPUT);
    pinMode(GPIO_DI5, OUTPUT);
    pinMode(GPIO_DI6, OUTPUT);

    // Initial low state using direct register access
    GPIO.out_w1tc = (1 << LED) | (1 << GPIO_DI4) | (1 << GPIO_DI5) | (1 << GPIO_DI6);
    
    xTaskCreatePinnedToCore(
        bleTask,
        "BLE Task",
        4096,
        NULL,
        1,
        NULL,
        CORE_0
    );
    
    // Create signal generation task with high priority
    xTaskCreatePinnedToCore(
        generateSignal,           // Task function
        "SignalGenerator",        // Task name
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