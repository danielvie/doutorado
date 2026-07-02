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
#include "helper_common.h"
#include "signal_controller.h"
#include "messaging.pb.h"

#include "helper_matrix.h"

// REQUIRED to read the clock speed
#include "esp_rom_sys.h"
#include "esp_chip_info.h"

#include <stdbool.h>
#include "esp_cpu.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"

static const char *TAG = "BLE_LED";

/* Blink control via State Machine */

void blink_stop_task(void)
{
    ESP_LOGI(TAG, "Stopping blink (State Machine)");
    g_system_state.led_mode.store(LedMode::NORMAL, std::memory_order_release);
}

void blink_create_task() {
    ESP_LOGI(TAG, "Starting blink (State Machine)");
    g_system_state.led_mode.store(LedMode::BLINKING, std::memory_order_release);
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

    // Set initial alpha 0.5
    signal_set_alpha(0.5f);

    // Initialize LED Manager (State + Queue driven)
    led_create_manager_task();

    // create semaphore
    sem_analog_read_trigger = xSemaphoreCreateBinary();
    if (sem_analog_read_trigger == NULL) {
        ESP_LOGE("INIT", "Failed to create semaphore");
    }

    return ret;
}

static void analog_reading_task(void* arg) {
    ESP_LOGI(TAG, "Analog Task Started");

    for (;;) {
        if (ble_is_connected()) {
            AnalogRuntimeStatus analog_status;
            analog_get_status(&analog_status);

            BlePacket packet = BlePacket_init_zero;
            packet.which_payload = BlePacket_telemetry_tag;
            packet.payload.telemetry.an3 = analog_status.calibrated_an3;
            packet.payload.telemetry.an5 = analog_status.calibrated_an5;
            packet.payload.telemetry.an6 = analog_status.calibrated_an6;
            packet.payload.telemetry.timestamp_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;

            ble_send_protobuf(&packet);
        }
        vTaskDelay(pdMS_TO_TICKS(g_analog_monitor_period_ms));
    }
}

extern "C" void app_main(void)
{
    uint32_t cpu_freq_mhz = esp_rom_get_cpu_ticks_per_us();

    esp_chip_info_t chip_info;
    esp_chip_info(&chip_info);

    ESP_LOGW(TAG, "================================================");
    ESP_LOGW(TAG, "  Chip: %s | Rev: %d.%d | Cores: %d",
             CONFIG_IDF_TARGET, chip_info.revision / 100, chip_info.revision % 100, chip_info.cores);
    ESP_LOGW(TAG, "  CPU: %lu MHz | Flash: %s | BLE: %s",
             cpu_freq_mhz,
             (chip_info.features & CHIP_FEATURE_EMB_FLASH) ? "embedded" : "external",
             (chip_info.features & CHIP_FEATURE_BLE) ? "yes" : "no");
    ESP_LOGW(TAG, "================================================");

    esp_err_t ret = app_init();
    if (ret) {
        ESP_LOGW(TAG, "COULD NOT INITIALIZE APP!!");
    } else {
        signal_start_continuous();
    }

    xTaskCreatePinnedToCore(analog_reading_task, "Analog Task", 8192, NULL, tskIDLE_PRIORITY + 1, NULL, 0);
    // The acquisition task produces the control input; keep it above app
    // housekeeping (but below the BLE host) so publishes are not delayed by
    // telemetry work, which would inflate measurement age at the control point.
    xTaskCreatePinnedToCore(analog_acquisition_task, "Analog Acquisition", 4096, NULL, tskIDLE_PRIORITY + 6, NULL, 0);

    matrix_test();

    blink(4);
}
