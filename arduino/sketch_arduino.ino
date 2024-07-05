const int ledPin = 13;    // Pin number for the LED
int delayInterval = 1000; // Default delay interval in milliseconds

void setup() {
  pinMode(ledPin, OUTPUT);
  Serial.begin(9600); // Start serial communication at 9600 baud rate
}

void loop() {
  if (Serial.available() > 0) {
    // Read the incoming data as a string
    String data = Serial.readString();

    // Convert the string to an integer
    int newInterval = data.toInt();

    // Update the delay interval
    if (newInterval > 0) {
      delayInterval = newInterval;
    }
  }

  // Blink the LED
  digitalWrite(ledPin, HIGH);
  delay(delayInterval);
  digitalWrite(ledPin, LOW);
  delay(delayInterval);
}
