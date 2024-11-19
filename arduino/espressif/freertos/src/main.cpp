// src/main.cpp
#include <Arduino.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

// Wave pattern structure
struct WaveTiming {
    uint32_t highTime;  // microseconds HIGH
    uint32_t lowTime;   // microseconds LOW
};

// Pin configuration structure
struct PinConfig {
    uint8_t pin;
    WaveTiming pattern[3];  // Fixed size array for each pattern
};

// Create static configurations for each pin
static PinConfig PIN_21 = {
    21,
    {{5, 5}, {10, 10}, {15, 15}}
};

static PinConfig PIN_22 = {
    22,
    {{50, 50}, {100, 100}, {150, 150}}
};

static PinConfig PIN_23 = {
    23,
    {{50, 50}, {75, 75}, {100, 100}}
};

// Task handles
TaskHandle_t taskHandle21 = NULL;
TaskHandle_t taskHandle22 = NULL;
TaskHandle_t taskHandle23 = NULL;

void IRAM_ATTR waveGeneratorTask(void* pvParameters) {
    PinConfig* config = (PinConfig*)pvParameters;
    const uint8_t pin = config->pin;
    
    Serial.printf("Starting pin %d\n", pin);
    
    // Initialize time tracking
    TickType_t lastWakeTime = xTaskGetTickCount();
    uint64_t nextMicroTime = esp_timer_get_time();
    
    // Configure GPIO
    gpio_set_direction(static_cast<gpio_num_t>(pin), GPIO_MODE_OUTPUT);
    gpio_set_level(static_cast<gpio_num_t>(pin), 0);
    
    size_t patternIndex = 0;
    
    while (1) {
        const WaveTiming& currentTiming = config->pattern[patternIndex];
        
        // Set output HIGH
        gpio_set_level(static_cast<gpio_num_t>(pin), 1);
        
        // Calculate next wake time for HIGH period
        nextMicroTime += currentTiming.highTime;
        
        // Wait for HIGH period
        if (currentTiming.highTime > 50) {
            vTaskDelayUntil(&lastWakeTime, pdMS_TO_TICKS(currentTiming.highTime / 1000));
        } else {
            while (esp_timer_get_time() < nextMicroTime) {
                // Tight loop for short delays
            }
        }
        
        // Set output LOW
        gpio_set_level(static_cast<gpio_num_t>(pin), 0);
        
        // Calculate next wake time for LOW period
        nextMicroTime += currentTiming.lowTime;
        
        // Check for timing drift
        int64_t drift = nextMicroTime - esp_timer_get_time();
        if (drift < -1000) {  // Allow small drift before resetting
            nextMicroTime = esp_timer_get_time();
        }
        
        // Wait for LOW period
        if (currentTiming.lowTime > 50) {
            vTaskDelayUntil(&lastWakeTime, pdMS_TO_TICKS(currentTiming.lowTime / 1000));
        } else {
            while (esp_timer_get_time() < nextMicroTime) {
                // Tight loop for short delays
            }
        }
        
        // Move to next pattern
        patternIndex = (patternIndex + 1) % 3;
    }
}

// Function to calculate and print timing info
void printTimingInfo(const char* label, const PinConfig& config) {
    uint32_t totalPeriod = 0;
    Serial.printf("\n%s (GPIO%d):\n", label, config.pin);
    for (int i = 0; i < 3; i++) {
        Serial.printf("  Cycle %d: UP=%dµs, DOWN=%dµs\n",
            i + 1,
            config.pattern[i].highTime,
            config.pattern[i].lowTime
        );
        totalPeriod += config.pattern[i].highTime + config.pattern[i].lowTime;
    }
    Serial.printf("  Total Period: %d microseconds\n", totalPeriod);
    Serial.printf("  Frequency: %.2f Hz\n", 1000000.0f / totalPeriod);
}

void setup() {
    Serial.begin(115200);
    while(!Serial);

    Serial.println("\nMulti-Pin Wave Pattern Generator Started");

    // Configure pins
    pinMode(PIN_21.pin, OUTPUT);
    pinMode(PIN_22.pin, OUTPUT);
    pinMode(PIN_23.pin, OUTPUT);
    
    // Print configurations
    printTimingInfo("Fast Pattern", PIN_21);
    printTimingInfo("Slow Pattern", PIN_22);
    printTimingInfo("Medium Pattern", PIN_23);

    // Create tasks for each pin with static configurations
    xTaskCreatePinnedToCore(
        waveGeneratorTask,
        "Wave_GPIO21",
        2048,
        &PIN_21,
        configMAX_PRIORITIES - 1,
        &taskHandle21,
        1
    );

    xTaskCreatePinnedToCore(
        waveGeneratorTask,
        "Wave_GPIO22",
        2048,
        &PIN_22,
        configMAX_PRIORITIES - 1,
        &taskHandle22,
        1
    );

    xTaskCreatePinnedToCore(
        waveGeneratorTask,
        "Wave_GPIO23",
        2048,
        &PIN_23,
        configMAX_PRIORITIES - 1,
        &taskHandle23,
        1
    );

    Serial.println("\nAll tasks started!");
}

void loop() {
    // Main loop stays empty
    vTaskDelay(pdMS_TO_TICKS(1000));
}