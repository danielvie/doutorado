#pragma once


struct Bin {
    bool b1;
    bool b2;
    bool b3;
    bool b4;
    bool b5;
    bool b6;
};

struct Bin Num2Bin(int n);


int qpRun();

void GetValues(const char *s, int timeValues[], int modeValues[]);
void Init(int timeValues[], int modeValues[], int N);
void SetValues(int timeValuesNew[], int modeValuesNew[], int timeValues[], int modeValues[], int N);
void Print(int timeValues[], int modeValues[], int N);