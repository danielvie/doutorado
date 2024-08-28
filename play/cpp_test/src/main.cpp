#include <iostream>
#include <string>
#include "utils.h"

std::string msg = "1,2,3,4,5;1,0,1,0,1;";

const int N = 100;

int timeValues[N];
int modeValues[N];

int main(int argc, char const *argv[])
{

    Init(timeValues, modeValues, N);
    GetValues(msg.c_str(), timeValues, modeValues);
    
    Print(timeValues, modeValues, N);
    
    return 0;
    
}
