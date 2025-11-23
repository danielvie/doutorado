/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */

#include <cstdio>
#include <cstring>
#include <memory>

#include "ble_controller.h"
#include "helper_analog.h"
#include "helper_note.h"
#include "helper_led.h"
#include "signal_controller.h" 



// REQUIRED to read the clock speed
#include "esp_rom_sys.h" 

#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"
#include "nvs_flash.h"

static const char *TAG = "BLE_LED";

/* Blink task control */
TaskHandle_t blink_task_handle = NULL;
volatile uint16_t blink_delay1_ms = 200;
volatile uint16_t blink_delay2_ms = 500;

void blink_stop_task(void)
{
    if (blink_task_handle) {
        vTaskDelete(blink_task_handle);
        blink_task_handle = NULL;
    }
}

static void blink_task(void *arg)
{
    (void)arg;
    for (;;) {
        led_on();
        vTaskDelay(pdMS_TO_TICKS(blink_delay1_ms));
        led_off();
        vTaskDelay(pdMS_TO_TICKS(blink_delay1_ms));
        led_on();
        vTaskDelay(pdMS_TO_TICKS(blink_delay1_ms));
        led_off();
        vTaskDelay(pdMS_TO_TICKS(blink_delay2_ms));
    }
    vTaskDelete(NULL);
}

void blink_create_task() {
    ESP_LOGI(TAG, "blink_create_task [in]");
    if (!blink_task_handle) {
        BaseType_t r = xTaskCreate(blink_task, "blink_task", 2048, NULL, 5, &blink_task_handle);
        if (r != pdPASS) {
            ESP_LOGE(TAG, "Failed to create blink task");
            blink_task_handle = NULL;
        }
    }
    
    auto msg = std::make_unique<NoteData>(120);
    note_buffer_clear(*msg);
    note_buffer_add_text_f(*msg, "\nSTATUS\n");
    note_buffer_add_text_f(*msg, "LED::BLINK %d, %d\n", blink_delay1_ms, blink_delay2_ms);
    note_buffer_ble_send(*msg);
}

esp_err_t app_init() {
    esp_err_t ret;

    led_init();
    
    // initialize analog ports (ADC)
    analog_init();

    // Initialize Signal Controller GPIOs & Test Pattern
    signal_controller_init();

    // Initialize NVS
    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Initialize BLE controller
    ret = ble_controller_init();
    if (ret) {
        ESP_LOGE(TAG, "BLE controller init failed: %s", esp_err_to_name(ret));
        return ret;
    }
    
    return ret;
}

static void analog_reading_task(void* arg) {
    ESP_LOGI(TAG, "Analog Task Started");

    for (;;) {

        // only send message if client is connected
        if (ble_is_connected()) {
            // Read Values (in V)
            float an3 = analog_read_port(AnalogPort::AN3);
            float an5 = analog_read_port(AnalogPort::AN5);
            float an6 = analog_read_port(AnalogPort::AN6);

            // Prepare BLE Message
            auto msg = std::make_unique<NoteData>(128);
            note_buffer_clear(*msg);

            // Format: "an3:1.2345 an5:0.0123 an6:3.1000"
            note_buffer_add_text_f(*msg, "an3:%.4f an5:%.4f an6:%.4f", an3, an5, an6);

            // Send
            // ble_send_message(msg->buffer, msg->size);
            note_buffer_ble_send(*msg, BLEMode::SILENT);
        }

        // Wait 500ms
        vTaskDelay(pdMS_TO_TICKS(500));
    }
    vTaskDelete(NULL);
}

extern "C" void app_main(void)
{
    // print clock speed
    uint32_t cpu_freq_mhz = esp_rom_get_cpu_ticks_per_us();
    
    ESP_LOGW(TAG, "================================================");
    ESP_LOGW(TAG, "           CPU FREQUENCY: %lu MHz", cpu_freq_mhz);
    ESP_LOGW(TAG, "================================================");
    
    if (cpu_freq_mhz < 240) {
        ESP_LOGE(TAG, "WARNING: ESP32 is running SLOW (%lu MHz).", cpu_freq_mhz);
        ESP_LOGE(TAG, "Please run 'idf.py menuconfig' -> Component config -> ESP System Settings -> CPU frequency -> 240 MHz");
    }

    // init functions of the app
    esp_err_t ret = app_init();
    if (ret) {
        ESP_LOGW(TAG, "COULD NOT INITIALIZE APP!!");
    }


    // Create analog task on Core 0 with sufficient stack size for helper::printf
    xTaskCreatePinnedToCore(
        analog_reading_task,  // Task function
        "Analog Task",        // Task name (corrected name)
        8192,                  // Stack size (bytes) - increased for helper::printf
        NULL,                 // Task parameter
        tskIDLE_PRIORITY + 1, // Priority
        NULL,                 // Task handle
        0                     // CPU core
    );

}