
// Pin number for the LED
const int ledPin = 13;

// output digital pins
const int outputPin_1  = 9;
const int outputPin_2  = 8;
const int outputPin_3  = 7;

// pin number for the analog input 
const int analogPin_1 = A0;
const int analogPin_2 = A1;
const int analogPin_3 = A2;

// Default delay interval in milliseconds  
int delayInterval = 2000; 

// Helper
bool commandON = false;

const int N = 10;
int timeValues[N];
int modeValues[N];

void setup() {  
  pinMode(ledPin, OUTPUT);  
  pinMode(outputPin_1, OUTPUT); 
  pinMode(outputPin_2, OUTPUT); 
  pinMode(outputPin_3, OUTPUT); 

  Serial.begin(9600); // Start serial communication at 9600 baud rate  
}  

void GetValues(const char* s, int timeValues[], int modeValues[]) {
    // Buffer to store the substring parts
    char buffer[20];
    int bufferIndex = 0;
    int timeIndex = 0;
    int modeIndex = 0;
    bool isTimePart = true;

    for (int i = 0; s[i] != '\0'; ++i) {
        if (s[i] == ',' || s[i] == ';' || s[i+1] == '\0') {
            if (s[i+1] == '\0' && s[i] != ',' && s[i] != ';') {
                buffer[bufferIndex++] = s[i];
            }
            buffer[bufferIndex] = '\0';
            bufferIndex = 0;

            if (isTimePart) {
                timeValues[timeIndex++] = atoi(buffer);
            } else {
                modeValues[modeIndex++] = atoi(buffer);
            }

            if (s[i] == ';') {
                isTimePart = false;
            }
        } else {
            buffer[bufferIndex++] = s[i];
        }
    }
}

void loop() {
  
  // Read the incoming data from the Serial
  if (Serial.available() > 0) {  
    String data = Serial.readString();  
  
    commandON = true;
    Serial.println("----------------"); 
    Serial.println(data); 
    Serial.println("----------------"); 

    GetValues(data.c_str(), timeValues, modeValues);

    Serial.println("======= received message ========="); 
    for (int i = 0; i <  4; i++) {
      Serial.println(timeValues[i]); 
      Serial.println(modeValues[i]); 
    }
    Serial.println("======= received message [end] ========="); 

    // Convert the string to an integer  
    int newInterval = data.toInt();  
  
    // Update the delay interval  
    if (newInterval > 0) {  
      delayInterval = newInterval;  
    }  
  }  

  // Read the analog values for the blink
  int analogValue_1 = analogRead(analogPin_1); 
  int analogValue_2 = analogRead(analogPin_2); 
  int analogValue_3 = analogRead(analogPin_3); 
   
  bool PIN = false; 
  long cont = 0; 
  
  // LOOP DO CICLO DE BLINK
  {

    Serial.println("======= time and modes ========="); 
    Serial.println("time:");
    for (int i = 0; i <  4; i++) {
      Serial.print(timeValues[i]); 
      Serial.print(" "); 
    }
    Serial.println(";");

    Serial.println("mode:");
    for (int i = 0; i <  4; i++) {
      Serial.print(modeValues[i]); 
      Serial.print(" "); 
    }
    Serial.println(";");
    Serial.println("======= time and modes [end] ========="); 



    Serial.println("======= blink (low) ========="); 
    digitalWrite(ledPin, LOW);  
    digitalWrite(outputPin_1, LOW); 
    digitalWrite(outputPin_2, LOW); 
    digitalWrite(outputPin_3, LOW); 

    analogValue_1 = analogRead(analogPin_1); 
    analogValue_2 = analogRead(analogPin_2); 
    analogValue_3 = analogRead(analogPin_3); 
    Serial.print("a1 (low)  -> "); 
    Serial.println(analogValue_1); 
    Serial.print("a2 (low)  -> "); 
    Serial.println(analogValue_2); 
    Serial.print("a3 (low)  -> "); 
    Serial.println(analogValue_3); 
  
    delay(delayInterval);  
  
    Serial.println("======= blink (high) ========="); 

    // Blink the LED  
    digitalWrite(ledPin, HIGH);  
    digitalWrite(outputPin_1, HIGH); 
    digitalWrite(outputPin_2, HIGH); 
    digitalWrite(outputPin_3, HIGH); 

    analogValue_1 = analogRead(analogPin_1); 
    analogValue_2 = analogRead(analogPin_2); 
    analogValue_3 = analogRead(analogPin_3); 
    Serial.print("a1 (high) -> "); 
    Serial.println(analogValue_1); 
    Serial.print("a2 (high) -> "); 
    Serial.println(analogValue_2); 
    Serial.print("a3 (high) -> "); 
    Serial.println(analogValue_3); 

    delay(delayInterval);  
  }

}
