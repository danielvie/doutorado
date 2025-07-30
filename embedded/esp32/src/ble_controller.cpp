#include <Arduino.h>
#include "ble_controller.h"
#include "signal_controller.h"
#include "esp_task_wdt.h"
#include "Matrix.h"

// External references to global variables
extern SignalTaskState signal_task_state;
extern SemaphoreHandle_t signal_mutex;
extern uint32_t cycle_nrun;
extern volatile ActiveSignalSet active_set;
extern volatile uint8_t current_state;
extern volatile uint32_t cycle_count;

// BLE Task state management
BLETaskState ble_task_state = BLETaskState::IDLE;

// Global matrix variable for gain matrix

size_t g_control_dtk_size = 0;
double g_control_dtk[50];

size_t g_control_ts_size = 0;
double g_control_ts[50];

Matrix g_control_gain_k(1, 1, {0.0});  // Initialize with 1x1 matrix containing 0

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

// .. BLE write CALLBACK
void CharacteristicCallbacks::onWrite(NimBLECharacteristic *characteristic) {
    std::string value = characteristic->getValue();
    
    Serial.print("received message: ");
    Serial.println(value.c_str());
    Serial.printf("Free heap: %d bytes\n", ESP.getFreeHeap());
    Serial.println("==================");

    // START command: Begin signal generation
    if (value == "START") {
        if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
            signal_task_state = SignalTaskState::SIGNAL_RUN;
            xSemaphoreGive(signal_mutex);
        }
        Serial.println("Signals started");
        digitalWrite(2, HIGH);  // LED GPIO
        startSignalTimer();
    } 
    // HIGH command: Set all outputs to constant high
    else if (value == "HIGH") {
        if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
            signal_task_state = SignalTaskState::HIGH_RUN;
            xSemaphoreGive(signal_mutex);
        }
        stopSignalTimer();
        Serial.println("Signals high");
        digitalWrite(2, LOW);
        setAllOutputsHigh();
    } 
    // STOP/LOW commands: Stop signals and set outputs low
    else if (value == "STOP" || value == "LOW") {
        if (xSemaphoreTake(signal_mutex, portMAX_DELAY) == pdTRUE) {
            signal_task_state = SignalTaskState::IDLE;
            xSemaphoreGive(signal_mutex);
        }
        stopSignalTimer();
        Serial.println("Signals stopped");
        digitalWrite(2, LOW);
        setAllOutputsLow();
    } 
    // STATUS command: Returns the main status info from the system
    else if (value == "STATUS") {
        sendMessageStatus(characteristic);
    } 
    // CYCLE_NRUN command: Set analog reading frequency
    else if (value.substr(0,11) == "CYCLE_NRUN:") {
        std::string payload = value.substr(11);
        cycle_nrun = std::stoi(payload);
        Serial.printf("updating ncycles to `%d`!\n", cycle_nrun);
    } 
    // SIGNAL command: Load new signal pattern
    else if (value.substr(0,7) == "SIGNAL:") {
        std::string signal = value.substr(7);
        Serial.println("Signals received:");
        Serial.println(value.c_str());

        try {
            ble_task_state = BLETaskState::SIGNAL_READING;
            updateSignalPattern(signal);
        } catch (std::exception &e) {
            Serial.printf("Error parsing signal: %s\n", e.what());
            Serial.printf("Signal sent to parse: '%s'\n", signal.c_str());
        }
    }
    // MATRIX command: Load new gain matrix
    else if (value.substr(0,7) == "MATRIX:") {
        std::string matrix_str = value.substr(7);
        Serial.println("Matrix received:");
        Serial.println(matrix_str.c_str());

        try {
            // Parse and store the matrix using Matrix::from_string
            Matrix new_matrix = Matrix::from_string(matrix_str);
            
            if (new_matrix.is_valid()) {
                g_control_gain_k = new_matrix;  // Store as global variable
                Serial.printf("Matrix stored successfully: %dx%d\n", 
                             g_control_gain_k.get_rows(), g_control_gain_k.get_cols());
                
                // Debug: Print the matrix
                Serial.println("Stored matrix:");
                g_control_gain_k.print();
            } else {
                Serial.println("Error: Invalid matrix format or data");
            }
        } catch (std::exception &e) {
            Serial.printf("Error parsing matrix: %s\n", e.what());
            Serial.printf("Matrix string sent to parse: '%s'\n", matrix_str.c_str());
        }
    }
}

/**
 * Send Status info to main program
 * @param pCharacteristic Pointer to the BLE characteristic for sending data
 */
void sendMessageStatus(NimBLECharacteristic* pCharacteristic) {
    // Use static buffer to avoid heap allocation issues
    static char message_buffer[1024];  // Static buffer to avoid heap fragmentation
    int pos = 0;
    
    // Read analog values from multiple channels
    float voltage_03 = read_analog(AnalogPort::AN3);
    float voltage_05 = read_analog(AnalogPort::AN5);
    float voltage_06 = read_analog(AnalogPort::AN6);

    // Format message with sensor readings using snprintf for safety
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "status ");
    
    if (active_set == ActiveSignalSet::SET_A) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "(SET_A active)\n");
    } else {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "(SET_B active)\n");
    }

    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "state: ");
    if (signal_task_state == SignalTaskState::HIGH_RUN) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::HIGH_RUN\n");
    } else if (signal_task_state == SignalTaskState::IDLE) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::IDLE\n");
    } else if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, "SignalTaskState::SIGNAL_RUN\n");
    }

    // Add analog readings
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                   "analog: an3:%.3f, an5:%.3f, an6:%.3f\n", 
                   voltage_03, voltage_05, voltage_06);

    // Add basic timing info without full vectors to prevent overflow
    pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                   "SET_A: %d elements, SET_B: %d elements\n", 
                   getSignalSetSize(ActiveSignalSet::SET_A), 
                   getSignalSetSize(ActiveSignalSet::SET_B));
    
    // Add current state info if signal is running
    if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
        pos += snprintf(message_buffer + pos, sizeof(message_buffer) - pos, 
                       "current_state: %d, cycle_count: %d\n", 
                       current_state, cycle_count);
    }
    
    // Ensure null termination
    message_buffer[sizeof(message_buffer) - 1] = '\0';

    // Send data via BLE notification with retry mechanism for signal running state
    pCharacteristic->setValue((uint8_t *)message_buffer, strlen(message_buffer));
    
    // When signal is running, try multiple times with delays to ensure delivery
    if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
        for (int retry = 0; retry < 3; retry++) {
            pCharacteristic->notify();
            vTaskDelay(pdMS_TO_TICKS(10)); // Small delay between retries
        }
    } else {
        pCharacteristic->notify();
    }
    
    Serial.println(message_buffer);
    
    // Demonstrate matrix multiplication with 3-element vector (optimized)
    if (g_control_gain_k.is_valid() && g_control_gain_k.get_cols() == 3) {
        // Pre-allocate result array for the multiplication
        double result[g_control_gain_k.get_rows()];
        
        // Perform optimized multiplication with vector [0.6, 0.1, 0.1] (NO SCALING)
        g_control_gain_k.multiply_vector3(-0.6, -0.1, -0.1, result);
        
        Serial.println("Matrix multiplication result (optimized):");
        for (int i = 0; i < g_control_gain_k.get_rows(); ++i) {
            Serial.printf("%.6f\n", result[i]);
        }

        Serial.println("\ncomputing => g_gain_k.multiply(Matrix(3,1,{0.6, 0.1, 0.1}));");
        auto res = g_control_gain_k.scale(-1.0).multiply(Matrix(3,1,{0.6, 0.1, 0.1}));
        res.print();


    } else {
        Serial.println("Matrix not available or wrong dimensions for vector multiplication");
    }

    Serial.println("STATUS response sent successfully");
}

/**
 * Read analog values from multiple channels and send via BLE notification
 * @param pCharacteristic Pointer to the BLE characteristic for sending data
 */
void readAndSendAnalogData(NimBLECharacteristic* pCharacteristic) {
    // Use static buffer to avoid heap allocation issues
    static char analog_buffer[128];
    
    // Read analog values from multiple channels
    float voltage_03 = read_analog(AnalogPort::AN3);
    float voltage_05 = read_analog(AnalogPort::AN5);
    float voltage_06 = read_analog(AnalogPort::AN6);

    // Compute control
    if (g_control_gain_k.is_valid()) {
        // compute control
        g_control_dtk_size = g_control_gain_k.get_rows();
        g_control_gain_k.multiply_vector3(voltage_06, voltage_05, voltage_03, g_control_dtk);
        
        // compute_ts_from_dtk
        for (int j = 0; j < g_control_dtk_size; j++) {

            
        }
    }

    // Format message with sensor readings using snprintf for safety
    snprintf(analog_buffer, sizeof(analog_buffer), 
             "an3:%.3f, an5:%.3f, an6:%.3f", 
             voltage_03, voltage_05, voltage_06);
    
    // Ensure null termination
    analog_buffer[sizeof(analog_buffer) - 1] = '\0';

    // Send data via BLE notification
    pCharacteristic->setValue((uint8_t *)analog_buffer, strlen(analog_buffer));
    pCharacteristic->notify();
}

/**
 * BLE Communication Task
 * Runs on Core 0 and handles:
 * - BLE server initialization and advertising
 * - Periodic analog sensor readings
 * - Data transmission to connected clients
 * 
 * @param parameter Unused task parameter
 */
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
            readAndSendAnalogData(pCharacteristic);
            ble_task_state = BLETaskState::IDLE;
        }
        
        esp_task_wdt_reset();  // Reset watchdog timer
        
        // Use different delays based on signal state to give BLE more processing time during signal generation
        if (signal_task_state == SignalTaskState::SIGNAL_RUN) {
            vTaskDelay(pdMS_TO_TICKS(5));   // Shorter delay when signal is running to handle BLE better
        } else {
            vTaskDelay(pdMS_TO_TICKS(10));  // Normal delay when not running signals
        }
    }
}
