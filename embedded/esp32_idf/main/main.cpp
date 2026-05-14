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
#include "esp_adc/adc_continuous.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "soc/soc_caps.h"

static const char *TAG = "BLE_LED";

#define ADC_CONTINUOUS_FRAME_TRIPLES 16
#define ADC_CONTINUOUS_FRAME_SIZE (SOC_ADC_DIGI_RESULT_BYTES * 3 * ADC_CONTINUOUS_FRAME_TRIPLES)
#define ADC_CONTINUOUS_STORE_SIZE (ADC_CONTINUOUS_FRAME_SIZE * 4)

#if (SOC_ADC_DIGI_RESULT_BYTES == 2)
#define ADC_CONTINUOUS_OUTPUT_FORMAT ADC_DIGI_OUTPUT_FORMAT_TYPE1
#define ADC_CONTINUOUS_GET_CHANNEL(sample) ((sample)->type1.channel)
#define ADC_CONTINUOUS_GET_DATA(sample) ((sample)->type1.data)
#else
#define ADC_CONTINUOUS_OUTPUT_FORMAT ADC_DIGI_OUTPUT_FORMAT_TYPE2
#define ADC_CONTINUOUS_GET_CHANNEL(sample) ((sample)->type2.channel)
#define ADC_CONTINUOUS_GET_DATA(sample) ((sample)->type2.data)
#endif

static adc_continuous_handle_t s_adc_continuous_handle = NULL;
static bool s_adc_continuous_started = false;
static uint32_t s_adc_continuous_sample_hz = 0;

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

static void analog_publish_compat(uint32_t raw_an3, float an3,
                                  uint32_t raw_an5, float an5,
                                  uint32_t raw_an6, float an6,
                                  bool valid) {
    analog_publish_triple(raw_an3, an3, raw_an5, an5, raw_an6, an6, valid);

    g_adc_an3.store(an3, std::memory_order_release);
    g_adc_an5.store(an5, std::memory_order_release);
    g_adc_an6.store(an6, std::memory_order_release);
    g_adc_fresh.store(valid, std::memory_order_release);
    g_system_state.ble_an_read_state.store(BLEAnalogReadState::IDLE, std::memory_order_release);
}

static void analog_continuous_stop() {
    if (s_adc_continuous_handle == NULL) {
        s_adc_continuous_started = false;
        s_adc_continuous_sample_hz = 0;
        return;
    }

    if (s_adc_continuous_started) {
        adc_continuous_stop(s_adc_continuous_handle);
        s_adc_continuous_started = false;
    }

    adc_continuous_deinit(s_adc_continuous_handle);
    s_adc_continuous_handle = NULL;
    s_adc_continuous_sample_hz = 0;
}

static bool analog_continuous_start(uint32_t sample_hz) {
    if (s_adc_continuous_started && s_adc_continuous_sample_hz == sample_hz) {
        return true;
    }

    analog_continuous_stop();

    adc_continuous_handle_cfg_t handle_config = {};
    handle_config.max_store_buf_size = ADC_CONTINUOUS_STORE_SIZE;
    handle_config.conv_frame_size = ADC_CONTINUOUS_FRAME_SIZE;
    handle_config.flags.flush_pool = 1;

    esp_err_t ret = adc_continuous_new_handle(&handle_config, &s_adc_continuous_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "ADC continuous handle init failed: %s", esp_err_to_name(ret));
        s_adc_continuous_handle = NULL;
        return false;
    }

    adc_digi_pattern_config_t pattern[3] = {};
    pattern[0].atten = ADC_ATTEN_DB_12;
    pattern[0].channel = ADC_CHANNEL_4;
    pattern[0].unit = ADC_UNIT_1;
    pattern[0].bit_width = SOC_ADC_DIGI_MAX_BITWIDTH;
    pattern[1].atten = ADC_ATTEN_DB_12;
    pattern[1].channel = ADC_CHANNEL_6;
    pattern[1].unit = ADC_UNIT_1;
    pattern[1].bit_width = SOC_ADC_DIGI_MAX_BITWIDTH;
    pattern[2].atten = ADC_ATTEN_DB_12;
    pattern[2].channel = ADC_CHANNEL_0;
    pattern[2].unit = ADC_UNIT_1;
    pattern[2].bit_width = SOC_ADC_DIGI_MAX_BITWIDTH;

    adc_continuous_config_t adc_config = {};
    adc_config.pattern_num = 3;
    adc_config.adc_pattern = pattern;
    adc_config.sample_freq_hz = sample_hz;
    adc_config.conv_mode = ADC_CONV_SINGLE_UNIT_1;
    adc_config.format = ADC_CONTINUOUS_OUTPUT_FORMAT;

    ret = adc_continuous_config(s_adc_continuous_handle, &adc_config);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "ADC continuous config failed: %s", esp_err_to_name(ret));
        analog_continuous_stop();
        return false;
    }

    ret = adc_continuous_start(s_adc_continuous_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "ADC continuous start failed: %s", esp_err_to_name(ret));
        analog_continuous_stop();
        return false;
    }

    s_adc_continuous_started = true;
    s_adc_continuous_sample_hz = sample_hz;
    ESP_LOGI(TAG, "ADC continuous started at %lu samples/s", sample_hz);
    return true;
}

struct AnalogTripleAccumulator {
    uint32_t raw_an3 = 0;
    uint32_t raw_an5 = 0;
    uint32_t raw_an6 = 0;
    bool has_an3 = false;
    bool has_an5 = false;
    bool has_an6 = false;
};

static void analog_continuous_accept_sample(AnalogTripleAccumulator* acc, uint32_t channel, uint32_t raw) {
    switch (channel) {
    case ADC_CHANNEL_4:
        acc->raw_an3 = raw;
        acc->has_an3 = true;
        break;
    case ADC_CHANNEL_6:
        acc->raw_an5 = raw;
        acc->has_an5 = true;
        break;
    case ADC_CHANNEL_0:
        acc->raw_an6 = raw;
        acc->has_an6 = true;
        break;
    default:
        return;
    }

    if (acc->has_an3 && acc->has_an5 && acc->has_an6) {
        analog_publish_compat(acc->raw_an3, analog_calibrate_raw(acc->raw_an3),
                              acc->raw_an5, analog_calibrate_raw(acc->raw_an5),
                              acc->raw_an6, analog_calibrate_raw(acc->raw_an6),
                              true);
        acc->has_an3 = false;
        acc->has_an5 = false;
        acc->has_an6 = false;
    }
}

static void analog_oneshot_step() {
    float an3, an5, an6;
    uint32_t raw_an3, raw_an5, raw_an6;

    uint32_t start = esp_cpu_get_cycle_count();
    bool valid = analog_read_port_sample(AnalogPort::AN3, &raw_an3, &an3);
    valid = analog_read_port_sample(AnalogPort::AN5, &raw_an5, &an5) && valid;
    valid = analog_read_port_sample(AnalogPort::AN6, &raw_an6, &an6) && valid;
    uint32_t end = esp_cpu_get_cycle_count();
    analog_record_latency((end - start) / esp_rom_get_cpu_ticks_per_us());
    analog_publish_compat(raw_an3, an3, raw_an5, an5, raw_an6, an6, valid);

    uint32_t period_us = g_analog_acquisition_period_us;
    if (period_us >= 1000) {
        vTaskDelay(pdMS_TO_TICKS((period_us + 999) / 1000));
    } else if (period_us > 0) {
        esp_rom_delay_us(period_us);
    } else {
        taskYIELD();
    }
}

static void analog_continuous_step(AnalogTripleAccumulator* acc) {
    uint32_t sample_hz = g_analog_continuous_sample_hz;
    if (!analog_continuous_start(sample_hz)) {
        analog_record_overflow();
        g_analog_acquisition_mode = ANALOG_ACQ_MODE_ONESHOT;
        vTaskDelay(pdMS_TO_TICKS(100));
        return;
    }

    uint8_t frame[ADC_CONTINUOUS_FRAME_SIZE];
    uint32_t out_len = 0;
    uint32_t start = esp_cpu_get_cycle_count();
    esp_err_t ret = adc_continuous_read(s_adc_continuous_handle, frame, sizeof(frame), &out_len, 20);
    uint32_t end = esp_cpu_get_cycle_count();

    if (ret == ESP_ERR_TIMEOUT) {
        return;
    }
    if (ret != ESP_OK) {
        analog_record_overflow();
        if (ret == ESP_ERR_INVALID_STATE) {
            adc_continuous_flush_pool(s_adc_continuous_handle);
        } else {
            ESP_LOGW(TAG, "ADC continuous read failed: %s", esp_err_to_name(ret));
        }
        return;
    }

    analog_record_latency((end - start) / esp_rom_get_cpu_ticks_per_us());
    for (uint32_t i = 0; i + SOC_ADC_DIGI_RESULT_BYTES <= out_len; i += SOC_ADC_DIGI_RESULT_BYTES) {
        adc_digi_output_data_t* sample = reinterpret_cast<adc_digi_output_data_t*>(&frame[i]);
        analog_continuous_accept_sample(acc, ADC_CONTINUOUS_GET_CHANNEL(sample), ADC_CONTINUOUS_GET_DATA(sample));
    }
}

static void analog_action_task(void* arg) {
    ESP_LOGI(TAG, "Analog Background Acquisition Task Started");
    AnalogTripleAccumulator acc;

    for (;;) {
        if (g_analog_acquisition_mode == ANALOG_ACQ_MODE_CONTINUOUS) {
            analog_continuous_step(&acc);
        } else {
            analog_continuous_stop();
            analog_oneshot_step();
        }
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
    }

    xTaskCreatePinnedToCore(analog_reading_task, "Analog Task", 8192, NULL, tskIDLE_PRIORITY + 1, NULL, 0);
    xTaskCreatePinnedToCore(analog_action_task, "Analog Acquisition", 4096, NULL, tskIDLE_PRIORITY, NULL, 0);

    matrix_test();

    blink(4);
}
