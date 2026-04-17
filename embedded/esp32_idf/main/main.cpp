/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */

#include <cstdio>
#include <cstring>
#include <memory>

#include "ble_controller.h"
// #include "esp_log_level.h"
#include "helper_analog.h"
#include "helper_note.h"
#include "helper_led.h"
#include "helper_common.h"
#include "signal_controller.h"

#include "helper_matrix.h"

// REQUIRED to read the clock speed
#include "esp_rom_sys.h"

#include <stdbool.h>
// #include "freertos/FreeRTOS.h"
#include "freertos/task.h"
// #include "esp_system.h"
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

static void blink_task(void* arg)
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
    note_clear(*msg);
    note_add_text(*msg, "\nSTATUS\n");
    note_add_text(*msg, "LED::BLINK %d, %d\n", blink_delay1_ms, blink_delay2_ms);
    note_ble_send(*msg);
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
        ESP_LOGE("INIT", "BLE controller init failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // create semaphore
    sem_analog_read_trigger = xSemaphoreCreateBinary();
    if (sem_analog_read_trigger == NULL) {
        ESP_LOGE("INIT", "Failed to create semaphore");
    }

    return ret;
}

static void analog_reading_task(void* arg) {
    ESP_LOGI(TAG, "Analog Task Started");

    float an3, an5, an6;
    for (;;) {

        // only send message if client is connected
        if (ble_is_connected()) {
            // Read Values (in V)
            an3 = analog_read_port(AnalogPort::AN3);
            an5 = analog_read_port(AnalogPort::AN5);
            an6 = analog_read_port(AnalogPort::AN6);

            // Prepare BLE Message
            auto msg = std::make_unique<NoteData>(128);
            note_clear(*msg);

            // Format: "an3:1.2345 an5:0.0123 an6:3.1000"
            note_add_text(*msg, "an3:%.4f an5:%.4f an6:%.4f", an3, an5, an6);

            // Send
            note_ble_send(*msg, BLEMode::SILENT);
        }

        // Wait 500ms
        vTaskDelay(pdMS_TO_TICKS(g_analog_monitor_period_ms));
    }
    vTaskDelete(NULL);
}

static void analog_action_task(void* arg) {
    ESP_LOGI(TAG, "Analog Action Task Started");
    float an3, an5, an6;

    for (;;) {
        if (xSemaphoreTake(sem_analog_read_trigger, portMAX_DELAY) == pdPASS) {
            ESP_LOGI("AnalogRead", "New data Received!");

            an3 = analog_read_port(AnalogPort::AN3);
            an5 = analog_read_port(AnalogPort::AN5);
            an6 = analog_read_port(AnalogPort::AN6);

            ESP_LOGI("AnalogRead", "  -> an3: %f, an5: %f, an6: %f\n", an3, an5, an6);

            // Store readings for control loop (Core 1)
            g_adc_an3 = an3;
            g_adc_an5 = an5;
            g_adc_an6 = an6;
            g_adc_fresh = true;

            g_system_state.ble_an_read_state = BLEAnalogReadState::IDLE;
        }
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

    ESP_LOGE("mijn test", "ik ben hier, u haaaa");
    ESP_LOGE("mijn test", "ik ben hier, u haaaa");


    // Create analog task on Core 0 with sufficient stack size for helper::printf
    xTaskCreatePinnedToCore(
        analog_reading_task,  // Task function
        "Analog Task",        // Task name (corrected name)
        8192,                  // Stack size (bytes) - increased for helper::printf
        NULL,                 // Task parameter
        tskIDLE_PRIORITY + 1, // Priority
        NULL,                 // Task handle
        CORE_0                // CPU core
    );

    // task to receive command for ble readings
    xTaskCreatePinnedToCore(
        analog_action_task,   // Task function
        "Analog Action Task", // Task name (corrected name)
        4096,                 // Stack size (bytes) - increased for helper::printf
        NULL,                 // Task parameter
        tskIDLE_PRIORITY + 1, // Priority
        NULL,                 // Task handle
        CORE_0                // CPU core
    );

    matrix_test();

    blink(4);
}
