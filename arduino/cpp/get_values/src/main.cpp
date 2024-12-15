#include <iostream>
#include <string>
#include <sstream>
#include <vector>

void PrintV(int V[], int n);
void GetValues(const char* s, int timeValues[], int modeValues[]);

void parseSignal(const std::string &s, std::vector<int64_t> &time, std::vector<int64_t> &mode);
void _parseSection(const std::string &section, std::vector<int64_t> &result);

int main(int argc, char const *argv[])
{
    std::string s = "100,2,548,452,546540,5462,4564516,4562,00,300,400;1,4,1,5,1,85,3,1325,458,12,2,3,4";
    std::vector<int64_t> time, mode;
    
    try {
        parseSignal(s, time, mode);
        std::cout << s << std::endl;
        
        // printing time
        std::cout << "time: ";
        for (auto ti : time) {
            std::cout << ti << ", ";
        }
        std::cout << "\n";

        // printing mode
        std::cout << "mode: ";
        for (auto mi : mode) {
            std::cout << mi << ", ";
        }
        std::cout << "\n";
    }
    catch (const std::exception &e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}

void _parseSection(const std::string &section, std::vector<int64_t> &result) {
    std::stringstream ss(section);
    std::string item;
    
    while (std::getline(ss, item, ',')) {
        result.push_back(std::stoi(item));
    }
}

void parseSignal(const std::string &s, std::vector<int64_t> &time, std::vector<int64_t> &mode) {
    // clearing values
    time.clear();
    mode.clear();
    
    // parsing new values
    size_t semicolonPos = s.find(';');
    if (semicolonPos == std::string::npos) {
        throw std::runtime_error("No semicolon found");
    }
    
    // extract the parts
    std::string timeSection = s.substr(0, semicolonPos);
    std::string modeSection = s.substr(semicolonPos + 1);
    
    // parse each part
    _parseSection(timeSection, time);
    _parseSection(modeSection, mode);
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