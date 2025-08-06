#ifndef BLE_CONTROLLER_H
#define BLE_CONTROLLER_H

#include <NimBLEDevice.h>
#include "MatrixMath.h"
#include "esp_task_wdt.h"
#include "helpers.h"
#include "signal_controller.h"

// BLE Service and Characteristic UUIDs for remote control
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Global control variables accessible from signal_controller
extern size_t g_control_dtk_size;
extern float g_control_dtk[50];
extern int64_t g_control_dtk_us[50];
extern size_t g_control_ts_size;
extern float g_control_ts[50];

// BLE Task state management
extern BLETaskState ble_task_state;

// Function declarations
void bleTask(void* parameter);
void read_and_send_analog_data(NimBLECharacteristic* pCharacteristic);
void send_message_status(NimBLECharacteristic* pCharacteristic);
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
