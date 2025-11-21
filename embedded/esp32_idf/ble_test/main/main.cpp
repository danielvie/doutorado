/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */
/*
 * Minimal BLE GATT example for LED ON/OFF control
 * Keeps only the code necessary to expose a writable BLE characteristic
 * that accepts ASCII "ON" / "OFF" (case-insensitive) or a single byte 0x01/0x00.
 * 
 * Now in C++
 */

#include <cstdio>
#include <cstring>

#include "helper_note.h"
#include "ble_controller.h"
#include "signal_controller.h"

extern "C" {
#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "led.h"
}

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
    
    
    NoteData msg(120);
    note_buffer_clear(msg);
    
    note_buffer_add_text(msg, "\nSTATUS\n");
    note_buffer_add_text_f(msg, "blink: %d, %d\n", blink_delay1_ms, blink_delay2_ms);

    ble_send_message(msg.buffer, msg.size);
}

esp_err_t app_init() {
    esp_err_t ret;

    led_init();
    
    // initialize signal controller GPIOs
    signal_controller_init();

    // Initialize NVS (Non-Volatile Storage) for storing system parameters
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


extern "C" void app_main(void)
{

    // --------------------------------------------------------
    // CHECK CLOCK SPEED
    // --------------------------------------------------------
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
    
    NoteData message_buffer(120);
    note_buffer_clear(message_buffer);
    note_buffer_add_text(message_buffer, "\nSTATUS\n testing hier");
    note_buffer_print_info(message_buffer);
}
