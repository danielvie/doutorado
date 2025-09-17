#include "analog_controller.h"
#include "ble_controller.h"
#include <cmath>

volatile float g_voltage_03 = -1.0;
volatile float g_voltage_05 = -1.0;
volatile float g_voltage_06 = -1.0;

#define pdUS_TO_TICKS(us) (((us) * configTICK_RATE_HZ + 500000) / 1000000)

void analogTask(void *parameter) {
    
    const float scale_factor = 10.0 / 6.0;

    while (1) {
        // Read analog values from multiple channels and update globals
        g_voltage_03 = read_analog(AnalogPort::AN3)*scale_factor;
        g_voltage_05 = read_analog(AnalogPort::AN5)*scale_factor;
        g_voltage_06 = read_analog(AnalogPort::AN6)*scale_factor;

        vTaskDelay(pdMS_TO_TICKS(500)); 
    }
}