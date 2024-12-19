#include <sstream>
#include <vector>

struct Bin {
    bool b1;
    bool b2;
    bool b3;
    bool b4;
    bool b5;
    bool b6;
};

namespace SignalState {
    enum State {
        IDLE,
        RUN_SIGNAL,
        RUN_HIGH,
        RUN_AND_READ,
        SIGNAL_READING,
        SIGNAL_CHANGED,
        SIGNAL_CHANGED_IDLE,
    };
}

struct Bin Num2Bin(uint64_t n);

void _parseSection(const std::string &section, std::vector<uint64_t> &result);
int parseSignal(const std::string &s, std::vector<uint64_t> &time, std::vector<uint64_t> &mode);
