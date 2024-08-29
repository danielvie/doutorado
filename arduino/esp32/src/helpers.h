#pragma once

int qpRun();

void GetValues(const char *s, int timeValues[], int modeValues[]);
void Init(int timeValues[], int modeValues[], int N);
void SetValues(int timeValuesNew[], int modeValuesNew[], int timeValues[], int modeValues[], int N);
void Print(int timeValues[], int modeValues[], int N);