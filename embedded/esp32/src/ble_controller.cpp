#include "ble_controller.h"

// External references to global variables
extern SignalTaskState g_signal_task_state;
extern SemaphoreHandle_t g_signal_mutex;
extern uint32_t g_cycle_nrun;
extern volatile ActiveSignalSet g_active_set;
extern volatile uint8_t g_current_state;
extern volatile uint32_t g_cycle_count;

// BLE Task state management
BLETaskState ble_task_state = BLETaskState::IDLE;

// NOTE: Global matrix variable for gain matrix
ControlStatus g_control_status = ControlStatus::OFF;

// Matrix g_control_gain_k(1, 1, {0.0});  // Initialize with 1x1 matrix containing 0

// LED blink utility function for status indication
void blink(uint8_t N) {
    for (uint8_t i = 0; i < N; i++) {
        GPIO.out_w1ts = (1 << 2);  // Turn LED on (GPIO 2)
        vTaskDelay(pdMS_TO_TICKS(100));
        GPIO.out_w1tc = (1 << 2);  // Turn LED off
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// .. BLE connect AND disconnect CALLBACKS
void ServerCallbacks::onConnect(NimBLEServer* pServer) {
    blink(3);  // Visual indication of connection
    Serial.println("Device connected");
}


void ServerCallbacks::onDisconnect(NimBLEServer* pServer) {
    blink(2);  // Visual indication of disconnection
    Serial.println("Device disconnected");
    NimBLEDevice::startAdvertising();  // Resume advertising for new connections
}

// Route BLE commands
void BLE_router(NimBLECharacteristic *characteristic) {

    std::string message = characteristic->getValue();

    // START command: Begin signal generation
    if (message == "START") {
        ble_router_start();
    } 

    // HIGH command: Set all outputs to constant high
    else if (message == "HIGH") {
        ble_router_high();
    } 

    // STOP/LOW commands: Stop signals and set outputs low
    else if (message == "STOP" || message == "LOW") {
        ble_router_idle();
    } 
    // STATUS command: Returns the main status info from the system
    else if (message == "STATUS") {
        send_ble_message_status(characteristic);
    } 
    else if (message == "TOGGLE_SET") {
        toggle_signal_dataset();
    }
    else if (message == "TOGGLE_SET_A") {
        set_signal_dataset_a();
    }
    else if (message == "TOGGLE_SET_B") {
        set_signal_dataset_b();
    }
    else if (message == "CONTROL_ON") {
        set_signal_control_on();
    }
    else if (message == "CONTROL_OFF") {
        set_signal_control_off();
    }
    else if (message.substr(0,14) == "LOG_LAST_CALC:") {
        std::string payload = message.substr(14);
        int n_chunk = std::stoi(payload);
        send_message_last_calc(characteristic, n_chunk - 1);
    } 
    // CYCLE_NRUN command: Set analog reading frequency
    else if (message.substr(0,11) == "CYCLE_NRUN:") {
        std::string payload = message.substr(11);
        g_cycle_nrun = std::stoi(payload);
        Serial.printf("updating ncycles to `%d`!\n", g_cycle_nrun);
    } 
    // SIGNAL command: Load new signal pattern
    else if (message.substr(0,7) == "SIGNAL:") {
        std::string signal = message.substr(7);
        ble_router_run_signal(signal);
    }
    // MESSAGE_DATA command: Load new gain matrix
    else if (message.substr(0,13) == "MESSAGE_DATA:") {
        auto msg = message.substr(13);
        ble_router_message_data(msg);
    }
}

// .. BLE write CALLBACK
void CharacteristicCallbacks::onWrite(NimBLECharacteristic *characteristic) {
    BLE_router(characteristic);
}

void send_message_last_calc(NimBLECharacteristic* pCharacteristic, int n_chunk) {

    note_buffer_print_buffer();

    // Send in chunks to handle large messages
    send_ble_message_chunk(pCharacteristic, note_buffer, strlen(note_buffer), 200, n_chunk);
    
}

// Send system status over BLE
void send_ble_message_status(NimBLECharacteristic* pCharacteristic) {
    // Use static buffer to avoid heap allocation issues
    static char message_buffer[4096];  // Static buffer to avoid heap fragmentation
    int pos = 0;
    
    // Read analog values from multiple channels
    float voltage_03 = read_analog(AnalogPort::AN3);
    float voltage_05 = read_analog(AnalogPort::AN5);
    float voltage_06 = read_analog(AnalogPort::AN6);

    // Format message with sensor readings using snprintf for safety
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "\n\n=========== STATUS ");
    
    if (g_active_set == ActiveSignalSet::SET_A) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "(SET_A active)\n");
    } else {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "(SET_B active)\n");
    }

    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "state: ");
    if (g_signal_task_state == SignalTaskState::HIGH_ALL) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::HIGH_ALL\n");
    } else if (g_signal_task_state == SignalTaskState::IDLE) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::IDLE\n");
    } else if (g_signal_task_state == SignalTaskState::SIGNAL_RUN) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::SIGNAL_RUN\n");
    }

    // Add control status
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "control: ");
    if (g_control_status == ControlStatus::ON) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "ControlStatus::ON\n");
    } else if (g_control_status == ControlStatus::OFF) { 
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "ControlStatus::OFF\n");
    } 

    // Add analog readings
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                   "analog: an3:%.3f, an5:%.3f, an6:%.3f\n", 
                   voltage_03, voltage_05, voltage_06);

    // Add basic timing info without full vectors to prevent overflow
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                   "SET_A: %d elements, SET_B: %d elements\n", 
                   get_signal_set_size(ActiveSignalSet::SET_A), 
                   get_signal_set_size(ActiveSignalSet::SET_B));
    
    // Add current state info if signal is running
    if (g_signal_task_state == SignalTaskState::SIGNAL_RUN) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                       "current_state: %d, cycle_count: %d\n", 
                       g_current_state, g_cycle_count);
    }
    
    // Ensure null termination
    message_buffer[sizeof(message_buffer) - 1] = '\0';

    // Send data via BLE notification with retry mechanism for signal running state
    pCharacteristic->setValue((uint8_t *)message_buffer, strlen(message_buffer));
    pCharacteristic->notify();
        


    Serial.println("STATUS response sent successfully");
}

void send_ble_message_chunk(NimBLECharacteristic* pCharacteristic, const char* buffer, size_t total_len, size_t chunk_size, int chunk_index) {
    // We need to account for the header size, so the actual data payload per chunk is smaller.
    // The header "[CHUNK_X_OF_Y]" can vary in size. Let's assume a safe maximum, or use dynamic sizing.
    // The original code used `chunk_size - 20`, let's maintain that for simplicity.
    size_t payload_size = chunk_size - 20;

    // Calculate the total number of chunks needed for the full message.
    int total_chunks = (total_len + payload_size - 1) / payload_size;

    // Check if the requested chunk index is valid.
    if (chunk_index < 0 || chunk_index >= total_chunks) {
        Serial.printf("Error: Invalid chunk index %d. Total chunks: %d\n", chunk_index, total_chunks);
        return;
    }

    // Calculate the start position for the requested chunk.
    size_t sent = chunk_index * payload_size;
    
    // Calculate the actual size of the data for this specific chunk.
    size_t this_chunk_data_len = std::min(payload_size, total_len - sent);
    
    // Create the header for the chunk.
    char header_buffer[20]; // Assuming header won't exceed 20 bytes
    int header_len = snprintf(header_buffer, sizeof(header_buffer), "\n[CHUNK_%d_OF_%d]\n", chunk_index + 1, total_chunks);
    
    // Create the final buffer for the notification.
    char chunk_buffer[chunk_size];
    memcpy(chunk_buffer, header_buffer, header_len);
    
    // Copy the data payload after the header.
    memcpy(chunk_buffer + header_len, buffer + sent, this_chunk_data_len);

    Serial.printf("Sending chunk %d/%d: %d bytes (total length: %d)\n", 
                  chunk_index + 1, total_chunks, header_len + this_chunk_data_len, total_len);

    // Set the characteristic value and send the notification.
    pCharacteristic->setValue((uint8_t*)chunk_buffer, header_len + this_chunk_data_len);
    pCharacteristic->notify();
    
    // A small delay to ensure the client has time to process the notification
    vTaskDelay(pdMS_TO_TICKS(50));
    
    Serial.printf("Chunk %d sent successfully.\n", chunk_index + 1);
}
uint64_t koka_contador = 0u;
// Send analog readings over BLE
void read_and_send_analog_data(NimBLECharacteristic* pCharacteristic) {
    // Use static buffer to avoid heap allocation issues
    static char analog_buffer[128];
    static char control_result[256];
    
    // Read analog values from multiple channels
    float voltage_03 = read_analog(AnalogPort::AN3);
    float voltage_05 = read_analog(AnalogPort::AN5);
    float voltage_06 = read_analog(AnalogPort::AN6);

    // Compute control
    
    // state
    // NOTE: State Vector
    // vc1 = states(:, 1);
    // vc2 = states(:, 2);
    // i_l = states(:, 3);

    const float resistance = 68.0; // resistor
    const float scale_factor = 10.0/6.0;
    // TODO: change scale to extenal BLE command

    float v_c1 = voltage_05 * scale_factor;
    float v_c2 = voltage_06 * scale_factor;
    float i_l = voltage_03 / resistance * scale_factor;

    DataSet* dataset_active = (g_active_set == ActiveSignalSet::SET_A) ? &dataset_a : &dataset_b;
   
    // NOTE: 5 -> compute dtk on read analog
    float control_dtk[50] = {};
    int32_t control_dtk_us[50] = {};
    size_t control_dtk_len = dataset_active->gain_k.rows;
    if (matrix_isvalid(dataset_active->gain_k) && (dataset_active->gain_k.cols == 3)) {
        // compute ek -> x - x_target

        float ek[3] = {};
        ek[0] = v_c1 - dataset_active->target[0];
        ek[1] = v_c2 - dataset_active->target[1];
        ek[2] = i_l - dataset_active->target[2];

        matrix_multiply_vector3(dataset_active->gain_k, -ek[0], -ek[1], -ek[2], control_dtk);

        // compute dtk_us
        // NOTE: set g_control_dtk_us
        for (int i = 0; i < control_dtk_len; i++) {
            control_dtk_us[i] = (int32_t)std::round(control_dtk[i]*1000000.0);
        }

        // NOTE: conditioning dtk

        // note_buffer_clear();
        // koka_contador = koka_contador++ % 100000;
        // note_buffer_add_text_f("cont: %d\n", koka_contador);

        // note_buffer_add_text("k=");
        // note_buffer_add_matrix(dataset_active->gain_k);
        // note_buffer_add_text_f("x=[%.7f,%.7f,%.7f];\n", v_c1, v_c2, i_l);
        // note_buffer_add_text_f("tgt=[%.7f,%.7f,%.7f];\n", dataset_active->target[0], dataset_active->target[1], dataset_active->target[2]);
        // note_buffer_add_text_f("ek=[%.7f,%.7f,%.7f];\n", ek[0], ek[1], ek[2]);
        // note_buffer_add_text("dtk=[");
        // for (size_t i = 0; i < control_dtk_len; i++) {
        //     note_buffer_add_text_f("%.7f,", control_dtk[i]);
        // }
        // note_buffer_add_text("];\n");

        condition_dtk_signal(dataset_active->time_vec, 10, control_dtk_us, control_dtk_len);

        dataset_active->time_us_diff.resize(control_dtk_len+1, 0);

        dataset_active->time_us_diff[0] = control_dtk_us[0];
        for (size_t i = 1; i < control_dtk_len; i++) {
            dataset_active->time_us_diff[i] = control_dtk_us[i] - control_dtk_us[i-1];
        }
        dataset_active->time_us_diff[control_dtk_len] = -control_dtk_us[control_dtk_len-1];

        size_t time_us_len = dataset_active->time_vec.size();
        uint32_t ts_us[time_us_len + 1] = {};
        for (size_t i = 0; i < time_us_len; i++) {
            ts_us[i+1] = ts_us[i] + dataset_active->time_vec[i] + dataset_active->time_us_diff[i];
        }
        
        // save last matrix multiplication

        // note_buffer_add_text("dtk_fix=[");
        // for (size_t i = 0; i < control_dtk_len; i++) {
        //     note_buffer_add_text_f("%.7f,", control_dtk[i]);
        // }
        // note_buffer_add_text("];\n");

        // note_buffer_add_text("ts_us=[");
        // const size_t ts_us_len = time_us_len + 1;
        // for (size_t i = 0; i < ts_us_len; i++) {
        //     note_buffer_add_text_f("%.7f,", ts_us[i]);
        // }
        // note_buffer_add_text("];\n");
    } else {
        note_buffer_clear();
        koka_contador = koka_contador++ % 100000;
        note_buffer_add_text_f("matrix is not valid!!!! cont: %d\n", koka_contador);
        note_buffer_add_text_f("M.rows: %d; M.cols: %d\n", dataset_active->gain_k.rows, dataset_active->gain_k.cols);
        note_buffer_add_matrix(dataset_active->gain_k);
        // pCharacteristic->setValue((uint8_t *)control_result, strlen(control_result));
        // pCharacteristic->notify();
    } 

    // Format message with sensor readings using snprintf for safety
    //
    // float v_c1 = voltage_05 * scale_factor;
    // float v_c2 = voltage_06 * scale_factor;
    // float i_l = voltage_03 / resistance * scale_factor;
    snprintf(analog_buffer, sizeof(analog_buffer), 
             "an3:%.3f, an5:%.3f, an6:%.3f", 
             voltage_03, voltage_05, voltage_06);
    
    // Ensure null termination
    analog_buffer[sizeof(analog_buffer) - 1] = '\0';

    snprintf(control_result, sizeof(control_result), 
             "an3:%.3f, an5:%.3f, an6:%.3f\nv_c1:%.3f, v_c2:%.3f, i_l:%.3f\ncontrol:[%d,%d,%d,%d,%d]", 
             voltage_03, voltage_05, voltage_06,
             v_c1, v_c2, i_l,
             control_dtk_us[0],control_dtk_us[1],control_dtk_us[2],control_dtk_us[3],control_dtk_us[4]);

    control_result[sizeof(control_result) - 1] = '\0';

    // Send data via BLE notification
    // pCharacteristic->setValue((uint8_t *)analog_buffer, strlen(analog_buffer));
    pCharacteristic->setValue((uint8_t *)control_result, strlen(control_result));
    pCharacteristic->notify();

    // pCharacteristic->notify();
}

// BLE communication task
void bleTask(void* parameter) {
    Serial.print("BLE Task running on core: ");
    Serial.println(xPortGetCoreID());
    
    // Initialize BLE device and server
    NimBLEDevice::init("ESP32 Signal Controller");
    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    
    // Create service and characteristic for remote control
    NimBLEService *pService = pServer->createService(SERVICE_UUID);
    NimBLECharacteristic *pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY
    );
    
    pCharacteristic->setCallbacks(new CharacteristicCallbacks());
    pCharacteristic->setValue("Hello");
    pService->start();
    
    // Start advertising to make device discoverable
    NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
    
    blink(5);  // Indicate BLE initialization complete

    // Register task with watchdog timer
    esp_task_wdt_add(NULL);
    
    // Main BLE task loop
    while (1) {
        // Handle analog reading requests
        if (ble_task_state == BLETaskState::ANALOG_READ) {
            ble_task_state = BLETaskState::ANALOG_READING;
            read_and_send_analog_data(pCharacteristic);
            ble_task_state = BLETaskState::IDLE;
        }
        
        esp_task_wdt_reset();  // Reset watchdog timer
        
        // Use different delays based on signal state to give BLE more processing time during signal generation
        if (g_signal_task_state == SignalTaskState::SIGNAL_RUN) {
            vTaskDelay(pdMS_TO_TICKS(5));   // Shorter delay when signal is running to handle BLE better
        } else {
            vTaskDelay(pdMS_TO_TICKS(10));  // Normal delay when not running signals
        }
    }
}
