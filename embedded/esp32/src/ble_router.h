#pragma once

#include <Arduino.h>

void ble_router_start();
void ble_router_high();
void ble_router_idle();
void ble_router_run_signal(std::string& message);
void ble_router_message_data(std::string& message);