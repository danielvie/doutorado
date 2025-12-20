/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */

#include "ble_controller.h"

#define PROFILE_NUM 1
#define PROFILE_APP_ID 0

/* String UUIDs (canonical big-endian textual form) */
#define SERVICE_UUID_STR "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID_STR "beb5483e-36e1-4688-b7f5-ea07361b26a8"

static const char* TAG = "BLE_CTRL";

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
    .service_uuid_len = 0,
    .p_service_uuid = NULL,
    .flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT),
};

static esp_ble_adv_params_t adv_params = {
    .adv_int_min = 0x20,
    .adv_int_max = 0x40,
    .adv_type = ADV_TYPE_IND,
    .own_addr_type = BLE_ADDR_TYPE_PUBLIC,
    .peer_addr = {},
    .peer_addr_type = BLE_ADDR_TYPE_PUBLIC,
    .channel_map = ADV_CHNL_ALL,
    .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
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
    [PROFILE_APP_ID] = {
        .gatts_cb = NULL,
        .gatts_if = ESP_GATT_IF_NONE,
        .app_id = 0,
        .conn_id = 0xFFFF,
        .service_handle = 0,
        .service_id = {},
        .char_handle = 0,
        .char_uuid = {},
    },
};

static bool uuid_from_string_le(const char* str, uint8_t out[16]) {
    if (!str || !out) return false;
    uint8_t tmp[16];
    int hi = -1;
    int byte_index = 0;
    for (const char* p = str; *p; ++p) {
        char c = *p;
        if (c == '-') continue;
        int v;
        if (c >= '0' && c <= '9')
            v = c - '0';
        else if (c >= 'a' && c <= 'f')
            v = 10 + (c - 'a');
        else if (c >= 'A' && c <= 'F')
            v = 10 + (c - 'A');
        else
            return false;
        if (hi < 0) {
            hi = v;
        } else {
            if (byte_index >= 16) return false;
            tmp[byte_index++] = (uint8_t)((hi << 4) | v);
            hi = -1;
        }
    }
    if (hi != -1) return false;
    if (byte_index != 16) return false;
    for (int i = 0; i < 16; ++i) {
        out[i] = tmp[15 - i];
    }
    return true;
}

extern TaskHandle_t blink_task_handle;
extern volatile uint16_t blink_delay1_ms;
extern volatile uint16_t blink_delay2_ms;

extern void blink_stop_task(void);
extern void blink_create_task(void);

esp_err_t ble_send_message(const char* data, uint16_t len, BLEMode mode) {
    if (gl_profile_tab[PROFILE_APP_ID].conn_id == 0xFFFF) {
        ESP_LOGW(TAG, "Cannot send message: no client connected");
        return ESP_FAIL;
    }

    uint16_t conn_id = gl_profile_tab[PROFILE_APP_ID].conn_id;
    uint16_t gatts_if = gl_profile_tab[PROFILE_APP_ID].gatts_if;
    uint16_t char_handle = gl_profile_tab[PROFILE_APP_ID].char_handle;

    if (char_handle == 0) {
        ESP_LOGE(TAG, "Cannot send message: characteristic handle not set");
        return ESP_FAIL;
    }

    esp_err_t ret = esp_ble_gatts_send_indicate(
        gatts_if,
        conn_id,
        char_handle,
        len,
        (uint8_t*)data,
        false);

    if (mode == BLEMode::VERBOSE) {
        if (ret != ESP_OK) {
            ESP_LOGE(TAG, "esp_ble_gatts_send_indicate failed: %s", esp_err_to_name(ret));
        } else {
            ESP_LOGI(TAG, "Sent BLE notification");
        }
    }

    return ret;
}

static void example_write_event_env(esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t* param) {
    esp_gatt_status_t status = ESP_GATT_OK;
    if (param->write.need_rsp) {
        esp_ble_gatts_send_response(gatts_if, param->write.conn_id, param->write.trans_id, status, NULL);
    }
}

// ----------------------------------------------------------------------
// UPDATED BLE ROUTER
// ----------------------------------------------------------------------
void ble_router(esp_ble_gatts_cb_param_t* param) {
    if (param->write.len > 0) {
        auto msg = std::make_unique<NoteData>(120);

        // read message
        std::string message(reinterpret_cast<const char*>(param->write.value), param->write.len);
        std::string message_lower = message;
        std::transform(message_lower.begin(), message_lower.end(), message_lower.begin(), ::tolower);

        // treat cases
        uint16_t blink_d1 = 0, blink_d2 = 0;
        if (sscanf(message_lower.c_str(), "blink:%hu,%hu", &blink_d1, &blink_d2) == 2) {
            ble_router_blink_nn(blink_d1, blink_d2);
        } else if (sscanf(message_lower.c_str(), "blink:%hu", &blink_d1) == 1) {
            ble_router_blink_n(blink_d1);
        } else if (message_lower == "blink") {
            ble_router_blink();
        } else if (sscanf(message_lower.c_str(), "port:%hu,%hu", &blink_d1, &blink_d2) == 2) {
            uint16_t port = blink_d1;
            uint16_t value = blink_d2;
            ble_router_set_port(port, value);
        } else if (sscanf(message_lower.c_str(), "cycles:%lu", &g_cycle_nrun) == 1) {
            ESP_LOGI(TAG, "Setting `g_cycle_nrun= %d`", g_cycle_nrun);
        } else if (sscanf(message_lower.c_str(), "us_delay:%lu", &g_cycle_us_delay_up) == 1) {
            g_cycle_us_delay_down = g_cycle_us_delay_up;
            ESP_LOGI(TAG, "Setting `g_cycle_us_delay_up= %d`", g_cycle_us_delay_up);
            ESP_LOGI(TAG, "Setting `g_cycle_us_delay_down= %d`", g_cycle_us_delay_down);
        } else if (sscanf(message_lower.c_str(), "us_delay_up:%lu", &g_cycle_us_delay_up) == 1) {
            ESP_LOGI(TAG, "Setting `g_cycle_us_delay_up= %d`", g_cycle_us_delay_up);
        } else if (sscanf(message_lower.c_str(), "us_delay_down:%lu", &g_cycle_us_delay_down) == 1) {
            ESP_LOGI(TAG, "Setting `g_cycle_us_delay_down= %d`", g_cycle_us_delay_down);
        } else if (sscanf(message_lower.c_str(), "an_monitor_ms:%lu", &g_analog_monitor_period_ms) == 1) {
            ESP_LOGI(TAG, "Setting `g_analog_monitor_period_ms = %d`", g_analog_monitor_period_ms);
        } else if (message_lower == "on") {
            ble_router_led_on(msg);
        } else if (message_lower == "off") {
            ble_router_led_off(msg);
        } else if (message_lower == "read") {
            ble_router_read(msg);
        } else if (message_lower == "active_dataset") {
            ble_router_print_active_dataset();
        } else if (message.substr(0, 7) == "SIGNAL:") {
            auto payload = message.substr(7);
            ble_router_set_signal(payload);
        } else if (message.substr(0, 10) == "SET_ALPHA:") {
            auto payload = message.substr(10);
            ble_router_message_set_alpha(payload);
        } else if (message_lower == "status_matrix_a") {
            ble_router_status_matrix(SignalSet::SET_A);
        } else if (message_lower == "status_matrix_b") {
            ble_router_status_matrix(SignalSet::SET_B);
        } else if (message_lower == "status") {
            ble_router_status();
        } else if (message_lower == "log_duration") {
            ble_router_log_duration();
        } else if (message_lower == "ble_read_on") {
            ble_router_ble_read(Status::ON);
        } else if (message_lower == "ble_read_off") {
            ble_router_ble_read(Status::OFF);
        } else if (message_lower == "start") {
            ble_router_signal_start();
        } else if (message_lower == "stop") {
            ble_router_signal_stop();
        } else {
            ESP_LOGI(TAG, "Unrecognized write: '%s' (len=%u)", message.c_str(), message.length());
        }
    }
}

void ble_router_blink_nn(uint16_t blink_d1, uint16_t blink_d2) {
    // blink:%hu,%hu
    if (blink_d1 > 0 && blink_d2 > 0) {
        blink_delay1_ms = blink_d1;
        blink_delay2_ms = blink_d2;
        ESP_LOGI(TAG, "Blink delays set to D1=%u ms, D2=%u ms", blink_d1, blink_d2);
        blink_create_task();
    }
}

void ble_router_blink_n(uint16_t blink_d1) {
    if (blink_d1 > 0) {
        blink_delay1_ms = blink_d1;
        ESP_LOGI(TAG, "Blink delay set to %u ms", blink_d1);
        blink_create_task();
    }
}

void ble_router_blink(void) {
    ESP_LOGI(TAG, "Start blinking (1s period)");
    blink_create_task();
}

void ble_router_led_on(std::unique_ptr<NoteData>& msg) {
    ESP_LOGI(TAG, "LED ON!");
    blink_stop_task();
    led_on();

    note_clear(*msg);
    note_add_text(*msg, "\nSTATUS\n");
    note_add_text(*msg, "LED::ON");

    note_ble_send(*msg);
}

void ble_router_led_off(std::unique_ptr<NoteData>& msg) {
    ESP_LOGI(TAG, "LED OFF!");
    blink_stop_task();
    led_off();

    note_clear(*msg);
    note_add_text(*msg, "\nSTATUS\n");
    note_add_text(*msg, "LED::OFF");

    note_ble_send(*msg);
}

void ble_router_read(std::unique_ptr<NoteData>& msg) {
    float an3 = analog_read_port(AnalogPort::AN3);
    float an5 = analog_read_port(AnalogPort::AN5);
    float an6 = analog_read_port(AnalogPort::AN6);

    note_clear(*msg);
    note_add_text(*msg, "\nSTATUS\n");
    note_add_text(*msg, "an3: %.4f\nan5: %.4f\nan6: %.4f\n", an3, an5, an6);

    note_logi(*msg, TAG);
    note_ble_send(*msg);
}

void ble_router_set_signal(std::string& message) {
    ESP_LOGI(TAG, "Updating Signal Pattern via Double Buffer...");
    signal_update_from_string(message);

    // ESP_GATT_MAX_ATTR_LEN

    auto msg = std::make_unique<NoteData>(120);
    note_clear(*msg);
    note_add_text(*msg, "SIGNAL UPDATED OK");

    note_ble_send(*msg);
}

void ble_router_set_port(uint16_t port, uint16_t value) {
    ESP_LOGI(TAG, "Setting %d to port %d", value, port);

    switch(port) {
        case 6:
            gpio_set_level(PIN_OUT_6, value);
            break;
        case 5:
            gpio_set_level(PIN_OUT_5, value);
            break;
        case 4:
            gpio_set_level(PIN_OUT_4, value);
            break;
        case 3:
            gpio_set_level(PIN_OUT_6_, value);
            break;
        case 2:
            gpio_set_level(PIN_OUT_5_, value);
            break;
        case 1:
            gpio_set_level(PIN_OUT_4_, value);
            break;
        default:
            ESP_LOGE(TAG, "could not find a valid config");
            break;
    }


    // auto msg = std::make_unique<NoteData>(120);
    // note_clear(*msg);
    // note_add_text(*msg, "SIGNAL UPDATED OK");

    // note_ble_send(*msg);
}

void ble_router_print_active_dataset(void) {
    // (message_lower == "active_dataset")
    auto msg = std::make_unique<NoteData>(NOTE_BLE_BUFFER_SIZE);
    
    DataSet* ds = get_dataset_active();

    note_add_text(*msg, "\nSTATUS\n");
    note_add_text(*msg, "== active dataset (%s) == \n", get_label(g_active_set).c_str());
    note_add_array_u32(*msg, "time", ds->time_durations, ds->size);
    note_add_array_u32(*msg, "d4  ", ds->modes_d4, ds->size);
    note_add_array_u32(*msg, "d5  ", ds->modes_d5, ds->size);
    note_add_array_u32(*msg, "d6  ", ds->modes_d6, ds->size);
    
    note_logi(*msg, TAG);
    note_ble_send(*msg);
}

void ble_router_message_set_alpha(std::string& message) {

    // get set that is not active
    DataSet *dataset;
    
    if (g_active_set == SignalSet::SET_A) {
        dataset = &g_dataset_b;
    } else {
        dataset = &g_dataset_a;
    }
    
    // set data based on alpha
    float alpha = std::stof(message);
    
    ESP_LOGI(TAG, "set_alpha(%.2f)", alpha);
    helper_set_dataset_from_alpha(dataset, alpha);
    
    g_ds_update_pending = true; // mark for set update
}

void ble_router_status(void) {
    // status_matrix_a
    
    auto msg = std::make_unique<NoteData>(NOTE_BLE_BUFFER_SIZE);
    
    // DataSet* ds = get_dataset_active();
    
    auto is_valid = [](DataSet& ds_) {
        return matrix_isvalid(ds_.gain_k) ? std::string("valid") : std::string("not valid");
    };
    
    note_add_text(*msg, "\nSTATUS\n");
    note_add_text(*msg, "\n== status ==\n");
    note_add_text(*msg, "active         : %s\n", get_label(g_active_set).c_str());
    note_add_text(*msg, "matrix a       : %s\n", is_valid(g_dataset_a).c_str());
    note_add_text(*msg, "matrix b       : %s\n", is_valid(g_dataset_b).c_str());
    note_add_text(*msg, "signal state   : %s\n", get_label(g_system_state.signal_state).c_str());
    note_add_text(*msg, "ble state      : %s\n", get_label(g_system_state.ble_an_read_state).c_str());
    note_add_text(*msg, "cycles         : %d of %d\n", g_cycle_count, g_cycle_nrun);
    note_add_text(*msg, "g_an_monitor_ms: %d\n", g_analog_monitor_period_ms);
    note_add_text(*msg, "us cycles up   : %d\n", g_cycle_us_delay_up);
    note_add_text(*msg, "us cycles down : %d\n", g_cycle_us_delay_down);

    note_logi(*msg, TAG);
    note_ble_send(*msg);
}

void ble_router_status_matrix(SignalSet set) {
    // status_matrix_a
    
    auto msg = std::make_unique<NoteData>(NOTE_BLE_BUFFER_SIZE);
    
    DataSet* ds;
    if (set == SignalSet::SET_A) {
       ds = &g_dataset_a;
    } else {
       ds = &g_dataset_b;
    }
    
    note_add_text(*msg, "\nSTATUS\n");
    note_add_text(*msg, "\n== status matrix %s ==\n", get_label(set).c_str());
    note_add_matrix(*msg, ds->gain_k);

    note_logi(*msg, TAG);
    note_ble_send(*msg);
}

void ble_router_log_duration(void) {
    auto msg = std::make_unique<NoteData>(NOTE_BLE_BUFFER_SIZE);
    
    note_add_text(*msg, "\nSTATUS time duration:\n\n");
    note_add_text(*msg, "read and send   : %d us\n", g_log_duration.read_and_send_analog_us);
    note_add_text(*msg, "matrix multiply : %d us\n", g_log_duration.matrix_multiply_us);
    note_add_text(*msg, "dtk condition   : %d us\n", g_log_duration.dtk_condition);
    note_add_text(*msg, "update dtk sig  : %d us\n", g_log_duration.update_signal_with_dtk);
    
    note_ble_send(*msg);
    ESP_LOGI(TAG, "%s", msg->buffer);
}

void ble_router_ble_read(Status status) {
    switch (status)
    {
    case Status::ON:
        g_system_state.ble_an_read_state = BLEAnalogReadState::IDLE;
        break;
    case Status::OFF:
        g_system_state.ble_an_read_state = BLEAnalogReadState::DISABLED;
        break;
    }
}

void ble_router_signal_start() {
    // start
    signal_start_continuous();
}

void ble_router_signal_stop() {
    // stop
    signal_stop();
}

static void profile_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t* param) {
    switch (event) {
        case ESP_GATTS_REG_EVT: {
            ESP_LOGI(TAG, "GATT registered, app_id %d", param->reg.app_id);
            gl_profile_tab[PROFILE_APP_ID].service_id.is_primary = true;
            gl_profile_tab[PROFILE_APP_ID].service_id.id.inst_id = 0x00;
            gl_profile_tab[PROFILE_APP_ID].service_id.id.uuid.len = ESP_UUID_LEN_128;

            if (!uuid_from_string_le(SERVICE_UUID_STR, service_uuid_le)) {
                ESP_LOGE(TAG, "Failed to parse service UUID string");
                return;
            }
            memcpy(gl_profile_tab[PROFILE_APP_ID].service_id.id.uuid.uuid.uuid128, service_uuid_le, 16);

            adv_data.service_uuid_len = 16;
            adv_data.p_service_uuid = service_uuid_le;

            esp_err_t ret = esp_ble_gap_config_adv_data(&adv_data);
            if (ret) {
                ESP_LOGE(TAG, "config adv data failed: %x", ret);
                break;
            }

            esp_ble_gatts_create_service(gatts_if, &gl_profile_tab[PROFILE_APP_ID].service_id, 5);
            break;
        }
        case ESP_GATTS_CREATE_EVT: {
            ESP_LOGI(TAG, "Service created, handle %d", param->create.service_handle);
            gl_profile_tab[PROFILE_APP_ID].service_handle = param->create.service_handle;

            gl_profile_tab[PROFILE_APP_ID].char_uuid.len = ESP_UUID_LEN_128;
            if (!uuid_from_string_le(CHAR_UUID_STR, char_uuid_le)) {
                ESP_LOGE(TAG, "Failed to parse characteristic UUID string");
                return;
            }
            memcpy(gl_profile_tab[PROFILE_APP_ID].char_uuid.uuid.uuid128, char_uuid_le, 16);

            esp_ble_gatts_start_service(gl_profile_tab[PROFILE_APP_ID].service_handle);

            esp_gatt_char_prop_t property = ESP_GATT_CHAR_PROP_BIT_WRITE | ESP_GATT_CHAR_PROP_BIT_READ | ESP_GATT_CHAR_PROP_BIT_NOTIFY;
            esp_err_t rc = esp_ble_gatts_add_char(gl_profile_tab[PROFILE_APP_ID].service_handle,
                                                  &gl_profile_tab[PROFILE_APP_ID].char_uuid,
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
            gl_profile_tab[PROFILE_APP_ID].char_handle = param->add_char.attr_handle;

            esp_bt_uuid_t descr_uuid = {};
            descr_uuid.len = ESP_UUID_LEN_16;
            descr_uuid.uuid.uuid16 = ESP_GATT_UUID_CHAR_CLIENT_CONFIG;
            esp_err_t rd = esp_ble_gatts_add_char_descr(gl_profile_tab[PROFILE_APP_ID].service_handle,
                                                        &descr_uuid,
                                                        ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE,
                                                        NULL, NULL);
            if (rd) {
                ESP_LOGW(TAG, "add cccd failed: %x", rd);
            }
            break;
        }
        case ESP_GATTS_READ_EVT: {
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
            ble_router(param);
            example_write_event_env(gatts_if, param);
            break;
        }
        case ESP_GATTS_START_EVT:
            ESP_LOGI(TAG, "Service started");
            break;
        case ESP_GATTS_CONNECT_EVT:
            ESP_LOGI(TAG, "Client connected");
            blink(3);
            gl_profile_tab[PROFILE_APP_ID].conn_id = param->connect.conn_id;
            break;
        case ESP_GATTS_DISCONNECT_EVT:
            blink(2);
            ESP_LOGI(TAG, "Client disconnected - restart advertising");
            gl_profile_tab[PROFILE_APP_ID].conn_id = 0xFFFF;
            esp_ble_gap_start_advertising(&adv_params);
            break;
        default:
            break;
    }
}

static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t* param) {
    switch (event) {
        case ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT:
            esp_ble_gap_start_advertising(&adv_params);
            break;
        case ESP_GAP_BLE_SCAN_RSP_DATA_SET_COMPLETE_EVT:
            esp_ble_gap_start_advertising(&adv_params);
            break;
        case ESP_GAP_BLE_ADV_START_COMPLETE_EVT:
            if (param->adv_start_cmpl.status != ESP_BT_STATUS_SUCCESS) {
                ESP_LOGE(TAG, "Advertising start failed");
            }
            break;
        default:
            break;
    }
}

static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t* param) {
    if (event == ESP_GATTS_REG_EVT) {
        if (param->reg.status == ESP_GATT_OK) {
            gl_profile_tab[param->reg.app_id].gatts_if = gatts_if;
        } else {
            ESP_LOGE(TAG, "Reg app failed");
            return;
        }
    }

    for (int idx = 0; idx < PROFILE_NUM; idx++) {
        if (gatts_if == ESP_GATT_IF_NONE || gatts_if == gl_profile_tab[idx].gatts_if) {
            if (gl_profile_tab[idx].gatts_cb) {
                gl_profile_tab[idx].gatts_cb(event, gatts_if, param);
            }
        }
    }
}

esp_err_t ble_controller_init(void) {
    esp_err_t ret;
    ESP_ERROR_CHECK(esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT));
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    ret = esp_bt_controller_init(&bt_cfg);
    if (ret) return ret;
    ret = esp_bt_controller_enable(ESP_BT_MODE_BLE);
    if (ret) return ret;
    ret = esp_bluedroid_init();
    if (ret) return ret;
    ret = esp_bluedroid_enable();
    if (ret) return ret;
    ret = esp_ble_gap_register_callback(gap_event_handler);
    if (ret) return ret;
    ret = esp_ble_gatts_register_callback(gatts_event_handler);
    if (ret) return ret;
    gl_profile_tab[PROFILE_APP_ID].gatts_cb = profile_event_handler;
    ret = esp_ble_gatts_app_register(PROFILE_APP_ID);
    if (ret) return ret;
    ret = esp_ble_gatt_set_local_mtu(500);
    return ret;
}

bool ble_is_connected() {
    return (gl_profile_tab[PROFILE_APP_ID].conn_id != 0xFFFF);
}