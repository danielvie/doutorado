#pragma once

#include <Arduino.h>
#include <chrono>
#include <vector>
#include <sstream>
#include <iostream>

struct Bin {
    bool b1;
    bool b2;
    bool b3;
    bool b4;
    bool b5;
    bool b6;
};

struct Bin Num2Bin(int n);


// int qpRun();

void GetValues(const char *s, int timeValues[], int modeValues[]);
void InitTimeMode(int timeValues[], int modeValues[], int N);
void SetValues(int timeValuesNew[], int modeValuesNew[], int timeValues[], int modeValues[], int N);
void parseString(const std::string& ref, std::vector<int64_t>& time, std::vector<int64_t>& mode);

void PrintValues(const std::vector<int64_t>& timeValues, const std::vector<int64_t>& modeValues);