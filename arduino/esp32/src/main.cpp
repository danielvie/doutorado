#include "BluetoothSerial.h"
#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "helpers.h"
#include <chrono>
#include <thread>

BluetoothSerial SerialBT;

// .. naming IO ports
const int ad6 = 36;
const int ad5 = 34;
const int ad4 = 32;
const int ad3 = 25;
const int ad2 = 27;
const int ad1 = 13;

const int di6 = 23;
const int di5 = 22;
const int di4 = 21;
const int di3 = 18;
const int di2 = 17;
const int di1 = 4;

const int led = 2;

const int di10 = 33;

// .. initializing variables
int cont = 0;
int delay_ms = 500;

const int N = 100;
int time_values[N];
int mode_values[N];

int commandON = 0;

auto origin = std::chrono::high_resolution_clock::now();
std::chrono::milliseconds duration;

// .. helper functions
void CheckBtConnection() {
    if (SerialBT.connected()) {
        digitalWrite(di6, HIGH);
    } else {
        digitalWrite(di6, LOW);
    }
}

void ProcessBinary(const int &value) {
    Bin b = Num2Bin(value);
    Serial.printf("binary: %d %d %d %d\n", b.b1, b.b2, b.b3, b.b4);
}

void ProcessMATLAB_GUI() {
    String message = SerialBT.readStringUntil('\0');
    if (message.compareTo("0") == 0) {
        digitalWrite(di4, 0);
        digitalWrite(di5, 0);
        digitalWrite(di6, 0);
    } else if (message.compareTo("D4") == 0) {
        digitalWrite(di4, 1);
        digitalWrite(di5, 0);
        digitalWrite(di6, 0);
    } else if (message.compareTo("D5") == 0) {
        digitalWrite(di4, 0);
        digitalWrite(di5, 1);
        digitalWrite(di6, 0);
    } else if (message.compareTo("D6") == 0) {
        digitalWrite(di4, 0);
        digitalWrite(di5, 0);
        digitalWrite(di6, 1);
    }
}

void ProcessMATLAB_Command() {
    // reading message
    String message = SerialBT.readStringUntil('\n');

    // processing arrays
    GetValues(message.c_str(), time_values, mode_values);
    
    // signal command received
    // digitalWrite(di5, 1);
    commandON = 1;
}

// .. task functions
void TaskSerialBT(void *pvParameters) {
    (void) pvParameters; // To avoid unused parameter warning

    while (true) {
        CheckBtConnection();

        // read BT message
        if (SerialBT.available()) {
            // ProcessMATLAB_GUI();
            ProcessMATLAB_Command();
        }

        delay(20);
    }
}

void TaskSerial(void *pvParameters) {
    (void) pvParameters; // To avoid unused parameter warning

    while (true) {
        // int value = random(0, 100);
        if (Serial.available() > 0) {
            String message = Serial.readStringUntil('\n');
            ProcessMATLAB_GUI();
        }
        delay(20);
    }
}

void TaskBlink(void *pvParameters) {
    // track starting time
    auto start = std::chrono::high_resolution_clock::now();
    
    // current index
    size_t index = 0;
    
    // iterate through arrays
    while (index < N && commandON) {
        // calculate elapsed time
        auto now = std::chrono::high_resolution_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();
        
        // check if time has reached
        if (elapsed >= time_values[index]) {
            // update mode
            int mode = mode_values[index];
            digitalWrite(led, mode);
            
            // update index
            ++index;
            
            // break if time -1
            if (time_values[index] == -1) {
                break;
            }
        }
    }
    delay(20);
}

// .. setup
void setup() {
    Serial.begin(115200);
    SerialBT.begin("ESP32_BT"); // Bluetooth name
    Serial.print("Bluetooth started. Waiting for connections...");
    Serial.println(" `ESP32_BT`");
    pinMode(2, OUTPUT);

    // put your setup code here, to run once:
    // Serial.begin(115200);

    pinMode(ad1, INPUT);
    pinMode(ad2, INPUT);
    pinMode(ad3, INPUT);
    pinMode(ad4, INPUT);
    pinMode(ad5, INPUT);
    pinMode(ad6, INPUT);

    pinMode(di1, OUTPUT);
    pinMode(di2, OUTPUT);
    pinMode(di3, OUTPUT);
    pinMode(di4, OUTPUT);
    pinMode(di5, OUTPUT);
    pinMode(di6, OUTPUT);

    pinMode(led, OUTPUT);
    pinMode(di10, OUTPUT);
    // pinMode(outputPin, OUTPUT);
    // pinMode(adcPin, INPUT);

    Init(time_values, mode_values, N);
    time_values[0] = 0;
    time_values[1] = 100;
    time_values[2] = 200;
    time_values[3] = 300;
    time_values[4] = 400;
    time_values[5] = 2000;
    time_values[6] = 5000;
    // time_values[7] = 200;
    mode_values[0] = 0;
    mode_values[1] = 1;
    mode_values[2] = 0;
    mode_values[3] = 1;
    mode_values[4] = 0;
    mode_values[5] = 1;
    mode_values[6] = 0;

    // Create the Blink task
    xTaskCreatePinnedToCore(
        TaskBlink,                // Task function
        "Blink",                  // Task name
        1024,                     // Stack size (bytes)
        NULL,                     // Parameter passed to the task
        1,                        // Task priority
        NULL,                     // Task handle
        0                         // Core idx
    );

    // Create the SerialBT task
    xTaskCreatePinnedToCore(
        TaskSerialBT,             // Task function
        "Serial",                 // Task name
        2048*4,                   // Stack size (bytes)
        NULL,                     // Parameter passed to the task
        1,                        // Task priority
        NULL,                     // Task handle
        1                         // Core idx
    );

    // Create the SerialBT task
    // xTaskCreatePinnedToCore(
    //     TaskSerial,               // Task function
    //     "Serial",                 // Task name
    //     2048*4,                   // Stack size (bytes)
    //     NULL,                     // Parameter passed to the task
    //     1,                        // Task priority
    //     NULL,                     // Task handle
    //     1                         // Core idx
    // );

    // origin = std::chrono::high_resolution_clock::now();

}

void loop() { }