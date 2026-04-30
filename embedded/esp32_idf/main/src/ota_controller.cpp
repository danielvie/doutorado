#include "ota_controller.h"
#include "ble_controller.h"
#include <string.h>

static const char* TAG = "OTA_CTRL";

static esp_ota_handle_t update_handle = 0;
static const esp_partition_t* update_partition = NULL;
static size_t binary_file_size = 0;
static size_t written_size = 0;
static OtaState current_state = OtaState_OTA_IDLE;
static char last_error[64] = "";

void ota_controller_init(void) {
    current_state = OtaState_OTA_IDLE;
    written_size = 0;
    binary_file_size = 0;
}

void ota_controller_get_status(OtaStatus* status) {
    status->state = current_state;
    if (binary_file_size > 0) {
        status->progress_percent = (written_size * 100) / binary_file_size;
    } else {
        status->progress_percent = 0;
    }
    strncpy(status->message, last_error, sizeof(status->message) - 1);
}

static void send_status_update() {
    BlePacket packet = BlePacket_init_zero;
    packet.which_payload = BlePacket_ota_status_tag;
    ota_controller_get_status(&packet.payload.ota_status);
    ble_send_protobuf(&packet);
}

void ota_controller_handle_command(const OtaCommand* cmd) {
    esp_err_t err;

    switch (cmd->which_type) {
        case OtaCommand_begin_tag:
            ESP_LOGI(TAG, "OTA Begin requested. Size: %lu bytes", cmd->type.begin.file_size);
            
            if (current_state != OtaState_OTA_IDLE) {
                ota_controller_abort();
            }

            update_partition = esp_ota_get_next_update_partition(NULL);
            if (update_partition == NULL) {
                ESP_LOGE(TAG, "Passive OTA partition not found");
                current_state = OtaState_OTA_ERROR;
                strcpy(last_error, "No OTA partition");
                send_status_update();
                return;
            }

            binary_file_size = cmd->type.begin.file_size;
            written_size = 0;
            
            err = esp_ota_begin(update_partition, binary_file_size, &update_handle);
            if (err != ESP_OK) {
                ESP_LOGE(TAG, "esp_ota_begin failed: %s", esp_err_to_name(err));
                current_state = OtaState_OTA_ERROR;
                snprintf(last_error, sizeof(last_error), "Begin failed: %s", esp_err_to_name(err));
                send_status_update();
                return;
            }

            current_state = OtaState_OTA_DOWNLOADING;
            ESP_LOGI(TAG, "OTA started, writing to partition at offset 0x%lx", update_partition->address);
            send_status_update();
            break;

        case OtaCommand_chunk_tag:
            if (current_state != OtaState_OTA_DOWNLOADING) {
                ESP_LOGW(TAG, "Chunk received but not in DOWNLOADING state");
                return;
            }

            err = esp_ota_write(update_handle, cmd->type.chunk.data.bytes, cmd->type.chunk.data.size);
            if (err != ESP_OK) {
                ESP_LOGE(TAG, "esp_ota_write failed: %s", esp_err_to_name(err));
                current_state = OtaState_OTA_ERROR;
                snprintf(last_error, sizeof(last_error), "Write failed: %s", esp_err_to_name(err));
                send_status_update();
                return;
            }

            written_size += cmd->type.chunk.data.size;
            // Send status update every 10% or so to avoid flooding BLE
            if (written_size % (binary_file_size / 10 + 1) < cmd->type.chunk.data.size) {
                 send_status_update();
            }
            break;

        case OtaCommand_end_tag:
            ESP_LOGI(TAG, "OTA End requested");
            if (current_state != OtaState_OTA_DOWNLOADING) {
                ESP_LOGW(TAG, "End received but not in DOWNLOADING state");
                return;
            }

            current_state = OtaState_OTA_VERIFYING;
            send_status_update();

            err = esp_ota_end(update_handle);
            if (err != ESP_OK) {
                ESP_LOGE(TAG, "esp_ota_end failed: %s", esp_err_to_name(err));
                current_state = OtaState_OTA_ERROR;
                snprintf(last_error, sizeof(last_error), "End failed: %s", esp_err_to_name(err));
                send_status_update();
                return;
            }

            err = esp_ota_set_boot_partition(update_partition);
            if (err != ESP_OK) {
                ESP_LOGE(TAG, "esp_ota_set_boot_partition failed: %s", esp_err_to_name(err));
                current_state = OtaState_OTA_ERROR;
                snprintf(last_error, sizeof(last_error), "Boot set failed: %s", esp_err_to_name(err));
                send_status_update();
                return;
            }

            current_state = OtaState_OTA_FINISHED;
            ESP_LOGI(TAG, "OTA successful! Rebooting in 2 seconds...");
            send_status_update();
            
            vTaskDelay(pdMS_TO_TICKS(2000));
            esp_restart();
            break;

        case OtaCommand_abort_tag:
            ESP_LOGI(TAG, "OTA Abort requested");
            ota_controller_abort();
            send_status_update();
            break;

        default:
            break;
    }
}

void ota_controller_abort(void) {
    if (update_handle != 0) {
        esp_ota_abort(update_handle);
        update_handle = 0;
    }
    current_state = OtaState_OTA_IDLE;
    written_size = 0;
    binary_file_size = 0;
}
