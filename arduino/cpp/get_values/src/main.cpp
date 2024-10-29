#include <iostream>
#include <string>
#include <sstream>

void PrintV(int V[], int n);
void GetValues(const char* s, int timeValues[], int modeValues[]);

int main(int argc, char const *argv[])
{
    std::string s = "100,200,300,400;1,2,3,4";
    
    int timeValues[4];
    int modeValues[4];
    
    GetValues(s.c_str(), timeValues, modeValues);
    PrintV(timeValues, 4);
    PrintV(modeValues, 4);

    std::cout << s << std::endl;
    return 0;
}

void PrintV(int V[], int n) {
    std::cout << "V: ";
    for (int i = 0; i < n; i++) {
        std::cout << V[i] << ", ";
    }
    std::cout << "\n";
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