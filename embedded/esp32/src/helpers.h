#include <sstream>
#include <vector>
#include <driver/adc.h>


#define ADC_MAX 4095.0 // 12-bit ADC (2^12 - 1)
#define VOLTAGE_MAX 3.3


struct Bin {
    bool b1;
    bool b2;
    bool b3;
    bool b4;
    bool b5;
    bool b6;
};

namespace SignalWriteState {
    enum State {
        IDLE,
        RUN_SIGNAL,
        RUN_HIGH,
    };
}

namespace SignalReadState {
    enum State {
        IDLE,
        READ,
        READING,
        CHANGED,
    };
}

namespace AnalogReadState {
    enum State {
        IDLE,
        READ,
    };
}

struct Bin Num2Bin(uint64_t n);

void _parseSection(const std::string &section, std::vector<uint64_t> &result);
int parseSignal(const std::string &s, std::vector<uint64_t> &time, std::vector<uint64_t> &mode);

// float read_analog_01(void);
// float read_analog_02(void);
// float read_analog_03(void);
// float read_analog_04(void);
// float read_analog_05(void);
// float read_analog_06(void);