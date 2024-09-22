#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32_BT"); // Bluetooth name
  Serial.print("Bluetooth started. Waiting for connections...");
  Serial.println(" `ESP32_BT`");
  pinMode(2, OUTPUT);
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
