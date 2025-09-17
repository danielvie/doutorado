// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

#include "ble_controller.h"
#include "analog_controller.h"

// BLE Task state management
BLETaskState g_ble_task_state = BLETaskState::IDLE;

NoteData g_buffer_last_calc(1024);
NoteData g_buffer_koka(1024);

// LED blink utility function for status indication
void blink(uint8_t N) {
    for (uint8_t i = 0; i < N; i++) {
        GPIO.out_w1ts = (1 << 2); // Turn LED on (GPIO 2)
        vTaskDelay(pdMS_TO_TICKS(100));
        GPIO.out_w1tc = (1 << 2); // Turn LED off
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// .. BLE connect AND disconnect CALLBACKS
void ServerCallbacks::onConnect(NimBLEServer *pServer) {
    blink(3); // Visual indication of connection
    helper::println("Device connected");
}

void ServerCallbacks::onDisconnect(NimBLEServer *pServer) {
    blink(2); // Visual indication of disconnection
    helper::println("Device disconnected");
    NimBLEDevice::startAdvertising(); // Resume advertising for new connections
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
        ble_router_send_ble_message_status(characteristic);
    }
    else if (message == "STATUS_MATRIX_A") {
        // status matrix setA
        ble_router_send_ble_message_status_matrix(characteristic, SignalSet::SET_A);
    }
    else if (message == "STATUS_MATRIX_B") {
        // status matrix setB
        ble_router_send_ble_message_status_matrix(characteristic, SignalSet::SET_B);
    }
    else if (message == "STATUS_DURATION") {
        // status matrix setB
        ble_router_send_ble_message_status_durations(characteristic);
    }
    else if (message == "LOG_KOKA") {
        ble_router_send_ble_message_log_koka(characteristic);
    }
    else if (message == "TOGGLE_SET") {
        ble_router_toggle_signal_dataset();
    }
    else if (message == "TOGGLE_SET_A") {
        ble_router_set_signal_dataset_a();
    }
    else if (message == "TOGGLE_SET_B") {
        ble_router_set_signal_dataset_b();
    }
    else if (message == "CONTROL_ON") {
        ble_router_set_signal_control_on();
    }
    else if (message == "CONTROL_OFF") {
        ble_router_set_signal_control_off();
    }
    else if (message == "SET_PRINT_ON") {
        ble_router_set_print_on();
    }
    else if (message == "SET_PRINT_OFF") {
        ble_router_set_print_off();
    }
    else if (message == "BLE_MESSAGE_ON") {
        ble_router_set_ble_message_on();
    }
    else if (message == "BLE_MESSAGE_OFF") {
        ble_router_set_ble_message_off();
    }
    else if (message == "LOG_LAST_CALC_ON") {
        helper::println("set log_last_calc ON");
        g_system_status.log_last_calc = StatusONOFF::ON;
    }
    else if (message == "LOG_LAST_CALC_OFF") {
        helper::println("set log_last_calc OFF");
        g_system_status.log_last_calc = StatusONOFF::OFF;
    }
    else if (message.substr(0, 14) == "LOG_LAST_CALC:") {
        std::string payload = message.substr(14);
        int n_chunk = std::stoi(payload);
        ble_router_send_message_last_calc(characteristic, n_chunk - 1);
    }
    // CYCLE_NRUN command: Set analog reading frequency
    else if (message.substr(0, 11) == "CYCLE_NRUN:") {
        std::string payload = message.substr(11);
        g_cycle_nrun = std::stoi(payload);
        helper::printf("updating ncycles to `%d`!\n", g_cycle_nrun);
    }
    // SIGNAL command: Load new signal pattern
    else if (message.substr(0, 7) == "SIGNAL:") {
        std::string signal = message.substr(7);
        ble_router_run_signal(signal);
    }
    // MESSAGE_DATA command: Load new gain matrix
    else if (message.substr(0, 13) == "MESSAGE_DATA:") {
        auto msg = message.substr(13);
        ble_router_message_data(msg);
    }

    // SET_ALPHA command: set alpha from the lookup data
    else if (message.substr(0, 10) == "SET_ALPHA:") {
        auto msg = message.substr(10);
        ble_router_message_set_alpha(msg);
    }
}

// .. BLE write CALLBACK
void CharacteristicCallbacks::onWrite(NimBLECharacteristic *characteristic) {
    BLE_router(characteristic);
}

void ble_router_send_message_last_calc(NimBLECharacteristic *characteristic, int n_chunk) {
    // message.substr(0,14) == "LOG_LAST_CALC:"
    //
    note_buffer_print_info(g_buffer_last_calc);

    // Send in chunks to handle large messages
    ble_router_send_ble_message_chunk(characteristic, g_buffer_last_calc.buffer, strlen(g_buffer_last_calc.buffer), 200, n_chunk);
}

void ble_router_send_ble_message_log_koka(NimBLECharacteristic *characteristic) {
    // message == "LOG_KOKA"
    //

    note_buffer_clear(g_buffer_koka);

    DataSet *dataset = get_dataset_active();

    note_buffer_add_text(g_buffer_koka, "GET DATASET INFO:\n");

    note_buffer_add_text(g_buffer_koka, "active set: ");
    note_buffer_add_text(g_buffer_koka, get_signal_set_label(g_active_set).c_str());
    note_buffer_add_text(g_buffer_koka, "\n");

    auto print_u32 = [](std::string name, uint32_t *V, uint16_t size) {
        note_buffer_add_text_f(g_buffer_koka, "%s: [", name.c_str());
        for (size_t i = 0; i < size; ++i) {
            note_buffer_add_text_f(g_buffer_koka, "%d, ", V[i]);
        }
        note_buffer_add_text(g_buffer_koka, "]\n");
    };

    auto print_i32 = [](std::string name, int32_t *V, uint16_t size) {
        note_buffer_add_text_f(g_buffer_koka, "%s: [", name.c_str());
        for (size_t i = 0; i < size; ++i) {
            note_buffer_add_text_f(g_buffer_koka, "%d, ", V[i]);
        }
        note_buffer_add_text(g_buffer_koka, "]\n");
    };

    note_buffer_add_text_f(g_buffer_koka, "size: %d\n", dataset->size_vec);
    print_u32("time_vec", dataset->time_vec, dataset->size_vec);
    print_u32("d4_vec", dataset->d4_vec, dataset->size_vec);
    print_u32("d5_vec", dataset->d5_vec, dataset->size_vec);
    print_u32("d6_vec", dataset->d6_vec, dataset->size_vec);
    print_i32("time_us_diff", dataset->time_us_diff, dataset->size_vec);

    note_buffer_add_text(g_buffer_koka, "target: [");
    for (auto v : dataset->target) {
        note_buffer_add_text_f(g_buffer_koka, "%f, ", v);
    }
    note_buffer_add_text(g_buffer_koka, "]\n");

    note_buffer_ble_send(g_buffer_koka, characteristic);
    note_buffer_print_info(g_buffer_koka);
}

void ble_router_send_ble_message_status(NimBLECharacteristic *characteristic) {
    // message == "STATUS"
    //

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

    note_buffer_add_text(message_buffer, "ble_messages : ");
    note_buffer_add_text(message_buffer, get_status_onoff_label(g_system_status.ble_messages));
    note_buffer_add_text(message_buffer, "\n");

    note_buffer_add_text(message_buffer, "print_on     : ");
    if (helper::g_printer_on) {
        note_buffer_add_text(message_buffer, "ON");
    } else {
        note_buffer_add_text(message_buffer, "OFF");
    }
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
    helper::println("STATUS response sent successfully");
}

void ble_router_send_ble_message_status_matrix(NimBLECharacteristic *characteristic, SignalSet set) {
    // message == "STATUS_MATRIX_A" || message == "STATUS_MATRIX_B"
    //

    NoteData message_buffer(BLE_BUFFER_SIZE);

    note_buffer_clear(message_buffer);
    DataSet *data = get_dataset_from_set(set);

    note_buffer_add_text_f(message_buffer, "\n\nSTATUS matrix %s [%dx%d]:\n",
                           get_signal_set_label(set).c_str(), data->gain_k.rows, data->gain_k.cols);
    note_buffer_add_matrix(message_buffer, data->gain_k);
    note_buffer_ble_send(message_buffer, characteristic);

    note_buffer_print_info(message_buffer);
}

void ble_router_send_ble_message_status_durations(NimBLECharacteristic *characteristic) {
    // message == "STATUS_DURATION"
    //
    NoteData buffer(BLE_BUFFER_SIZE);

    note_buffer_add_text(buffer, "\nSTATUS time duration:\n");
    note_buffer_add_text_f(buffer, "read and send   : %d us\n", g_system_duration.read_and_send_analog_us);
    note_buffer_add_text_f(buffer, "matrix multiply : %d us\n", g_system_duration.matrix_multiply_us);
    note_buffer_add_text_f(buffer, "dtk condition   : %d us\n", g_system_duration.dtk_condition);
    note_buffer_add_text_f(buffer, "update dtk sig  : %d us\n", g_system_duration.update_signal_with_dtk);

    note_buffer_ble_send(buffer, characteristic);
    note_buffer_print_info(buffer);
}

void ble_router_send_ble_message_chunk(NimBLECharacteristic *characteristic, const char *buffer, size_t total_len, size_t chunk_size, int chunk_index) {
    // message.substr(0,14) == "LOG_LAST_CALC:"
    //

    // The header "[CHUNK_X_OF_Y]" can vary in size. Let's assume a safe maximum, or use dynamic sizing.
    size_t payload_size = chunk_size - 20;

    // Calculate the total number of chunks needed for the full message.
    int total_chunks = (total_len + payload_size - 1) / payload_size;

    // Check if the requested chunk index is valid.
    if (chunk_index < 0 || chunk_index >= total_chunks) {
        helper::printf("Error: Invalid chunk index %d. Total chunks: %d\n", chunk_index, total_chunks);
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

    helper::printf("Sending chunk %d/%d: %d bytes (total length: %d)\n",
                   chunk_index + 1, total_chunks, header_len + this_chunk_data_len, total_len);

    // Set the characteristic value and send the notification.
    characteristic->setValue((uint8_t *)chunk_buffer, header_len + this_chunk_data_len);
    characteristic->notify();

    // A small delay to ensure the client has time to process the notification
    vTaskDelay(pdMS_TO_TICKS(50));

    helper::printf("Chunk %d sent successfully.\n", chunk_index + 1);
}

void ble_router_start() {
    // message == "START"
    //

    if (xSemaphoreTake(g_signal_mutex, portMAX_DELAY) == pdTRUE) {
        g_signal_task_state = SignalTaskState::SIGNAL_RUN;
        xSemaphoreGive(g_signal_mutex);
    }
    digitalWrite(2, HIGH); // LED GPIO
    start_signal_timer();
}

void ble_router_high() {
    // message == "HIGH"
    //

    if (xSemaphoreTake(g_signal_mutex, portMAX_DELAY) == pdTRUE) {
        g_signal_task_state = SignalTaskState::HIGH_ALL;
        xSemaphoreGive(g_signal_mutex);
    }
    stop_signal_timer();
    digitalWrite(2, LOW);
    set_all_outputs_high();
}

void ble_router_idle() {
    // message == "STOP" || message == "LOW"
    //

    if (xSemaphoreTake(g_signal_mutex, portMAX_DELAY) == pdTRUE) {
        g_signal_task_state = SignalTaskState::IDLE;
        xSemaphoreGive(g_signal_mutex);
    }
    stop_signal_timer();
    digitalWrite(2, LOW);
    set_all_outputs_low();
}

void ble_router_run_signal(std::string &signal) {
    // message.substr(0,7) == "SIGNAL:"
    //

    g_ble_task_state = BLETaskState::SIGNAL_READING;
    signal_update_pattern(signal);
}

void ble_router_message_data(std::string &message) {
    // message.substr(0,13) == "MESSAGE_DATA:"
    //

    g_ble_task_state = BLETaskState::SIGNAL_READING;
    signal_update_full_control(message); // NOTE: 0 -> read new message
}

void ble_router_message_set_alpha(std::string &message) {
    // message.substr(0,10) == "SET_ALPHA:"

    // get set that is not active
    DataSet *dataset;

    if (g_active_set == SignalSet::SET_A) {
        dataset = &g_dataset_b;
    }
    else {
        dataset = &g_dataset_a;
    }

    // set data based on alpha and dataset
    float alpha = std::stof(message);

    helper::printf("set_alpha(%.2f)\n", alpha);
    helper_set_dataset_from_alpha(dataset, alpha);

    g_switch_set_pending = true; // Mark for set switching
}

void ble_send_analog_data(NimBLECharacteristic *characteristic) {

    auto timer_start = std::chrono::high_resolution_clock::now();

    // Use static buffer to avoid heap allocation issues
    static char analog_buffer[128];
    static char control_result[256];

    // Read analog values from multiple channels
    // float voltage_03 = read_analog(AnalogPort::AN3);
    // float voltage_05 = read_analog(AnalogPort::AN5);
    // float voltage_06 = read_analog(AnalogPort::AN6);

    // Compute control

    // state
    // NOTE: State Vector
    // vc1 = states(:, 1);
    // vc2 = states(:, 2);
    // i_l = states(:, 3);

    const float resistance = 68.0; // resistor

    // TODO: change scale to extenal BLE command

    // the scale factor is being applied on the analogTask
    float v_c1 = g_voltage_05;
    float v_c2 = g_voltage_06;
    float i_l  = g_voltage_03 / resistance;

    DataSet *dataset_active = (g_active_set == SignalSet::SET_A) ? &g_dataset_a : &g_dataset_b;

    // NOTE: 5 -> compute dtk on read analog
    float control_dtk[50] = {};
    int32_t control_dtk_us[50] = {};
    size_t control_dtk_len = dataset_active->gain_k.rows;

    // TODO: remove this code from here. the send analog data is not responsible for computing the gain
    if (matrix_isvalid(dataset_active->gain_k) && (dataset_active->gain_k.cols == 3)) {
        // compute ek -> x - x_target

        float ek[3] = {};
        ek[0] = v_c1 - dataset_active->target[0];
        ek[1] = v_c2 - dataset_active->target[1];
        ek[2] = i_l  - dataset_active->target[2];

        auto timer_a = std::chrono::high_resolution_clock::now();
        matrix_multiply_vector3(dataset_active->gain_k, -ek[0], -ek[1], -ek[2], control_dtk);
        auto timer_b = std::chrono::high_resolution_clock::now();
        g_system_duration.matrix_multiply_us = std::chrono::duration_cast<std::chrono::microseconds>(timer_b - timer_a).count();

        // compute dtk_us
        // NOTE: set g_control_dtk_us
        for (int i = 0; i < control_dtk_len; i++) {
            control_dtk_us[i] = (int32_t)std::round(control_dtk[i] * 1000000.0);
        }

        // NOTE: conditioning dtk

        // first part part of the log
        if (g_system_status.log_last_calc == StatusONOFF::ON) {
            note_buffer_clear(g_buffer_last_calc);

            auto rand_int = get_rand_int(1, 1000000);
            note_buffer_add_text_f(g_buffer_last_calc, "rand: %d\n", rand_int);

            note_buffer_add_text(g_buffer_last_calc, "k=");
            note_buffer_add_matrix(g_buffer_last_calc, dataset_active->gain_k);
            note_buffer_add_text_f(g_buffer_last_calc, "x=[%.7f,%.7f,%.7f];\n", v_c1, v_c2, i_l);
            note_buffer_add_text_f(g_buffer_last_calc, "target=[%.7f,%.7f,%.7f];\n", dataset_active->target[0], dataset_active->target[1], dataset_active->target[2]);
            note_buffer_add_text_f(g_buffer_last_calc, "ek=[%.7f,%.7f,%.7f];\n", ek[0], ek[1], ek[2]);
            note_buffer_add_text(g_buffer_last_calc, "dtk=[");
            for (size_t i = 0; i < control_dtk_len; i++) {
                note_buffer_add_text_f(g_buffer_last_calc, "%.7f,", control_dtk[i]);
            }
            note_buffer_add_text(g_buffer_last_calc, "];\n");
        }

        const float time_constraint_us = 10.0;

        timer_a = std::chrono::high_resolution_clock::now();
        condition_dtk_signal(dataset_active->time_vec, dataset_active->size_vec, time_constraint_us,
                                       control_dtk_us, control_dtk_len, workspace_float);
        timer_b = std::chrono::high_resolution_clock::now();
        g_system_duration.dtk_condition = std::chrono::duration_cast<std::chrono::microseconds>(timer_b - timer_a).count();

        timer_a = std::chrono::high_resolution_clock::now();

        dataset_active->time_us_diff[0] = control_dtk_us[0];
        for (size_t i = 1; i < control_dtk_len; i++) {
            dataset_active->time_us_diff[i] = control_dtk_us[i] - control_dtk_us[i - 1];
        }
        dataset_active->time_us_diff[control_dtk_len] = -control_dtk_us[control_dtk_len - 1];

        size_t time_us_len = dataset_active->size_vec;
        uint32_t ts_us[time_us_len + 1] = {};
        for (size_t i = 0; i < time_us_len; i++) {
            ts_us[i + 1] = ts_us[i] + dataset_active->time_vec[i] + dataset_active->time_us_diff[i];
        }
        timer_b = std::chrono::high_resolution_clock::now();
        g_system_duration.update_signal_with_dtk = std::chrono::duration_cast<std::chrono::microseconds>(timer_b - timer_a).count();

        // second part of the log
        if (g_system_status.log_last_calc == StatusONOFF::ON) {
            // save last matrix multiplication
            note_buffer_add_text(g_buffer_last_calc, "dtk_fix=[");
            for (size_t i = 0; i < control_dtk_len; i++) {
                note_buffer_add_text_f(g_buffer_last_calc, "%.7f,", control_dtk[i]);
            }
            note_buffer_add_text(g_buffer_last_calc, "];\n");

            note_buffer_add_text(g_buffer_last_calc, "ts_us=[");
            const size_t ts_us_len = time_us_len + 1;
            for (size_t i = 0; i < ts_us_len; i++) {
                note_buffer_add_text_f(g_buffer_last_calc, "%.7f,", ts_us[i]);
            }
            note_buffer_add_text(g_buffer_last_calc, "];\n");
        }
    }
    else {
        note_buffer_clear(g_buffer_last_calc);
        if (g_system_status.log_last_calc == StatusONOFF::ON) {
            note_buffer_add_text_f(g_buffer_last_calc, "matrix is not valid!!!! rand: %d\n", get_rand_int(1, 1000000));
            note_buffer_add_text_f(g_buffer_last_calc, "M.rows: %d; M.cols: %d\n", dataset_active->gain_k.rows, dataset_active->gain_k.cols);
            note_buffer_add_matrix(g_buffer_last_calc, dataset_active->gain_k);
        }
        else {
            note_buffer_add_text(g_buffer_last_calc, "LOG: matrix computation log (log_last_calc) is not active!\n");
        }
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
             g_voltage_03, g_voltage_05, g_voltage_06);

    // Ensure null termination
    analog_buffer[sizeof(analog_buffer) - 1] = '\0';

    snprintf(control_result, sizeof(control_result),
             "an3:%.3f, an5:%.3f, an6:%.3f\nv_c1:%.3f, v_c2:%.3f, i_l:%.3f\ncontrol:[%d,%d,%d,%d,%d]",
             g_voltage_03, g_voltage_05, g_voltage_06,
             v_c1, v_c2, i_l,
             control_dtk_us[0], control_dtk_us[1], control_dtk_us[2], control_dtk_us[3], control_dtk_us[4]);

    control_result[sizeof(control_result) - 1] = '\0';

    // Send data via BLE notification
    // characteristic->setValue((uint8_t *)analog_buffer, strlen(analog_buffer));
    characteristic->setValue((uint8_t *)control_result, strlen(control_result));
    characteristic->notify();

    // characteristic->notify();
}

// BLE communication task
void bleTask(void *parameter) {
    helper::printf("BLE Task running on core: %d\n", xPortGetCoreID());

    // Initialize BLE device and server
    NimBLEDevice::init("ESP32 Signal Controller");
    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    // Create service and characteristic for remote control
    NimBLEService *pService = pServer->createService(SERVICE_UUID);
    NimBLECharacteristic *characteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY);

    characteristic->setCallbacks(new CharacteristicCallbacks());
    characteristic->setValue("Hello");
    pService->start();

    // Start advertising to make device discoverable
    NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->start();

    blink(5); // Indicate BLE initialization complete

    // Register task with watchdog timer
    esp_task_wdt_add(NULL);

    // NOTE: BLE task loop
    while (1) {
        // Handle analog reading requests
        if (g_ble_task_state == BLETaskState::ANALOG_READ) {
            g_ble_task_state = BLETaskState::ANALOG_READING;
            ble_send_analog_data(characteristic);
            g_ble_task_state = BLETaskState::IDLE;
        }

        esp_task_wdt_reset(); // Reset watchdog timer

        // Use different delays based on signal state to give BLE more processing time during signal generation
        if (g_signal_task_state == SignalTaskState::SIGNAL_RUN) {
            vTaskDelay(pdMS_TO_TICKS(5)); // Shorter delay when signal is running to handle BLE better
        }
        else {
            vTaskDelay(pdMS_TO_TICKS(10)); // Normal delay when not running signals
        }
    }
}
