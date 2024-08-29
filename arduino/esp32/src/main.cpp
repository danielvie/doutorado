#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "helpers.h"
#include <chrono>

const int outputPin = 12;
const int led = 2;

// put function declarations here:
int cont = 0;
int delay_ms = 500;

const int N = 100;

int timeValues[N];
int modeValues[N];

int commandON = 0;

auto origin = std::chrono::high_resolution_clock::now();
std::chrono::milliseconds duration;

void TaskBlink(void *pvParameters) {
  while (true) {

    int timeV[N];
    int modeV[N];
    
    // copying values of the global time and mode to the current iteration
    SetValues(timeV, modeV, timeValues, modeValues, N);

    // starting variables for computing time
    auto start = std::chrono::high_resolution_clock::now();
    auto now = start;
    std::chrono::milliseconds time;
    std::chrono::milliseconds t;
    int idx = 0, m;

    for(;;)
    {
      if (!commandON)
      {
        vTaskDelay(10 / portTICK_PERIOD_MS);
        break;
      }

      // reading time and modes
      t = std::chrono::milliseconds(timeV[idx]);
      m = modeV[idx];
      
      // checking for switching time
      now = std::chrono::high_resolution_clock::now();
      time = std::chrono::duration_cast<std::chrono::milliseconds>(now - start);
      duration = std::chrono::duration_cast<std::chrono::milliseconds>(now - origin);
      
      if (time >= t)
      {
        Serial.print("tempo: ");
        Serial.print(t.count());

        Serial.print("; modo: ");
        Serial.print(m);

        Serial.print("; idx: ");
        Serial.println(idx);

        digitalWrite(outputPin, m);
        digitalWrite(led, m);

        idx++;
        t = std::chrono::milliseconds(timeV[idx]);
        m = modeV[idx];
        
      }
      if (timeV[idx] == -1)
      {
        Serial.print("(end of loop at: ");
        Serial.print(duration.count());
        Serial.print(" ms");
        Serial.println(")");
        Serial.println("");
        break;
      }

      vTaskDelay(1 / portTICK_PERIOD_MS);
    }

  }
}

void TaskSerial(void *pvParameters) {
  (void) pvParameters; // To avoid unused parameter warning

  while (true) {
    if (Serial.available() > 0) {
      String incomingString = Serial.readStringUntil('\n');
      int ret = incomingString.toInt();
      bool onlynumbers = incomingString.indexOf(",") == -1;
      if (ret && onlynumbers) {
        delay_ms = ret;
      }
      
      Init(timeValues, modeValues, N);
      GetValues(incomingString.c_str(), timeValues, modeValues);
      
      Print(timeValues, modeValues, N);
      commandON = 1;

      // run `qpRun`
      // auto start = std::chrono::high_resolution_clock::now();
      // qpRun();
      // auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::high_resolution_clock::now() - start);
      
      // Serial.print("tempo de execucao: ");
      // Serial.print(duration.count());
      // Serial.println(" ms");


    }
    vTaskDelay(100 / portTICK_PERIOD_MS); // Delay to avoid hogging the CPU
  }
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
	pinMode(outputPin, OUTPUT);
	pinMode(led, OUTPUT);

  // Create the Blink task
  xTaskCreatePinnedToCore(
    TaskBlink,        // Task function
    "Blink",          // Task name
    2048,             // Stack size (bytes)
    NULL,             // Parameter passed to the task
    1,                // Task priority
    NULL,             // Task handle
    0                 // Core idx
  );

  // Create the Serial task
  xTaskCreatePinnedToCore(
    TaskSerial,       // Task function
    "Serial",         // Task name
    2048*4,           // Stack size (bytes)
    NULL,             // Parameter passed to the task
    1,                // Task priority
    NULL,             // Task handle
    1                 // Core idx
  );


  origin = std::chrono::high_resolution_clock::now();

}

void loop() {
  // Nothing to do here
}