/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */

#include "ble_controller.h"
#include "helper_note.h"

#include <cstring>
#include <string>
#include <algorithm>

extern "C" {
#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_bt.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
#include "esp_bt_defs.h"
#include "esp_bt_main.h"
#include "esp_bt_device.h"
#include "esp_gatt_common_api.h"
#include "led.h"
}

#define PROFILE_NUM 1
#define LED_PROFILE_APP_ID 0
#define LED_CHAR_UUID_128_LEN 16

/* String UUIDs (canonical big-endian textual form) */
#define SERVICE_UUID_STR        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID_STR           "beb5483e-36e1-4688-b7f5-ea07361b26a8"

static const char *TAG = "BLE_CTRL";

/* Parsed UUID storage (little-endian as expected by esp-idf) */
static uint8_t service_uuid_le[16];
static uint8_t char_uuid_le[16];

static esp_ble_adv_data_t adv_data = {
    .set_scan_rsp = false,
    .include_name = true,
    .include_txpower = false,
    .min_interval = 0x0006,
    .max_interval = 0x0010,
    .appearance = 0x00,
    .manufacturer_len = 0,
    .p_manufacturer_data = NULL,
    .service_data_len = 0,
    .p_service_data = NULL,
    .service_uuid_len = 0, /* will be set after parsing */
    .p_service_uuid = NULL,
    .flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
};

static esp_ble_adv_params_t adv_params = {
    .adv_int_min        = 0x20,
    .adv_int_max        = 0x40,
    .adv_type           = ADV_TYPE_IND,
    .own_addr_type      = BLE_ADDR_TYPE_PUBLIC,
    .peer_addr          = {},
    .peer_addr_type     = BLE_ADDR_TYPE_PUBLIC,
    .channel_map        = ADV_CHNL_ALL,
    .adv_filter_policy  = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
};

struct gatts_profile_inst {
    esp_gatts_cb_t gatts_cb;
    uint16_t gatts_if;
    uint16_t app_id;
    uint16_t conn_id;
    uint16_t service_handle;
    esp_gatt_srvc_id_t service_id;
    uint16_t char_handle;
    esp_bt_uuid_t char_uuid;
};

static struct gatts_profile_inst gl_profile_tab[PROFILE_NUM] = {
    [LED_PROFILE_APP_ID] = {
        .gatts_cb = NULL,
        .gatts_if = ESP_GATT_IF_NONE,
        .app_id = 0,
        .conn_id = 0,
        .service_handle = 0,
        .service_id = {},
        .char_handle = 0,
        .char_uuid = {},
    },
};

/*
 * Parse canonical UUID string (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) into little-endian 16-byte array.
 * Returns true on success, false on parse/validation failure.
 */
static bool uuid_from_string_le(const char *str, uint8_t out[16])
{
    if (!str || !out) return false;
    uint8_t tmp[16];
    int hi = -1; // high nibble accumulator
    int byte_index = 0;
    for (const char *p = str; *p; ++p) {
        char c = *p;
        if (c == '-') continue; // skip hyphens
        int v;
        if (c >= '0' && c <= '9') v = c - '0';
        else if (c >= 'a' && c <= 'f') v = 10 + (c - 'a');
        else if (c >= 'A' && c <= 'F') v = 10 + (c - 'A');
        else return false; // invalid char
        if (hi < 0) {
            hi = v; // store high nibble
        } else {
            if (byte_index >= 16) return false; // too many bytes
            tmp[byte_index++] = (uint8_t)((hi << 4) | v);
            hi = -1; // reset
        }
    }
    if (hi != -1) return false; // dangling high nibble
    if (byte_index != 16) return false; // must have exactly 16 bytes
    // Convert to little-endian ordering expected by esp-idf internal storage
    for (int i = 0; i < 16; ++i) {
        out[i] = tmp[15 - i];
    }
    return true;
}

/* Blink task control - declared here but controlled via BLE commands */
extern TaskHandle_t blink_task_handle;
extern volatile uint16_t blink_delay1_ms;
extern volatile uint16_t blink_delay2_ms;

// Forward declarations from main.cpp
extern void blink_stop_task(void);
extern void blink_create_task(void);

esp_err_t ble_send_message(const char* data, uint16_t len) {
    // check if client is connected
    if (gl_profile_tab[LED_PROFILE_APP_ID].conn_id == 0xFFFF) {
        ESP_LOGW(TAG, "Cannot send message: no client connected");
        return ESP_FAIL;
    }

    // get connection parameters
    uint16_t conn_id = gl_profile_tab[LED_PROFILE_APP_ID].conn_id;
    uint16_t gatts_if = gl_profile_tab[LED_PROFILE_APP_ID].gatts_if;
    uint16_t char_handle = gl_profile_tab[LED_PROFILE_APP_ID].char_handle;

    if (char_handle == 0) {
        ESP_LOGE(TAG, "Cannot send message: characteristic handle not set");
        return ESP_FAIL;
    }
    
    // send message
    esp_err_t ret = esp_ble_gatts_send_indicate(
        gatts_if,
        conn_id,
        char_handle,
        len,
        (uint8_t*)data,
        false
    );
    
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "esp_ble_gatts_send_indicate failed: %s", esp_err_to_name(ret));
    } else {
        ESP_LOGI(TAG, "Sent BLE notification");
    }
    
    return ret;
}

static void example_write_event_env(esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param)
{
    esp_gatt_status_t status = ESP_GATT_OK;
    if (param->write.need_rsp) {
        esp_ble_gatts_send_response(gatts_if, param->write.conn_id, param->write.trans_id, status, NULL);
    }
}

void BLE_router(esp_ble_gatts_cb_param_t *param) {
    if (param->write.len > 0) {

        // read message
        std::string message(reinterpret_cast<const char*>(param->write.value), param->write.len);
        std::string message_lower = message;
        std::transform(message_lower.begin(), message_lower.end(), message_lower.begin(), ::tolower);
        
        // treat cases
        uint16_t blink_d1 = 0, blink_d2 = 0;
        if (sscanf(message_lower.c_str(), "blink:%hu,%hu", &blink_d1, &blink_d2) == 2) {
            if (blink_d1 > 0 && blink_d2 > 0) {
                blink_delay1_ms = blink_d1;
                blink_delay2_ms = blink_d2;
                ESP_LOGI(TAG, "Blink delays set to D1=%u ms, D2=%u ms", blink_d1, blink_d2);
                blink_create_task();
            } else {
                ESP_LOGW(TAG, "Ignoring DELAY command with zero or invalid value.");
            }
        } else if (sscanf(message_lower.c_str(), "blink:%hu", &blink_d1) == 1) {
            if (blink_d1 > 0) {
                blink_delay1_ms = blink_d1;
                ESP_LOGI(TAG, "Blink delay set to %u ms", blink_d1);
                blink_create_task();
            } else {
                ESP_LOGW(TAG, "Ignoring DELAY command with zero value.");
            }
        } else if (message_lower == "blink") {
            ESP_LOGI(TAG, "Start blinking (1s period)");
            blink_create_task();
        } else if (message_lower == "on") {
            ESP_LOGI(TAG, "LED ON!");
            blink_stop_task();
            led_on();
        } else if (message_lower == "off") {
            ESP_LOGI(TAG, "LED OFF!");
            blink_stop_task();
            led_off();
            
            NoteData msg(120);
            note_buffer_clear(msg);
            
            note_buffer_add_text(msg, "\nSTATUS\n");
            note_buffer_add_text(msg, "LED off");
            ble_send_message(msg.buffer, msg.size);

        } else {
            ESP_LOGI(TAG, "Unrecognized write: '%s' (len=%u)", message.c_str(), message.length());
        }
    }
}

static void led_profile_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param)
{
    switch (event) {
    case ESP_GATTS_REG_EVT: {
        ESP_LOGI(TAG, "GATT registered, app_id %d", param->reg.app_id);
        gl_profile_tab[LED_PROFILE_APP_ID].service_id.is_primary = true;
        gl_profile_tab[LED_PROFILE_APP_ID].service_id.id.inst_id = 0x00;
        gl_profile_tab[LED_PROFILE_APP_ID].service_id.id.uuid.len = ESP_UUID_LEN_128;
        /* Parse and set service UUID from string (little-endian for esp-idf) */
        if (!uuid_from_string_le(SERVICE_UUID_STR, service_uuid_le)) {
            ESP_LOGE(TAG, "Failed to parse service UUID string");
            return;
        }
        memcpy(gl_profile_tab[LED_PROFILE_APP_ID].service_id.id.uuid.uuid.uuid128, service_uuid_le, 16);

        /* Inject service UUID into advertising data now that it is parsed */
        adv_data.service_uuid_len = 16;
        adv_data.p_service_uuid = service_uuid_le;

        esp_err_t ret = esp_ble_gap_config_adv_data(&adv_data);
        if (ret) {
            ESP_LOGE(TAG, "config adv data failed: %x", ret);
            break;
        }

        // Allocate enough handles: Service (1) + Char Declaration (1) + Char Value (1) + CCCD (1) => 4. Give a little extra.
        esp_ble_gatts_create_service(gatts_if, &gl_profile_tab[LED_PROFILE_APP_ID].service_id, 5);
        break;
    }
    case ESP_GATTS_CREATE_EVT: {
        ESP_LOGI(TAG, "Service created, handle %d", param->create.service_handle);
        gl_profile_tab[LED_PROFILE_APP_ID].service_handle = param->create.service_handle;

        gl_profile_tab[LED_PROFILE_APP_ID].char_uuid.len = ESP_UUID_LEN_128;
        if (!uuid_from_string_le(CHAR_UUID_STR, char_uuid_le)) {
            ESP_LOGE(TAG, "Failed to parse characteristic UUID string");
            return;
        }
        memcpy(gl_profile_tab[LED_PROFILE_APP_ID].char_uuid.uuid.uuid128, char_uuid_le, 16);

        esp_ble_gatts_start_service(gl_profile_tab[LED_PROFILE_APP_ID].service_handle);

        esp_gatt_char_prop_t property = ESP_GATT_CHAR_PROP_BIT_WRITE | ESP_GATT_CHAR_PROP_BIT_READ | ESP_GATT_CHAR_PROP_BIT_NOTIFY;
        esp_err_t rc = esp_ble_gatts_add_char(gl_profile_tab[LED_PROFILE_APP_ID].service_handle,
                                             &gl_profile_tab[LED_PROFILE_APP_ID].char_uuid,
                                             ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE,
                                             property,
                                             NULL, NULL);
        if (rc) {
            ESP_LOGE(TAG, "add char failed: %x", rc);
        }
        break;
    }
    case ESP_GATTS_ADD_CHAR_EVT: {
        ESP_LOGI(TAG, "Char added, attr_handle %d", param->add_char.attr_handle);
        gl_profile_tab[LED_PROFILE_APP_ID].char_handle = param->add_char.attr_handle;
        // Add Client Characteristic Configuration Descriptor (CCCD) to match NOTIFY property
        esp_bt_uuid_t descr_uuid = {};
        descr_uuid.len = ESP_UUID_LEN_16;
        descr_uuid.uuid.uuid16 = ESP_GATT_UUID_CHAR_CLIENT_CONFIG;
        esp_err_t rd = esp_ble_gatts_add_char_descr(gl_profile_tab[LED_PROFILE_APP_ID].service_handle,
                                                    &descr_uuid,
                                                    ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE,
                                                    NULL, NULL);
        if (rd) {
            ESP_LOGW(TAG, "add cccd failed: %x", rd);
        }
        break;
    }
    case ESP_GATTS_READ_EVT: {
        // Simple readback of current LED state (0/1)
        esp_gatt_rsp_t rsp;
        memset(&rsp, 0, sizeof(rsp));
        rsp.attr_value.handle = param->read.handle;
        rsp.attr_value.len = 1;
        rsp.attr_value.value[0] = get_led_state();
        esp_ble_gatts_send_response(gatts_if, param->read.conn_id, param->read.trans_id, ESP_GATT_OK, &rsp);
        break;
    }
    case ESP_GATTS_WRITE_EVT: {
        ESP_LOGI(TAG, "Write event, len=%u", param->write.len);
        ESP_LOG_BUFFER_HEX(TAG, param->write.value, param->write.len);

        BLE_router(param);

        example_write_event_env(gatts_if, param);
        break;
    }
    case ESP_GATTS_START_EVT:
        ESP_LOGI(TAG, "Service started");
        break;
    case ESP_GATTS_CONNECT_EVT:
        ESP_LOGI(TAG, "Client connected");
        gl_profile_tab[LED_PROFILE_APP_ID].conn_id = param->connect.conn_id;
        break;
    case ESP_GATTS_DISCONNECT_EVT:
        ESP_LOGI(TAG, "Client disconnected - restart advertising");
        esp_ble_gap_start_advertising(&adv_params);
        break;
    default:
        break;
    }
}

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param)
{
    switch (event) {
    case ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT:
        ESP_LOGI(TAG, "adv data set complete, start advertising");
        esp_ble_gap_start_advertising(&adv_params);
        break;
    case ESP_GAP_BLE_SCAN_RSP_DATA_SET_COMPLETE_EVT:
        ESP_LOGI(TAG, "scan resp data set complete, start advertising");
        esp_ble_gap_start_advertising(&adv_params);
        break;
    case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
        if (param->adv_start_cmpl.status != ESP_BT_STATUS_SUCCESS) {
            ESP_LOGE(TAG, "Advertising start failed, status %d", param->adv_start_cmpl.status);
        } else {
            ESP_LOGI(TAG, "Advertising started");
        }
        break;
    default:
        break;
    }
}

static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param)
{
    if (event == ESP_GATTS_REG_EVT) {
        if (param->reg.status == ESP_GATT_OK) {
            gl_profile_tab[param->reg.app_id].gatts_if = gatts_if;
        } else {
            ESP_LOGE(TAG, "Reg app failed, app_id %04x, status %d", param->reg.app_id, param->reg.status);
            return;
        }
    }

    int idx;
    for (idx = 0; idx < PROFILE_NUM; idx++) {
        if (gatts_if == ESP_GATT_IF_NONE || gatts_if == gl_profile_tab[idx].gatts_if) {
            if (gl_profile_tab[idx].gatts_cb) {
                gl_profile_tab[idx].gatts_cb(event, gatts_if, param);
            }
        }
    }
}

esp_err_t ble_controller_init(void) {
    esp_err_t ret;

    // Release memory used by the Classic Bluetooth controller if it was enabled. This is crucial for
    // BLE-only applications to free up resources.
    ESP_ERROR_CHECK(esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT));

    // Initialize the Bluetooth controller with default configuration. This prepares the hardware
    // for Bluetooth operations.
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret) {
        ESP_LOGE(TAG, "initialize controller failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Enable the Bluetooth controller in BLE mode. This makes the controller ready for BLE functionality.
    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret) {
        ESP_LOGE(TAG, "enable controller failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Initialize the Bluedroid stack, which provides the API for BLE host functionality.
    ret = esp_bluedroid_init();
    if (ret) {
        ESP_LOGE(TAG, "init bluetooth failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Enable the Bluedroid stack. This activates the BLE host and makes its services available.
    ret = esp_bluedroid_enable();
    if (ret) {
        ESP_LOGE(TAG, "enable bluetooth failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Register the GAP (Generic Access Profile) callback function. This function handles GAP events
    // such as advertising, scanning, and connection management.
    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret) {
        ESP_LOGE(TAG, "gap register error: %x", ret);
        return ret;
    }

    // Register the GATTS (GATT Server) callback function. This function handles GATT server events
    // such as service creation, characteristic read/write, and descriptor events.
    ret = esp_ble_gatts_register_callback(gatts_event_handler);
    if (ret) {
        ESP_LOGE(TAG, "gatts register error: %x", ret);
        return ret;
    }

    gl_profile_tab[LED_PROFILE_APP_ID].gatts_cb = led_profile_event_handler;

    // Register the GATT server application. This associates the profile callback with an application ID.
    ret = esp_ble_gatts_app_register(LED_PROFILE_APP_ID);
    if (ret) {
        ESP_LOGE(TAG, "app register error: %x", ret);
        return ret;
    }

    // Set the local MTU (Maximum Transmission Unit) for GATT operations. A larger MTU allows
    // for more data to be exchanged in a single transaction.
    ret = esp_ble_gatt_set_local_mtu(500);
    if (ret) {
        ESP_LOGW(TAG, "set local MTU failed: %x", ret);
    }
    
    return ret;
}
