#include "helpers.h"

struct Bin Num2Bin(uint64_t num) {
    auto b  = Bin();
    b.b1 = num & 0x1;
    b.b2 = num & 0x2;
    b.b3 = num & 0x4;
    b.b4 = num & 0x8;
    b.b5 = num & 0x16;
    b.b6 = num & 0x32;

    return b;
};

void _parseSection(const std::string &section, std::vector<uint64_t> &result) {
    std::stringstream ss(section);
    std::string item;
    
    while (std::getline(ss, item, ',')) {
        result.push_back(std::stoi(item));
    }
}

int parseSignal(const std::string &s, std::vector<uint64_t> &time, std::vector<uint64_t> &mode) {
    // clearing values
    time.clear();
    mode.clear();
    
    // parsing new values
    size_t semicolonPos = s.find(';');
    if (semicolonPos == std::string::npos) {
        throw std::runtime_error("No semicolon found");
        return 0;
    }
    
    // extract the parts
    std::string timeSection = s.substr(0, semicolonPos);
    std::string modeSection = s.substr(semicolonPos + 1);
    
    // parse each part
    _parseSection(timeSection, time);
    _parseSection(modeSection, mode);
    return 1;
}
