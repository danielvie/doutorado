#include <iostream>
#include <chrono>
#include <string>
#include <vector>

int main(int argc, char const *argv[])
{
    // create data
    std::vector<int> time = {1, 2, 3, 6, 13};
    std::vector<std::string> message = {"hello", "world", "!", "esse eh o 6", "e agora o 13"};
    
    // track the starting time
    auto start = std::chrono::high_resolution_clock::now();
    
    // current index
    size_t index = 0;
    
    // iterate through vectors
    while (index < time.size()) {
        // calculate elapsed time
        auto now = std::chrono::high_resolution_clock::now();
        auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();
        
        // show time in console
        std::cout << "\relapsed time: " << elapsed_ms << " ms. >> " << std::flush;
        
        // check if elapsed time has reached
        if (elapsed_ms >= time[index]*1000) {
            // print corresponding message
            std::cout << message[index] << std::endl;

            // mode to the next message
            ++index;
        }
    }

    return 0;
}