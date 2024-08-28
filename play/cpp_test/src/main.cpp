#include <iostream>
#include <fstream>
#include <string>
#include <chrono>
#include <thread>
#include "utils.h"

// std::string msg = "1,2,3,4,5,8;1,2,3,4,5,9;";

const int N = 100;

int timeValues[N];
int modeValues[N];

int cont = 0;

void loop();

std::chrono::time_point<std::chrono::steady_clock> origin;
std::chrono::milliseconds duration;

std::ifstream file;

std::string ReadFile()
{
    std::cout << "======================\n";
    std::cout << "reading file...\n";
    std::cout << "======================\n";
    std::ifstream file;

    std::string path = "message.txt";
    file.open(path);

    if (!file.is_open())
    {
        std::cerr << "Failed to open file: " << path << "\n";
        return "";
    }

    std::ostringstream ss;
    ss << file.rdbuf();
    std::string msg = ss.str();
    
    file.close();

    return msg;
}

int main(int argc, char const *argv[])
{

    origin = std::chrono::high_resolution_clock::now();
    
    
    for (;;)
    {
        loop();
    }

    return 0;
}

void loop()
{
    
    // reading msg from file
    std::string msg = ReadFile();


    Init(timeValues, modeValues, N);
    GetValues(msg.c_str(), timeValues, modeValues);

    std::cout << "\n";
    std::cout << "iter: ";
    std::cout << ++cont << "\n";
    std::cout << "\n";
    
    
    // Print(timeValues, modeValues, N);

    
    auto start = std::chrono::high_resolution_clock::now();
    std::chrono::time_point<std::chrono::steady_clock> end;
    std::chrono::milliseconds time;

    std::chrono::milliseconds t;
    int m;
    
    // 'for' buscando o tempo de ativacao
    int idx = 0;
    for (;;)
    {
        // getting values
        t = std::chrono::milliseconds(timeValues[idx]);
        m = modeValues[idx];
        
        // testing if trigger is on
        end = std::chrono::high_resolution_clock::now();
        time = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - origin);
        if (time > t)
        {
            t = std::chrono::milliseconds(timeValues[idx]);
            m = modeValues[idx];
            idx++;

            std::cout << "tempo: " << t << "\n";
            std::cout << "modo : " << m << "\n";
        }
        if (timeValues[idx] == -1)
        {
            std::cout << "end of loop at: " << duration << "\n";
            std::cout << "cast: " << duration.count() / 8000.0 << "\n";
            break;
        }

        std::this_thread::sleep_for(std::chrono::microseconds(1));
    }



    // std::this_thread::sleep_for(std::chrono::milliseconds(300));
}
