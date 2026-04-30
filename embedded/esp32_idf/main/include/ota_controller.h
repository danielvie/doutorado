#pragma once

#include "esp_ota_ops.h"
#include "esp_system.h"
#include "esp_log.h"
#include "messaging.pb.h"

// Initialize OTA controller
void ota_controller_init(void);

// Handle OTA commands from BLE
void ota_controller_handle_command(const OtaCommand* cmd);

// Get current OTA status for reporting
void ota_controller_get_status(OtaStatus* status);

// Abort current OTA process
void ota_controller_abort(void);
