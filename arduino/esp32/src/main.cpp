#include <Arduino.h>
#include "BluetoothSerial.h"
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

const int N = 10;

int timeValues[N];
int modeValues[N];

// track starting time
auto start = std::chrono::high_resolution_clock::now();
bool commandON = false;

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

void ProcessMATLAB_GUI(const String& message) {
    // String message = SerialBT.readStringUntil('\0');
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

void ProcessMATLAB_Command(String& message) {
    // reading message
    // String message = SerialBT.readStringUntil('\n');

    // processing arrays
    Init(timeValues, modeValues, 4);
    GetValues(message.c_str(), timeValues, modeValues);

    // printing values
    Print(timeValues, modeValues, 4);
    
    commandON = true;
}

// .. task functions
void TaskSerialBT(void *pvParameters) {
    (void) pvParameters; // To avoid unused parameter warning

    while (true) {
        // CheckBtConnection();

        // read BT message
        if (SerialBT.available()) {
            String message = SerialBT.readStringUntil('\n');
            // ProcessMATLAB_GUI(message);
            ProcessMATLAB_Command(message);
        }

        delay(20);
    }
}

void TaskSerial(void *pvParameters) {
    (void) pvParameters; // To avoid unused parameter warning

    while (true) {
        // int value = random(0, 100);
        if (Serial.available()) {
            String message = Serial.readStringUntil('\n');
            ProcessMATLAB_GUI(message);
        }
        delay(20);
    }
}

void TaskBlink(void *pvParameters) {
    (void) pvParameters; // To avoid unused parameter warning
    
    while(true) {

        // track starting time
        start = std::chrono::high_resolution_clock::now();

        // current index
        size_t index = 0;
        
        bool first = false;
        
        while(true) {
            auto now = std::chrono::high_resolution_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();
            
            if (elapsed >= 2000 && !first) {
                Serial.println("ik ben uit");
                first = true;
            }

            if (elapsed >= 5000) {
                Serial.println("ik ben uit 5000");
                break;
            }
        }

        // iterate through arrays
        // while(true) {
        //     // calculate elapsed time
        //     auto now = std::chrono::high_resolution_clock::now();
        //     auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();

        //     // if (commandON) {
        //     //     Serial.print("elapsed: ");
        //     //     Serial.println(elapsed);
        //     //     Serial.print("timeValues[index]: ");
        //     //     Serial.println(timeValues[index]);
        //     //     commandON = false;
        //     // }

        //     // // check if time has reached
        //     // if ((elapsed >= (int64_t)timeValues[index]) && commandON)
        //     // {
        //     //     // update mode
        //     //     // int mode = modeValues[index];
        //     //     // digitalWrite(led, mode);

        //     //     // // update index
        //     //     ++index;

        //     //     // // break if time -1
        //     //     if (timeValues[index] == -1) {
        //     //         break;
        //     //     }
        //     //     Serial.printf("time: %d, mode: %d", timeValues[index], modeValues[index]);
        //     // }
        // }

        delay(20);
    }
    
    // // iterate through arrays
    // while (index < N && commandON) {
    //     // calculate elapsed time
    //     auto now = std::chrono::high_resolution_clock::now();
    //     auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();
        
    //     // check if time has reached
    //     if (elapsed >= timeValues[index]) {
    //         // update mode
    //         int mode = modeValues[index];
    //         digitalWrite(led, mode);
            
    //         // update index
    //         ++index;
            
    //         // break if time -1
    //         if (timeValues[index] == -1) {
    //             break;
    //         }
    //     }
    // }
    // delay(20);
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
    xTaskCreatePinnedToCore(
        TaskSerial,               // Task function
        "Serial",                 // Task name
        1024,                     // Stack size (bytes)
        NULL,                     // Parameter passed to the task
        1,                        // Task priority
        NULL,                     // Task handle
        1                         // Core idx
    );


    // Create the Blink task
    xTaskCreatePinnedToCore(
        TaskBlink,                // Task function
        "Blink",                  // Task name
        2048*4,                     // Stack size (bytes)
        NULL,                     // Parameter passed to the task
        1,                        // Task priority
        NULL,                     // Task handle
        0                         // Core idx
    );

    // origin = std::chrono::high_resolution_clock::now();

}

void loop() { }