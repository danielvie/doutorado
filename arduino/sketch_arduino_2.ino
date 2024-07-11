const int ledPin = 13;    // Pin number for the LED  
const int outputPin = 9; // pin number for the digital output signal 
const int analogPin = A0; // pin number for the analog input 
int delayInterval = 1000; // Default delay interval in milliseconds  
bool commandON = false;

const int N = 10;
int timeValues[N];
int modeValues[N];

void setup() {  
  pinMode(ledPin, OUTPUT);  
  pinMode(outputPin, OUTPUT); 
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
  
  if (Serial.available() > 0) {  
    // Read the incoming data as a string  
    String data = Serial.readString();  
  
    commandON = true;
    Serial.println("----------------"); 
    Serial.println(data); 
    Serial.println("----------------"); 

    GetValues(data.c_str(), timeValues, modeValues);

    Serial.println("=======serial values========="); 
    for (int i = 0; i <  4; i++) {
      Serial.println(timeValues[i]); 
      Serial.println(modeValues[i]); 
    }
    Serial.println("=======serial values [end]========="); 



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
 
    if (i >= N/2 && commandON) {
      PIN = true; 
    } 
 
    // Blink the LED  
    digitalWrite(ledPin, PIN);  
    digitalWrite(outputPin, PIN); 
    delay(delay_);  
  } 
}
