/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */

#ifndef BLE_CONTROLLER_H
#define BLE_CONTROLLER_H

#include "helper_analog.h"
#include "helper_common.h"
#include "helper_note.h"
#include "helper_led.h"
#include "helper_datasetter.h"
#include "signal_controller.h"
#include "proto/messaging.pb.h"


#include <algorithm>
#include <cstring>
#include <memory>
#include <string>

extern "C" {
#include "esp_bt.h"
#include "esp_bt_defs.h"
#include "esp_bt_device.h"
#include "esp_bt_main.h"
#include "esp_err.h"
#include "esp_gap_ble_api.h"
#include "esp_gatt_common_api.h"
#include "esp_gatts_api.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

}

// Initialize BLE stack and register GATT server
esp_err_t ble_controller_init(void);

// Send a BLE notification message to the connected client
esp_err_t ble_send_message(const char* data, uint16_t len, BLEMode mode = BLEMode::VERBOSE);
esp_err_t ble_send_message_critical(const char* data, uint16_t len, BLEMode mode = BLEMode::VERBOSE);

// Send a Protobuf message to the connected client
esp_err_t ble_send_log(BleLogLevel level, const char* text);
esp_err_t ble_send_protobuf(const BlePacket* packet);
esp_err_t ble_send_protobuf_critical(const BlePacket* packet);

void ble_router(esp_ble_gatts_cb_param_t *param);

void ble_send_analog_read(void);
void ble_send_dataset(DataSet* ds, SignalSet set);
void ble_send_log_duration(void);
void ble_send_status(void);
void ble_send_status_matrix(SignalSet set);

// check is there is a client connected
bool ble_is_connected();
bool ble_is_congested();

#endif // BLE_CONTROLLER_H
