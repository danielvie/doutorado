#include <Arduino.h>
#include <iostream>
#include "qpOASES.hpp"
#include <chrono>
#include "helpers.h"

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

int qpRun()
{
  USING_NAMESPACE_QPOASES

  const int nV = 2;
  const int nC = 3;

  real_t H[nV * nV] = {1, -1,
                       -1, 2};
  real_t f[nV] = {-2, -6};
  real_t A[nV * nC] = {1, 1,
                       -1, 2,
                       2, 1};
  real_t lb[nV] = {-1e20, -1e20};
  real_t ub[nV] = {1e20, 1e20};
  real_t lbA[nC] = {-1e20, -1e20, -1e20};
  real_t ubA[nC] = {2, 2, 3};

  QProblem example(nV, nC);

  Options options;
  options.printLevel = qpOASES::PL_NONE;
  example.setOptions(options);

  // initialize QP
  int_t nWSR = 10; // maximum number of working set recalculations
  example.init(H, f, A, lb, ub, lbA, ubA, nWSR);

  // solve the QP
  real_t xOpt[nV];
  example.getPrimalSolution(xOpt);

  // print the solution
  Serial.println("Solution:");
  for (int i = 0; i < nV; ++i)
  {
    Serial.print("x["); 
    Serial.print(i); 
    Serial.print("]");
    Serial.println(xOpt[i]);
  }

  return 0;
}

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