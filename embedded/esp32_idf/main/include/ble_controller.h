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

// Send a Protobuf message to the connected client
esp_err_t ble_send_log(BleLogLevel level, const char* text);
esp_err_t ble_send_protobuf(const BlePacket* packet);

// Router function to handle incoming BLE write commands
void ble_router_set_signal(std::string& message);

void ble_router_print_active_dataset(void);
void ble_router_print_dataset_a(void);
void ble_router_print_dataset_b(void);

void ble_router_message_set_alpha(std::string& message);

void ble_router(esp_ble_gatts_cb_param_t *param);

void ble_router_ble_read(Status status);
void ble_router_blink(void);
void ble_router_blink_n(uint16_t blink_d1);
void ble_router_blink_nn(uint16_t blink_d1, uint16_t blink_d2);
void ble_router_led_off(NoteData& msg);
void ble_router_led_on(NoteData& msg);
void ble_router_log_duration(void);
void ble_router_message_set_alpha(std::string& message);
void ble_router_read(void);
void ble_router_set_port(uint16_t port, uint16_t value);
void ble_router_set_signal(std::string& message);
void ble_router_signal_start();
void ble_router_signal_stop();
void ble_router_all_high(void);
void ble_router_all_low(void);
void ble_router_ctrl(ControlState state);
void ble_router_status(void);
void ble_router_status_matrix(SignalSet set);

// check is there is a client connected
bool ble_is_connected();

#endif // BLE_CONTROLLER_H
