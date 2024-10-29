#include <iostream>
#include <string>
#include <vector>
#include <sstream>

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

int main(int argc, char const *argv[])
{
    // base string to parse
    std::string ref = "10000,3,5,7,10;1,0,1,0,1;\n";
    std::vector<int16_t> time;
    std::vector<int16_t> mode;
    
    parseString(ref, time, mode);
    
    auto print = [](std::vector<int16_t> v) {
        for (auto vi : v) {
            std::cout << vi << " ";
        }
        std::cout << "\n";
    };
    
    std::cout << "print time: ";
    print(time);

    std::cout << "print mode: ";
    print(mode);
    
    return 0;
}