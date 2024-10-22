#include "BluetoothSerial.h"
#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "helpers.h"
#include <chrono>

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

int timeValues[N];
int modeValues[N];

int commandON = 0;

auto origin = std::chrono::high_resolution_clock::now();
std::chrono::milliseconds duration;

// .. helper functions
void CheckBtConnection() {
    if (SerialBT.connected()) {
        digitalWrite(2, HIGH);
    } else {
        digitalWrite(2, LOW);
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
    String message = SerialBT.readStringUntil('\n');
}

// .. task functions
void TaskSerialBT(void *pvParameters) {
    (void) pvParameters; // To avoid unused parameter warning

    while (true) {
        // CheckBtConnection();

        // read BT message
        if (SerialBT.available()) {
            ProcessMATLAB_GUI();
            // ProcessMATLAB_Command();
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

    // // Create the Blink task
    // xTaskCreatePinnedToCore(
    //     TaskBlink,                // Task function
    //     "Blink",                    // Task name
    //     2048*4,                         // Stack size (bytes)
    //     NULL,                         // Parameter passed to the task
    //     1,                                // Task priority
    //     NULL,                         // Task handle
    //     0                                 // Core idx
    // );

    // Create the SerialBT task
    xTaskCreatePinnedToCore(
        TaskSerialBT,             // Task function
        "Serial",                 // Task name
        2048*4,                   // Stack size (bytes)
        NULL,                     // Parameter passed to the task
        1,                        // Task priority
        NULL,                     // Task handle
        0                         // Core idx
    );

    // Create the SerialBT task
    xTaskCreatePinnedToCore(
        TaskSerial,               // Task function
        "Serial",                 // Task name
        2048*4,                   // Stack size (bytes)
        NULL,                     // Parameter passed to the task
        1,                        // Task priority
        NULL,                     // Task handle
        1                         // Core idx
    );

    // origin = std::chrono::high_resolution_clock::now();

}

void loop() { }