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
#include "driver/adc.h"

#include "ble_controller.h"
#include "signal_controller.h"
#include "helpers.h"
#include "Matrix.h"
#include "MatrixMath.h"

// CPU Core definitions for task assignment
#define CORE_0 0
#define CORE_1 1

// GPIO Pin definitions
#define LED 2                    // Built-in LED for status indication

/**
 * System Setup Function
 * Initializes all hardware and software components:
 * - Serial communication
 * - Signal controller
 * - ADC configuration
 * - GPIO configuration
 * - Watchdog timer
 * - FreeRTOS tasks
 */
void setup() {
    Serial.begin(115200);
    
    // initializing g_gain_k
    g_control_gain_k.m_is_valid = false;
    g_control_gain_k.m_data.reserve(50);
    
    // Initialize signal controller (creates mutex, initializes vectors, configures GPIO)
    initializeSignalController();

    // Configure ADC channels for analog input reading
    adc1_config_width(ADC_WIDTH_BIT_12);  // 12-bit resolution (0-4095)
    adc1_config_channel_atten(ADC1_CHANNEL_0, ADC_ATTEN_DB_12);  // 0-3.3V range
    adc1_config_channel_atten(ADC1_CHANNEL_3, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_6, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_7, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_4, ADC_ATTEN_DB_12);
    adc1_config_channel_atten(ADC1_CHANNEL_5, ADC_ATTEN_DB_12);

    // Configure LED GPIO pin
    pinMode(LED, OUTPUT);
    digitalWrite(LED, LOW);

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


    // testing Matrix.cpp
    // std::string k = "5;3;0.00041624,-0.00041734,-0.000835,0.00083908,0.0008333,0.00084516,-0.00084918,-0.00040503,0.00040617,-0.00081487,0.0095941,-0.0095774,0.0096154,-0.0095994,0.019302;";

    // // Matrix data for performance comparison (5x3 matrix from string k)
    // double matrix_data[15] = {
    //     0.00041624, -0.00041734, -0.000835, 0.00083908, 0.0008333, 0.00084516,
    //     -0.00084918, -0.00040503, 0.00040617, -0.00081487, 0.0095941, -0.0095774,
    //     0.0096154, -0.0095994, 0.019302
    // };
    
    // // Vector B (3x1)
    // double vector_b[3] = {0.6, 0.1, 0.1};
    
    // // Result vector (5x1)
    // double result_matrixmath[5];

    // // Time MatrixMath computation
    // uint64_t start_matrixmath = esp_timer_get_time();
    
    // // Scale matrix by -1.0 (in-place)
    // matrix_scale(5, 3, matrix_data, -1.0);
    
    // // Perform matrix multiplication using MatrixMath
    // bool success = matrix_multiply(5, 3, matrix_data, 3, 1, vector_b, result_matrixmath);
    
    // uint64_t end_matrixmath = esp_timer_get_time();
    // uint64_t duration_matrixmath = end_matrixmath - start_matrixmath;

    // // Time class-based computation
    // Matrix matrix_a = Matrix::from_string(k);
    // Matrix matrix_b(3,1,{0.6, 0.1, 0.1});

    // uint64_t start_time = esp_timer_get_time();
        
    // auto res = matrix_a.scale(-1.0).multiply(matrix_b);
        
    // uint64_t end_time = esp_timer_get_time();
    // uint64_t duration_class = end_time - start_time;
    
    // // Print results for verification
    // Serial.println("=== Matrix Class Results ===");
    // matrix_a.print();
    // res.print();
    
    // Serial.println("=== MatrixMath Results ===");
    // matrix_print(5, 1, result_matrixmath, "Result");
    
    // // Performance comparison
    // Serial.println("=== Performance Comparison ===");
    // Serial.printf("MatrixMath computation: %llu microseconds\n", duration_matrixmath);
    // Serial.printf("Class-based computation: %llu microseconds\n", duration_class);
    // if (duration_matrixmath > 0) {
    //     Serial.printf("Class overhead factor: %.2fx\n", (double)duration_class / duration_matrixmath);
    // }





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
