#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "helpers.h"
#include <chrono>


const int ad1 = 13;
const int ad2 = 27;
const int ad3 = 25;
const int ad4 = 32;
const int ad5 = 34;
const int ad6 = 36;

const int di1 = 4;
const int di2 = 17;
const int di3 = 18;
const int di4 = 21;
const int di5 = 22;
const int di6 = 23;

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
        
        const int di = di5;

        // xxx
        digitalWrite(led, 0);
        digitalWrite(di, 0);
        vTaskDelay(1000 / portTICK_PERIOD_MS);
        Serial.print("leitura analog1: ");
        Serial.println(analogRead(ad1));
        Serial.print("leitura analog2: ");
        Serial.println(analogRead(ad2));
        Serial.print("leitura analog3: ");
        Serial.println(analogRead(ad3));
        Serial.print("leitura analog4: ");
        Serial.println(analogRead(ad4));
        Serial.print("leitura analog5: ");
        Serial.println(analogRead(ad5));
        Serial.print("leitura analog6: ");
        Serial.println(analogRead(ad6));
        Serial.println("");

        digitalWrite(led, 1);
        digitalWrite(di, 1);
        vTaskDelay(1000 / portTICK_PERIOD_MS);
        Serial.print("leitura analog1: ");
        Serial.println(analogRead(ad1));
        Serial.print("leitura analog2: ");
        Serial.println(analogRead(ad2));
        Serial.print("leitura analog3: ");
        Serial.println(analogRead(ad3));
        Serial.print("leitura analog4: ");
        Serial.println(analogRead(ad4));
        Serial.print("leitura analog5: ");
        Serial.println(analogRead(ad5));
        Serial.print("leitura analog6: ");
        Serial.println(analogRead(ad6));
        Serial.println("");

        // vTaskDelay(10 / portTICK_PERIOD_MS);
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


      int read = analogRead(ad1);
      Serial.print("read: ");
      Serial.println(read);
      vTaskDelay(100 / portTICK_PERIOD_MS);
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

    }
    vTaskDelay(100 / portTICK_PERIOD_MS); // Delay to avoid hogging the CPU
  }
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);

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

  // Create the Blink task
  xTaskCreatePinnedToCore(
    TaskBlink,        // Task function
    "Blink",          // Task name
    2048*4,             // Stack size (bytes)
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