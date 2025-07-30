#ifndef BLE_CONTROLLER_H
#define BLE_CONTROLLER_H

#include <NimBLEDevice.h>
#include "helpers.h"
#include "Matrix.h"

// BLE Service and Characteristic UUIDs for remote control
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Global matrix variable for gain matrix
extern Matrix g_control_gain_k;

// BLE Task state management
extern BLETaskState ble_task_state;

// Function declarations
void bleTask(void* parameter);
void readAndSendAnalogData(NimBLECharacteristic* pCharacteristic);
void sendMessageStatus(NimBLECharacteristic* pCharacteristic);
void initializeBLE();

// BLE Callback classes
class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer);
    void onDisconnect(NimBLEServer* pServer);
};

class CharacteristicCallbacks: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *characteristic);
};

#endif // BLE_CONTROLLER_H
