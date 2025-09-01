#ifndef BLE_CONTROLLER_H
#define BLE_CONTROLLER_H

#include <Arduino.h>
#include <NimBLEDevice.h>
#include "esp_task_wdt.h"

#include <chrono>
#include <random>

#include "signal_controller.h"
#include "helper_common.h"
#include "helper_matrix.h"
#include "helper_note.h"
#include "helper_datasetter.h"
#include "helper_printer.h"

// BLE Service and Characteristic UUIDs for remote control
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

static const int BLE_BUFFER_SIZE = 250;

// BLE Task state management
extern BLETaskState g_ble_task_state;

// Function declarations
void bleTask(void* parameter);
void read_and_send_analog_data(NimBLECharacteristic* characteristic);

void ble_router_send_message_last_calc(NimBLECharacteristic* characteristic, int n_chunk);
void ble_router_send_ble_message_status(NimBLECharacteristic* characteristic);
void ble_router_send_ble_message_status_matrix(NimBLECharacteristic* characteristic, SignalSet set);
void ble_router_send_ble_message_status_durations(NimBLECharacteristic* characteristic);
void ble_router_send_ble_message_log_koka(NimBLECharacteristic* characteristic);
void ble_router_send_ble_message_chunk(NimBLECharacteristic* characteristic, const char* buffer, size_t total_len, size_t chunk_size, int chunk_index);
void ble_router_start();
void ble_router_high();
void ble_router_idle();
void ble_router_run_signal(std::string& message);
void ble_router_message_data(std::string& message);
void ble_router_message_set_alpha(std::string& message);

void initialize_BLE();

// BLE Callback classes
class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer);
    void onDisconnect(NimBLEServer* pServer);
};

class CharacteristicCallbacks: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *characteristic);
};

#endif // BLE_CONTROLLER_H
