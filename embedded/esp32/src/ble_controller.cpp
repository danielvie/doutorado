#include "ble_controller.h"

#include <chrono>
#include <random>

// External references to global variables
extern SignalTaskState g_signal_task_state;
extern SemaphoreHandle_t g_signal_mutex;
extern uint32_t g_cycle_nrun;
extern volatile SignalSet g_active_set;
extern volatile uint8_t g_current_state;
extern volatile uint32_t g_cycle_count;

// BLE Task state management
BLETaskState g_ble_task_state = BLETaskState::IDLE;

NoteData g_log_last_calc(1024);
NoteData g_log_koka(250);

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
    else if (message == "STATUS_MATRIX_A") {
        // status matrix setA
        send_ble_message_status_matrix(characteristic, SignalSet::SET_A);
    } 
    else if (message == "STATUS_MATRIX_B") {
        // status matrix setB
        send_ble_message_status_matrix(characteristic, SignalSet::SET_B);
    } 
    else if (message == "STATUS_DURATIONS") {
        // status matrix setB
        send_ble_message_status_durations(characteristic);
    } 
    else if (message == "LOG_KOKA") {
        send_ble_message_log_koka(characteristic);
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
    else if (message == "LOG_LAST_CALC_ON") {
        Serial.println("set log_last_calc ON");
        g_system_status.log_last_calc = StatusONOFF::ON;
    } 
    else if (message == "LOG_LAST_CALC_OFF") {
        Serial.println("set log_last_calc OFF");
        g_system_status.log_last_calc = StatusONOFF::OFF;
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

void send_message_last_calc(NimBLECharacteristic* characteristic, int n_chunk) {
    note_buffer_print_info(g_log_last_calc);

    // Send in chunks to handle large messages
    send_ble_message_chunk(characteristic, g_log_last_calc.buffer, strlen(g_log_last_calc.buffer), 200, n_chunk);
}

void send_ble_message_log_koka(NimBLECharacteristic* characteristic) {
    // message == "LOG_KOKA"
    note_buffer_ble_send(g_log_koka, characteristic);
    note_buffer_print_info(g_log_koka);
}

// Send system status over BLE
void send_ble_message_status(NimBLECharacteristic* characteristic) {
    // Use static buffer to avoid heap allocation issues
    NoteData message_buffer(BLE_BUFFER_SIZE);
    note_buffer_clear(message_buffer);
    
    // Read analog values from multiple channels
    float voltage_03 = read_analog(AnalogPort::AN3);
    float voltage_05 = read_analog(AnalogPort::AN5);
    float voltage_06 = read_analog(AnalogPort::AN6);

    // Format message with sensor readings using snprintf for safety
    note_buffer_add_text(message_buffer, "\n\nSTATUS\n");
    note_buffer_add_text_f(message_buffer, "active       : %s\n", get_signal_set_label(g_active_set).c_str());

    // Add system state
    note_buffer_add_text(message_buffer, "signal state : ");
    note_buffer_add_text(message_buffer, get_signal_task_state_label(g_signal_task_state));
    note_buffer_add_text(message_buffer, "\n");

    note_buffer_add_text(message_buffer, "ble state    : ");
    note_buffer_add_text(message_buffer, get_ble_task_state_label(g_ble_task_state));
    note_buffer_add_text(message_buffer, "\n");

    // Add system status
    note_buffer_add_text(message_buffer, "prop control : ");
    note_buffer_add_text(message_buffer, get_status_onoff_label(g_system_status.prop_control));
    note_buffer_add_text(message_buffer, "\n");

    note_buffer_add_text(message_buffer, "log_last_calc: ");
    note_buffer_add_text(message_buffer, get_status_onoff_label(g_system_status.log_last_calc));
    note_buffer_add_text(message_buffer, "\n");

    // add g_cycle_nrun
    note_buffer_add_text_f(message_buffer, "g_cycle_nrun : %d\n", g_cycle_nrun);

    // Add duration read and send analog
    note_buffer_add_text_f(message_buffer, "\nduration read and send: %d us\n", g_system_duration.read_and_send_analog_us);

    // Add analog readings
    note_buffer_add_text_f(message_buffer, "\nanalog: an3:%.3f, an5:%.3f, an6:%.3f\n", 
                                            voltage_03, voltage_05, voltage_06);

    // Send data via BLE notification with retry mechanism for signal running state
    note_buffer_ble_send(message_buffer, characteristic);

    note_buffer_print_info(message_buffer);
    Serial.println("STATUS response sent successfully");
}

void send_ble_message_status_matrix(NimBLECharacteristic* characteristic, SignalSet set) {
    NoteData message_buffer(BLE_BUFFER_SIZE);

    note_buffer_clear(message_buffer);
    DataSet* data = get_dataset_from_set(set);
    
    note_buffer_add_text_f(message_buffer, "\n\nSTATUS matrix %s [%dx%d]:\n", 
                                           get_signal_set_label(set).c_str(), data->gain_k.rows, data->gain_k.cols);
    note_buffer_add_matrix(message_buffer, data->gain_k);
    note_buffer_ble_send(message_buffer, characteristic);
    
    note_buffer_print_info(message_buffer);
}

void send_ble_message_status_durations(NimBLECharacteristic* characteristic) {
    NoteData buffer(BLE_BUFFER_SIZE);
    
    note_buffer_add_text(buffer, "\nSTATUS time duration:\n");
    note_buffer_add_text_f(buffer, "read and send   : %d us\n", g_system_duration.read_and_send_analog_us);
    note_buffer_add_text_f(buffer, "matrix multiply : %d us\n", g_system_duration.matrix_multiply_us);
    note_buffer_add_text_f(buffer, "dtk condition   : %d us\n", g_system_duration.dtk_condition);
    note_buffer_add_text_f(buffer, "update dtk sig  : %d us\n", g_system_duration.update_signal_with_dtk);
    
    note_buffer_ble_send(buffer, characteristic);
    note_buffer_print_info(buffer);
}

void send_ble_message_chunk(NimBLECharacteristic* characteristic, const char* buffer, size_t total_len, size_t chunk_size, int chunk_index) {
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
    characteristic->setValue((uint8_t*)chunk_buffer, header_len + this_chunk_data_len);
    characteristic->notify();
    
    // A small delay to ensure the client has time to process the notification
    vTaskDelay(pdMS_TO_TICKS(50));
    
    Serial.printf("Chunk %d sent successfully.\n", chunk_index + 1);
}

// Send analog readings over BLE
void read_and_send_analog_data(NimBLECharacteristic* characteristic) {

    auto timer_start = std::chrono::high_resolution_clock::now();

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

    DataSet* dataset_active = (g_active_set == SignalSet::SET_A) ? &g_dataset_a : &g_dataset_b;
   
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

        auto timer_a = std::chrono::high_resolution_clock::now();
        matrix_multiply_vector3(dataset_active->gain_k, -ek[0], -ek[1], -ek[2], control_dtk);
        auto timer_b = std::chrono::high_resolution_clock::now();
        g_system_duration.matrix_multiply_us = std::chrono::duration_cast<std::chrono::microseconds>(timer_b - timer_a).count();

        // compute dtk_us
        // NOTE: set g_control_dtk_us
        for (int i = 0; i < control_dtk_len; i++) {
            control_dtk_us[i] = (int32_t)std::round(control_dtk[i]*1000000.0);
        }

        // NOTE: conditioning dtk

        // first part part of the log
        if (g_system_status.log_last_calc == StatusONOFF::ON) {
            note_buffer_clear(g_log_last_calc);

            auto rand_int = get_rand_int(1, 1000000);
            note_buffer_add_text_f(g_log_last_calc, "rand: %d\n", rand_int);

            note_buffer_add_text(g_log_last_calc, "k=");
            note_buffer_add_matrix(g_log_last_calc, dataset_active->gain_k);
            note_buffer_add_text_f(g_log_last_calc, "x=[%.7f,%.7f,%.7f];\n", v_c1, v_c2, i_l);
            note_buffer_add_text_f(g_log_last_calc, "target=[%.7f,%.7f,%.7f];\n", dataset_active->target[0], dataset_active->target[1], dataset_active->target[2]);
            note_buffer_add_text_f(g_log_last_calc, "ek=[%.7f,%.7f,%.7f];\n", ek[0], ek[1], ek[2]);
            note_buffer_add_text(g_log_last_calc, "dtk=[");
            for (size_t i = 0; i < control_dtk_len; i++) {
                note_buffer_add_text_f(g_log_last_calc, "%.7f,", control_dtk[i]);
            }
            note_buffer_add_text(g_log_last_calc, "];\n");
        }

        
        const float time_constraint_us = 10.0;

        note_buffer_clear(g_log_koka);
        note_buffer_add_text(g_log_koka, "\nLOG KOKA::\n");

        note_buffer_add_array_u32(g_log_koka, "time_vec      ", dataset_active->time_vec.data(), dataset_active->time_vec.size());
        note_buffer_add_array_i32(g_log_koka, "control_dtk_us", control_dtk_us, control_dtk_len);

        timer_a = std::chrono::high_resolution_clock::now();
        condition_dtk_signal(dataset_active->time_vec, time_constraint_us, control_dtk_us, control_dtk_len);
        timer_b = std::chrono::high_resolution_clock::now();
        g_system_duration.dtk_condition = std::chrono::duration_cast<std::chrono::microseconds>(timer_b - timer_a).count();

        // copy of control_dtk_us
        int32_t control_copy[control_dtk_len];
        for (size_t i = 0; i < control_dtk_len; i++) {
            control_copy[i] = control_dtk_us[i];
        }


        timer_a = std::chrono::high_resolution_clock::now();
        condition_dtk_signal_optimized(dataset_active->time_vec.data(), dataset_active->time_vec.size(), time_constraint_us, 
                                     control_copy, control_dtk_len, workspace);
        timer_b = std::chrono::high_resolution_clock::now();
        auto duration_opt = std::chrono::duration_cast<std::chrono::microseconds>(timer_b-timer_a).count();

        note_buffer_add_array_i32(g_log_koka, "control_dtk_us      ", control_dtk_us, control_dtk_len);
        note_buffer_add_array_i32(g_log_koka, "control_dtk_us (opt)", control_copy, control_dtk_len);

        note_buffer_add_text(g_log_koka, "\n");
        note_buffer_add_text_f(g_log_koka, "duration    : %d us\n", g_system_duration.dtk_condition);
        note_buffer_add_text_f(g_log_koka, "duration opt: %d us\n", duration_opt);

        timer_a = std::chrono::high_resolution_clock::now();
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
        timer_b = std::chrono::high_resolution_clock::now();
        g_system_duration.update_signal_with_dtk = std::chrono::duration_cast<std::chrono::microseconds>(timer_b - timer_a).count();
        
        // second part of the log
        if (g_system_status.log_last_calc == StatusONOFF::ON) {
            // save last matrix multiplication
            note_buffer_add_text(g_log_last_calc, "dtk_fix=[");
            for (size_t i = 0; i < control_dtk_len; i++) {
                note_buffer_add_text_f(g_log_last_calc, "%.7f,", control_dtk[i]);
            }
            note_buffer_add_text(g_log_last_calc, "];\n");

            note_buffer_add_text(g_log_last_calc, "ts_us=[");
            const size_t ts_us_len = time_us_len + 1;
            for (size_t i = 0; i < ts_us_len; i++) {
                note_buffer_add_text_f(g_log_last_calc, "%.7f,", ts_us[i]);
            }
            note_buffer_add_text(g_log_last_calc, "];\n");
        }

    } else {
        note_buffer_clear(g_log_last_calc);
        note_buffer_add_text_f(g_log_last_calc, "matrix is not valid!!!! rand: %d\n", get_rand_int(1, 1000000));
        note_buffer_add_text_f(g_log_last_calc, "M.rows: %d; M.cols: %d\n", dataset_active->gain_k.rows, dataset_active->gain_k.cols);
        note_buffer_add_matrix(g_log_last_calc, dataset_active->gain_k);
    } 

    auto timer_end = std::chrono::high_resolution_clock::now();
    g_system_duration.read_and_send_analog_us = std::chrono::duration_cast<std::chrono::microseconds>(timer_end - timer_start).count();

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
    // characteristic->setValue((uint8_t *)analog_buffer, strlen(analog_buffer));
    characteristic->setValue((uint8_t *)control_result, strlen(control_result));
    characteristic->notify();

    // characteristic->notify();
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
    NimBLECharacteristic *characteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY
    );
    
    characteristic->setCallbacks(new CharacteristicCallbacks());
    characteristic->setValue("Hello");
    pService->start();
    
    // Start advertising to make device discoverable
    NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();
    
    blink(5);  // Indicate BLE initialization complete

    // Register task with watchdog timer
    esp_task_wdt_add(NULL);
    
    // NOTE: BLE task loop
    while (1) {
        // Handle analog reading requests
        if (g_ble_task_state == BLETaskState::ANALOG_READ) {
            g_ble_task_state = BLETaskState::ANALOG_READING;
            read_and_send_analog_data(characteristic);
            g_ble_task_state = BLETaskState::IDLE;
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
