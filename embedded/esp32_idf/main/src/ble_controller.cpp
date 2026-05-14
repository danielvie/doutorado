/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */

#include "ble_controller.h"

#include <atomic>
#include <cmath>
#include "ota_controller.h"
#include "ui_command_router.h"

// Nanopb
#include <pb_encode.h>
#include <pb_decode.h>
#include "messaging.pb.h"

#define PROFILE_NUM 1
#define PROFILE_APP_ID 0

/* String UUIDs (canonical big-endian textual form) */
#define SERVICE_UUID_STR "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID_STR "beb5483e-36e1-4688-b7f5-ea07361b26a8"

static const char* TAG = "BLE_CTRL";
static uint16_t g_negotiated_mtu = 23; // BLE default until exchange completes
static volatile bool g_ble_congested = false; // TX queue backpressure flag

// Command queue for offloading ble_router from BLE callback
struct BleCommand {
    uint8_t data[1024];
    uint16_t len;
};
static QueueHandle_t s_cmd_queue = NULL;

static void ble_command_task(void* arg) {
    BleCommand cmd;
    for (;;) {
        if (xQueueReceive(s_cmd_queue, &cmd, portMAX_DELAY) == pdPASS) {
            // Synthesize minimal param for ble_router
            esp_ble_gatts_cb_param_t fake_param = {};
            fake_param.write.len = cmd.len;
            fake_param.write.value = cmd.data;
            ble_router(&fake_param);
        }
    }
}

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
    std::atomic<uint16_t> conn_id;
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
        .conn_id = ATOMIC_VAR_INIT(0xFFFF),
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

static esp_err_t ble_send_message_internal(const char* data, uint16_t len, BLEMode mode, bool critical) {
    if (gl_profile_tab[PROFILE_APP_ID].conn_id == 0xFFFF) {
        ESP_LOGW(TAG, "Cannot send message: no client connected");
        return ESP_FAIL;
    }

    // Drop packet if TX queue is backed up (prevents transport delay)
    if (g_ble_congested && !critical) {
        return ESP_ERR_NO_MEM;
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

esp_err_t ble_send_message(const char* data, uint16_t len, BLEMode mode) {
    return ble_send_message_internal(data, len, mode, false);
}

esp_err_t ble_send_message_critical(const char* data, uint16_t len, BLEMode mode) {
    return ble_send_message_internal(data, len, mode, true);
}

static esp_err_t ble_send_protobuf_internal(const BlePacket* packet, bool critical) {
    if (!ble_is_connected()) return ESP_FAIL;

    uint8_t buffer[500];
    buffer[0] = 0x01; // Binary prefix

    pb_ostream_t stream = pb_ostream_from_buffer(buffer + 1, sizeof(buffer) - 1);
    bool status = pb_encode(&stream, BlePacket_fields, packet);

    if (!status) {
        ESP_LOGE(TAG, "Encoding failed: %s", PB_GET_ERROR(&stream));
        return ESP_FAIL;
    }

    if (critical) {
        return ble_send_message_critical((const char*)buffer, stream.bytes_written + 1, BLEMode::SILENT);
    }

    return ble_send_message((const char*)buffer, stream.bytes_written + 1, BLEMode::SILENT);
}

esp_err_t ble_send_protobuf(const BlePacket* packet) {
    return ble_send_protobuf_internal(packet, false);
}

esp_err_t ble_send_protobuf_critical(const BlePacket* packet) {
    return ble_send_protobuf_internal(packet, true);
}

esp_err_t ble_send_log(BleLogLevel level, const char* text) {
    BlePacket packet = BlePacket_init_zero;
    packet.which_payload = BlePacket_log_tag;
    packet.payload.log.level = level;
    
    // strncpy doesn't guarantee null termination if limit reached
    size_t text_size = sizeof(packet.payload.log.text);
    strncpy(packet.payload.log.text, text, text_size - 1);
    packet.payload.log.text[text_size - 1] = '\0';
    
    return ble_send_protobuf(&packet);
}

static void example_write_event_env(esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t* param) {
    esp_gatt_status_t status = ESP_GATT_OK;
    if (param->write.need_rsp) {
        esp_ble_gatts_send_response(gatts_if, param->write.conn_id, param->write.trans_id, status, NULL);
    }
}

void ble_router(esp_ble_gatts_cb_param_t* param) {
    if (param->write.len > 0) {
        // 1. Check for binary prefix 0x02 (OtaCommand Protobuf)
        if (param->write.value[0] == 0x02) {
            OtaCommand ota_cmd = OtaCommand_init_zero;
            pb_istream_t stream = pb_istream_from_buffer(param->write.value + 1, param->write.len - 1);
            if (pb_decode(&stream, OtaCommand_fields, &ota_cmd)) {
                ota_controller_handle_command(&ota_cmd);
            } else {
                ESP_LOGE(TAG, "Failed to decode OtaCommand: %s", PB_GET_ERROR(&stream));
            }
            return;
        }

        // 2. Check for binary prefix 0x03 (UiCommand Protobuf)
        if (param->write.value[0] == 0x03) {
            UiCommand command = UiCommand_init_zero;
            pb_istream_t stream = pb_istream_from_buffer(param->write.value + 1, param->write.len - 1);
            BlePacket result_packet = BlePacket_init_zero;

            if (pb_decode(&stream, UiCommand_fields, &command)) {
                ESP_LOGI(TAG, "UI command: %s", command.name);
                UiCommandResultData result = ble_ui_command_dispatch(command);
                ble_ui_command_fill_result_packet(&result_packet, command, result);
            } else {
                ESP_LOGE(TAG, "Failed to decode UiCommand: %s", PB_GET_ERROR(&stream));
                UiCommand failed_command = UiCommand_init_zero;
                UiCommandResultData result = {
                    .ok = false,
                    .code = "decode_error",
                    .message = PB_GET_ERROR(&stream),
                    .json = "",
                };
                ble_ui_command_fill_result_packet(&result_packet, failed_command, result);
            }

            ble_send_protobuf(&result_packet);
            return;
        }
        ESP_LOGW(TAG, "Rejected write with unsupported binary prefix 0x%02x", param->write.value[0]);
    }
}

void ble_send_analog_read(void) {
    AnalogRuntimeStatus analog_status;
    analog_get_status(&analog_status);

    BlePacket packet = BlePacket_init_zero;
    packet.which_payload = BlePacket_telemetry_tag;
    packet.payload.telemetry.an3 = analog_status.calibrated_an3;
    packet.payload.telemetry.an5 = analog_status.calibrated_an5;
    packet.payload.telemetry.an6 = analog_status.calibrated_an6;
    packet.payload.telemetry.timestamp_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;

    ble_send_protobuf(&packet);
    
    ESP_LOGI(TAG,
             "Manual Read Snapshot - seq: %lu, valid: %d, an3: %.4f, an5: %.4f, an6: %.4f",
             analog_status.seq,
             analog_status.valid,
             analog_status.calibrated_an3,
             analog_status.calibrated_an5,
             analog_status.calibrated_an6);
}

void ble_send_dataset(DataSet *ds, SignalSet set) {
    auto msg = std::make_unique<NoteData>(NOTE_BLE_BUFFER_SIZE);

    note_add_text(*msg, "\nSTATUS\n");
    note_add_text(*msg, "== active dataset (%s) == \n", get_label(set).c_str());
    note_add_array_u32(*msg, "time", ds->time_durations, ds->size);
    note_add_array_u32(*msg, "d4  ", ds->modes_d4, ds->size);
    note_add_array_u32(*msg, "d5  ", ds->modes_d5, ds->size);
    note_add_array_u32(*msg, "d6  ", ds->modes_d6, ds->size);

    note_logi(*msg, TAG);
    note_ble_send(*msg);
}

void ble_send_status(void) {
    BlePacket packet = BlePacket_init_zero;
    packet.which_payload = BlePacket_status_tag;
    
    SystemStatus* status = &packet.payload.status;
    DataSet* active_ds = get_dataset_active();

    // Map Enums
    status->active_set = (g_active_set == SignalSet::SET_A) ? BleSignalSet_BLE_SET_A : BleSignalSet_BLE_SET_B;
    status->signal_state = (g_system_state.signal_state.load(std::memory_order_acquire) == SignalState::IDLE) ? BleSignalState_BLE_SIG_IDLE : BleSignalState_BLE_SIG_RUNNING;
    
    BLEAnalogReadState read_s = g_system_state.ble_an_read_state.load(std::memory_order_acquire);
    if (read_s == BLEAnalogReadState::IDLE) status->ble_read_state = BleAnalogReadState_BLE_READ_IDLE;
    else if (read_s == BLEAnalogReadState::READING) status->ble_read_state = BleAnalogReadState_BLE_READING;
    else status->ble_read_state = BleAnalogReadState_BLE_READ_DISABLED;

    status->control_state = (g_system_state.control_state.load(std::memory_order_acquire) == ControlState::OFF) ? BleControlState_BLE_CTRL_OFF : BleControlState_BLE_CTRL_ON;

    // Data values
    if (!std::isnan(active_ds->alpha)) {
        status->alpha = active_ds->alpha;
        status->has_alpha = true;
    } else {
        status->has_alpha = false;
    }

    status->matrix_a_valid = matrix_isvalid(g_dataset_a.gain_k);
    status->matrix_b_valid = matrix_isvalid(g_dataset_b.gain_k);
    
    status->current_cycles = g_cycle_count;
    status->total_cycles = g_cycle_nrun;
    status->monitor_ms = g_analog_monitor_period_ms;
    status->dead_time_us = g_dead_time_us;
    status->dead_time_tail_overhead_cycles = g_dead_time_tail_overhead_cycles;
    status->led_mode = (g_system_state.led_mode.load(std::memory_order_acquire) == LedMode::NORMAL) ? BleLedMode_LED_NORMAL : BleLedMode_LED_BLINKING;
    status->ble_congested = g_ble_congested;

    uint32_t a_min, a_max, a_avg;
    analog_get_latency_stats(&a_min, &a_max, &a_avg);
    status->adc_min = a_min;
    status->adc_max = a_max;
    status->adc_avg = a_avg;

    AnalogRuntimeStatus analog_status;
    analog_get_status(&analog_status);
    status->has_analog = true;
    status->analog.seq = analog_status.seq;
    status->analog.valid = analog_status.valid;
    status->analog.timestamp_us = analog_status.timestamp_us;
    status->analog.age_us = analog_status.age_us;
    status->analog.target_triples_per_cycle = analog_status.target_triples_per_cycle;
    status->analog.measured_triples_per_second = analog_status.measured_triples_per_second;
    status->analog.raw_an3 = analog_status.raw_an3;
    status->analog.raw_an5 = analog_status.raw_an5;
    status->analog.raw_an6 = analog_status.raw_an6;
    status->analog.calibrated_an3 = analog_status.calibrated_an3;
    status->analog.calibrated_an5 = analog_status.calibrated_an5;
    status->analog.calibrated_an6 = analog_status.calibrated_an6;
    status->analog.latency_min_us = analog_status.latency_min_us;
    status->analog.latency_avg_us = analog_status.latency_avg_us;
    status->analog.latency_p95_us = analog_status.latency_p95_us;
    status->analog.latency_max_us = analog_status.latency_max_us;
    status->analog.overflow_count = analog_status.overflow_count;
    status->analog.miss_count = analog_status.miss_count;
    status->analog.consecutive_misses = analog_status.consecutive_misses;
    status->analog.fault_code = analog_status.fault_code;

    ble_send_protobuf(&packet);
    
    // For now, keep the console log for serial debugging
    ESP_LOGI(TAG, "Sent binary STATUS update");
}

void ble_send_status_matrix(SignalSet set) {
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

void ble_send_log_duration(void) {
    auto msg = std::make_unique<NoteData>(NOTE_BLE_BUFFER_SIZE);

    note_add_text(*msg, "\nSTATUS time duration:\n\n");
    note_add_text(*msg, "read and send   : %d us\n", g_log_duration.read_and_send_analog_us);
    note_add_text(*msg, "matrix multiply : %d us\n", g_log_duration.matrix_multiply_us);
    note_add_text(*msg, "dtk condition   : %d us\n", g_log_duration.dtk_condition);
    note_add_text(*msg, "update dtk sig  : %d us\n", g_log_duration.update_signal_with_dtk);

    note_ble_send(*msg);
    ESP_LOGI(TAG, "%s", msg->buffer);
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

        esp_attr_value_t char_val = {
            .attr_max_len = 600,
            .attr_len     = 0,
            .attr_value   = NULL,
        };

        esp_gatt_char_prop_t property =
            ESP_GATT_CHAR_PROP_BIT_WRITE |
            ESP_GATT_CHAR_PROP_BIT_WRITE_NR |
            ESP_GATT_CHAR_PROP_BIT_READ |
            ESP_GATT_CHAR_PROP_BIT_NOTIFY;
        esp_err_t rc = esp_ble_gatts_add_char(gl_profile_tab[PROFILE_APP_ID].service_handle,
            &gl_profile_tab[PROFILE_APP_ID].char_uuid,
            ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE,
            property,
            &char_val, NULL);
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
        rsp.attr_value.value[0] = led_get_desired_state() ? 1 : 0;
        esp_ble_gatts_send_response(gatts_if, param->read.conn_id, param->read.trans_id, ESP_GATT_OK, &rsp);
        break;
    }
    case ESP_GATTS_WRITE_EVT: {
        ESP_LOGI(TAG, "Write event, len=%u, need_rsp=%d, is_prep=%d",
            param->write.len,
            param->write.need_rsp,
            param->write.is_prep);
        // ACK immediately, process command asynchronously
        example_write_event_env(gatts_if, param);

        // Queue command for processing outside BLE callback
        if (s_cmd_queue) {
            BleCommand cmd;
            cmd.len = param->write.len;
            if (cmd.len > sizeof(cmd.data)) cmd.len = sizeof(cmd.data);
            memcpy(cmd.data, param->write.value, cmd.len);
            
            // Wait up to 1000ms for room in queue (Backpressure/Flow Control)
            if (xQueueSend(s_cmd_queue, &cmd, pdMS_TO_TICKS(1000)) != pdPASS) {
                ESP_LOGE(TAG, "Command queue full, dropping write even after timeout!");
            }
        }
        break;
    }
    case ESP_GATTS_START_EVT:
        ESP_LOGI(TAG, "Service started");
        break;
    case ESP_GATTS_MTU_EVT:
        g_negotiated_mtu = param->mtu.mtu;
        ESP_LOGI(TAG, "MTU negotiated: %d", g_negotiated_mtu);
        break;
    case ESP_GATTS_CONNECT_EVT:
        ESP_LOGI(TAG, "Client connected");
        blink(3);
        gl_profile_tab[PROFILE_APP_ID].conn_id = param->connect.conn_id;

        // Request fast connection interval for higher throughput
        {
            esp_ble_conn_update_params_t conn_params = {};
            memcpy(conn_params.bda, param->connect.remote_bda, sizeof(esp_bd_addr_t));
            conn_params.min_int = 0x06;   // 7.5 ms (BLE spec minimum)
            conn_params.max_int = 0x06;   // 7.5 ms
            conn_params.latency = 0;
            conn_params.timeout = 400;    // 4s supervision timeout
            esp_ble_gap_update_conn_params(&conn_params);
        }
        break;
    case ESP_GATTS_DISCONNECT_EVT:
        blink(2);
        ESP_LOGI(TAG, "Client disconnected - restart advertising");
        gl_profile_tab[PROFILE_APP_ID].conn_id = 0xFFFF;
        g_negotiated_mtu = 23; // Reset to default
        g_ble_congested = false;
        esp_ble_gap_start_advertising(&adv_params);
        break;
    case ESP_GATTS_CONGEST_EVT:
        g_ble_congested = param->congest.congested;
        if (g_ble_congested) {
            ESP_LOGW(TAG, "BLE TX congested — dropping packets");
        }
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
    if (ret) return ret;

    ui_command_router_init();

    // Create command queue and processing task
    s_cmd_queue = xQueueCreate(20, sizeof(BleCommand));
    if (!s_cmd_queue) {
        ESP_LOGE(TAG, "Failed to create command queue");
        return ESP_FAIL;
    }
    xTaskCreatePinnedToCore(ble_command_task, "ble_cmd", 8192, NULL, tskIDLE_PRIORITY + 5, NULL, CORE_0);

    ota_controller_init();

    return ESP_OK;
}

// check is there is a client connected
bool ble_is_connected() {
    return (gl_profile_tab[PROFILE_APP_ID].conn_id.load(std::memory_order_acquire) != 0xFFFF);
}

bool ble_is_congested() {
    return g_ble_congested;
}
