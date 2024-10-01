#include "BluetoothSerial.h"
#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "helpers.h"
#include <chrono>

BluetoothSerial SerialBT;

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

// put function declarations here:
int cont = 0;
int delay_ms = 500;

const int N = 100;

int timeValues[N];
int modeValues[N];

int commandON = 0;

auto origin = std::chrono::high_resolution_clock::now();
std::chrono::milliseconds duration;

void ProcessIncoming(const String &incoming) {
    Serial.printf("received: %s", incoming.c_str());
}

void TaskSerial(void *pvParameters) {
    (void) pvParameters; // To avoid unused parameter warning

    while (true) {
        if (Serial.available() > 0) {
            String incomingString = Serial.readStringUntil('\n');
            int ret = incomingString.toInt();
            bool onlynumbers = incomingString.indexOf(",") == -1;
            // if (ret && onlynumbers) {
            //     delay_ms = ret;
            // }
      
            // Init(timeValues, modeValues, N);
            // GetValues(incomingString.c_str(), timeValues, modeValues);
      
            // Print(timeValues, modeValues, N);
            // commandON = 1;
            // printf("%s", incomingString.c_str());
            ProcessIncoming(incomingString);
        }
    
        // Serial.println("task serial");
        vTaskDelay(100 / portTICK_PERIOD_MS); // Delay to avoid hogging the CPU
    }
}

void setup() {
    Serial.begin(115200);
    SerialBT.begin("ESP32_BT"); // Bluetooth name
    Serial.print("Bluetooth started. Waiting for connections...");
    Serial.println(" `ESP32_BT`");
    pinMode(2, OUTPUT);

    // put your setup code here, to run once:
    // Serial.begin(115200);

    // pinMode(ad1, INPUT);
    // pinMode(ad2, INPUT);
    // pinMode(ad3, INPUT);
    // pinMode(ad4, INPUT);
    // pinMode(ad5, INPUT);
    // pinMode(ad6, INPUT);

    pinMode(di1, OUTPUT);
    pinMode(di2, OUTPUT);
    pinMode(di3, OUTPUT);
    pinMode(di4, OUTPUT);
    pinMode(di5, OUTPUT);
    pinMode(di6, OUTPUT);

    // pinMode(led, OUTPUT);
    // pinMode(di10, OUTPUT);
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

    // Create the Serial task
    xTaskCreatePinnedToCore(
        TaskSerial,             // Task function
        "Serial",                 // Task name
        2048*4,                     // Stack size (bytes)
        NULL,                         // Parameter passed to the task
        1,                                // Task priority
        NULL,                         // Task handle
        1                                 // Core idx
    );

    // origin = std::chrono::high_resolution_clock::now();

}

void Connection() {
    if (SerialBT.connected()) {
        digitalWrite(2, HIGH);
    } else {
        digitalWrite(2, LOW);
    }
}

void loop() {
    Connection();
  
    // int value = random(0, 100);
    if (SerialBT.available()) {
        String received = SerialBT.readString();
        Serial.printf("Received: %s\n", received.c_str());

        // You can also send back a response
        SerialBT.printf("Sended: Message received: `%s`\n", received.c_str());
    }
    delay(20);
}
