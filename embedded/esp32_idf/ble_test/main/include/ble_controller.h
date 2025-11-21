/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */

#ifndef BLE_CONTROLLER_H
#define BLE_CONTROLLER_H

#include <cstdint>

extern "C" {
#include "esp_err.h"
#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"
}

// Initialize BLE stack and register GATT server
esp_err_t ble_controller_init(void);

// Send a BLE notification message to the connected client
esp_err_t ble_send_message(const char* data, uint16_t len);

// Router function to handle incoming BLE write commands
void BLE_router(esp_ble_gatts_cb_param_t *param);

#endif // BLE_CONTROLLER_H
