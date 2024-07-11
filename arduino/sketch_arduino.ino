const int ledPin = 13;    // Pin number for the LED 
const int outputPin = 9; // pin number for the digital output signal
const int analogPin = A0; // pin number for the analog input
int delayInterval = 1000; // Default delay interval in milliseconds 

void setup() { 
  pinMode(ledPin, OUTPUT); 
  pinMode(outputPin, OUTPUT);
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
  // Read the analog value
  int analogValue = analogRead(analogPin);
  
  const int N = 10;
  int delay_ = delayInterval/N;

  bool PIN = false;
  long cont = 0;
  for (int i = 0; i < N; i++) {
    // Print the analog value to the serial monitor
    cont++;
    
    analogValue = analogRead(analogPin);
    Serial.println(analogValue);

    if (i >= N/2) {a
      PIN = true;
    }

    // Blink the LED 
    digitalWrite(ledPin, PIN); 
    digitalWrite(outputPin, PIN);
    delay(delay_); 
  }
}