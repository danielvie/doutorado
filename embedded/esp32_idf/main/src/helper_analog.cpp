
#include "helper_analog.h"


// handle for the ADC unit
static adc_oneshot_unit_handle_t adc1_handle = NULL;
static const char* TAG_COMMON = "HELPER_COMMON";

void analog_init() {
    if (adc1_handle != NULL) {
        return;
    }
    
    ESP_LOGI(TAG_COMMON, "Initializing Analog Ports (ADC1)...");
    
    // init adc unit 1
    adc_oneshot_unit_init_cfg_t init_config1 = {
        .unit_id = ADC_UNIT_1,
        .clk_src = ADC_RTC_CLK_SRC_DEFAULT,
        .ulp_mode = ADC_ULP_MODE_DISABLE,
    };
    ESP_ERROR_CHECK(adc_oneshot_new_unit(&init_config1, &adc1_handle));
    
    // configure channels
    adc_oneshot_chan_cfg_t config = {
        .atten = ADC_ATTEN_DB_12,
        .bitwidth = ADC_BITWIDTH_DEFAULT,
    };
    
    // map channels
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_3, &config)); // AN1
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_5, &config)); // AN2
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_4, &config)); // AN3
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_7, &config)); // AN4
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_6, &config)); // AN5
    ESP_ERROR_CHECK(adc_oneshot_config_channel(adc1_handle, ADC_CHANNEL_0, &config)); // AN6
    
    ESP_LOGI(TAG_COMMON, "Analog Ports Initialized.");
}

float calib_from[] = {0.00, 0.07, 0.17, 0.26, 0.36, 0.46, 0.56, 0.66, 0.76, 0.86, 0.96, 1.06, 1.16, 1.27, 1.37, 1.46, 1.56, 1.67, 1.76, 1.86, 1.96, 2.06, 2.16, 2.27, 2.37, 2.49, 2.61, 2.75, 2.90, 3.07, 3.26, 3.30, 3.30};
float calib_to[] = {0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00, 1.10, 1.20, 1.30, 1.40, 1.50, 1.60, 1.70, 1.80, 1.90, 2.00, 2.10, 2.20, 2.30, 2.40, 2.50, 2.60, 2.70, 2.80, 2.90, 3.00, 3.10, 3.20, 3.30};
int calib_numel = sizeof(calib_from) / sizeof(calib_from[0]);

float esp32_calibration(float value) {

    // return value;
    // lower boundary
    if (value <= calib_from[0]) {
        return calib_to[0];
    }

    // higher boundary
    if (value >= calib_from[calib_numel - 1]) {
        return calib_to[calib_numel - 1];
    }

    // find the lookup interval
    for (int i = 0; i < calib_numel - 1; ++i) {
        if (value >= calib_from[i] && value <= calib_from[i + 1]) {
            float x1 = calib_from[i];
            float y1 = calib_to[i];
            float x2 = calib_from[i + 1];
            float y2 = calib_to[i + 1];

            // perform a linear interpolation
            if (x2 == x1) {
                return y1;
            }

            return y1 + (value - x1) * (y2 - y1) / (x2 - x1);
        }
    }

    // edge cases protection
    return calib_to[calib_numel - 1];
}

float analog_read_port(AnalogPort port) {
    if (adc1_handle == NULL) {
        ESP_LOGE(TAG_COMMON, "ADC not initialized! Call analog_init().");
        return -99.0;
    }
    
    adc_channel_t channel;
    switch (port) {
        case AnalogPort::AN1: channel = ADC_CHANNEL_3; break;
        case AnalogPort::AN2: channel = ADC_CHANNEL_5; break;
        case AnalogPort::AN3: channel = ADC_CHANNEL_4; break;
        case AnalogPort::AN4: channel = ADC_CHANNEL_7; break;
        case AnalogPort::AN5: channel = ADC_CHANNEL_6; break;
        case AnalogPort::AN6: channel = ADC_CHANNEL_0; break;
        default:
            ESP_LOGW(TAG_COMMON, "Invalid Analog Port requested");
            return -99.0;
    }
    
    // read raw value
    int raw_val = 0;
    if (adc_oneshot_read(adc1_handle, channel, &raw_val) == ESP_OK) {
        float voltage = ((float)raw_val/ADC_MAX)*VOLTAGE_MAX;
        voltage = esp32_calibration(voltage);
        return voltage;
    } else {
        ESP_LOGE(TAG_COMMON, "Failed to read ADC channel %d", channel);
        return -99.0;
    }
}