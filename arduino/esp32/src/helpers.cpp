#include <Arduino.h>
#include <iostream>
#include <sstream>
#include <chrono>
#include "helpers.h"
#include <vector>

struct Bin Num2Bin(int num) {
    auto b  = Bin();
    b.b1 = num & 0x1;
    b.b2 = num & 0x2;
    b.b3 = num & 0x4;
    b.b4 = num & 0x8;
    b.b5 = num & 0x16;
    b.b6 = num & 0x32;

    return b;
};

void GetValues(const char *s, int timeValues[], int modeValues[])
{
    // Buffer to store the substring parts
    char buffer[20];
    int bufferIndex = 0;
    int timeIndex = 0;
    int modeIndex = 0;
    bool isTimePart = true;

    for (int i = 0; s[i] != '\0'; ++i)
    {
        if (s[i] == ',' || s[i] == ';' || s[i + 1] == '\0')
        {
            if (s[i + 1] == '\0' && s[i] != ',' && s[i] != ';')
            {
                buffer[bufferIndex++] = s[i];
            }
            buffer[bufferIndex] = '\0';
            bufferIndex = 0;

            if (isTimePart)
            {
                timeValues[timeIndex++] = atoi(buffer);
            }
            else
            {
                modeValues[modeIndex++] = atoi(buffer);
            }

            if (s[i] == ';')
            {
                isTimePart = false;
            }
        }
        else
        {
            buffer[bufferIndex++] = s[i];
        }
    }
}

void parseValues(const std::string& input, std::vector<int16_t>& values, char delimiter) {
    std::stringstream ss(input);
    std::string token;
    
    while (std::getline(ss, token, delimiter)) {
        if (!token.empty()) {
            try {
                int value = std::stoi(token);
                if (value > INT16_MAX || value < INT16_MIN) {
                    throw std::out_of_range("Value outside int16_t range");
                }
                values.push_back(static_cast<int16_t>(value));
            }
            catch (const std::exception& e) {
                std::cerr << "Error parsing value '" << token << "': " << e.what() << std::endl;
            }
        }
    }
}

void parseString(const std::string& ref, std::vector<int16_t>& time, std::vector<int16_t>& mode) {
    size_t semicolonPos = ref.find(';');
    if (semicolonPos != std::string::npos) {
        // Extract time part (before semicolon)
        std::string timePart = ref.substr(0, semicolonPos);
        parseValues(timePart, time, ',');
        
        // Extract mode part (between semicolon and newline)
        std::string modePart = ref.substr(semicolonPos + 1);
        size_t newlinePos = modePart.find(';');
        if (newlinePos != std::string::npos) {
            modePart = modePart.substr(0, newlinePos);
        }
        parseValues(modePart, mode, ',');
    }
}

void Init(int timeValues[], int modeValues[], int N)
{
    for (int i = 0; i < N; i++)
    {
        timeValues[i] = -1;
        modeValues[i] = -1;
    }
}

void SetValues(int timeValuesNew[], int modeValuesNew[], int timeValues[], int modeValues[], int N)
{
    for (int i = 0; i < N; i++)
    {
        timeValuesNew[i] = timeValues[i];
        modeValuesNew[i] = modeValues[i];
    }
}

void Print_helper(int values[], int N)
{
    std::ostringstream msg;
    for (int i = 0; i < N; i++)
    {
        int v = values[i];
        if (v == -1)
        {
            break;
        }
        msg << values[i] << ",";
    }

    std::string out = msg.str();
    std::size_t pos = out.rfind(",");
    if (pos != std::string::npos)
    {
        out.replace(pos, 2, ";");
    }
    
    Serial.println(out.c_str());
}

void Print(int timeValues[], int modeValues[], int N)
{
    Serial.println("");
    Serial.println("timeValues: ");
    Print_helper(timeValues, N);
    Serial.println("\n");

    Serial.println("modeValues: ");
    Print_helper(modeValues, N);
    Serial.println("");
}