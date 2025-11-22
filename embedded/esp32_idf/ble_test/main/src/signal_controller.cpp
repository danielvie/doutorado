#include "signal_controller.h"
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "soc/gpio_struct.h"
#include "esp_rom_sys.h"
#include "esp_log.h"
#include "esp_task_wdt.h"

static const char *TAG = "SIG_CTRL";

// ---------------------------------------------------------------------------
// HARDWARE CONFIGURATION
// ---------------------------------------------------------------------------
#define PIN_OUT_6  GPIO_NUM_23 // Bit 2 (4)
#define PIN_OUT_5  GPIO_NUM_22 // Bit 1 (2)
#define PIN_OUT_4  GPIO_NUM_21 // Bit 0 (1)

const uint32_t MASK_OUT_6 = (1ULL << PIN_OUT_6);
const uint32_t MASK_OUT_5 = (1ULL << PIN_OUT_5);
const uint32_t MASK_OUT_4 = (1ULL << PIN_OUT_4);

// Critical section mutex
static portMUX_TYPE signalMutex = portMUX_INITIALIZER_UNLOCKED;

// ---------------------------------------------------------------------------
// STATE MANAGEMENT
// ---------------------------------------------------------------------------
enum SignalState {
    SIGNAL_IDLE,
    SIGNAL_RUNNING
};

static TaskHandle_t s_signal_task_handle = NULL;
static volatile SignalState s_signal_state = SIGNAL_IDLE;

// ---------------------------------------------------------------------------
// FLEXIBLE SIGNAL DATA
// ---------------------------------------------------------------------------

// static DataSet dataset_a;
static uint16_t DEMO_DURATIONS[MAX_SIGNAL_SIZE];
static uint8_t  DEMO_MODES[MAX_SIGNAL_SIZE];
static uint8_t  DEMO_SIZE = 0;

void signal_controller_init() {
    // 1. Configure GPIOs
    gpio_config_t io_conf = {};
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << PIN_OUT_6) | (1ULL << PIN_OUT_5) | (1ULL << PIN_OUT_4);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&io_conf);

    // Initialize LOW
    gpio_set_level(PIN_OUT_6, 0);
    gpio_set_level(PIN_OUT_5, 0);
    gpio_set_level(PIN_OUT_4, 0);

    // 2. Populate Pattern (As requested)
    DEMO_DURATIONS[0] = 5; // 10 us
    DEMO_DURATIONS[1] = 20; // 20 us
    DEMO_DURATIONS[2] = 5; // 10 us
    DEMO_DURATIONS[3] = 20; // 20 us
    DEMO_DURATIONS[4] = 10; // 10 us
    DEMO_DURATIONS[5] = 20; // 20 us

    DEMO_MODES[0] = 7;      // All High
    DEMO_MODES[1] = 0;      // All Low
    DEMO_MODES[2] = 7;      // All High
    DEMO_MODES[3] = 0;      // All Low
    DEMO_MODES[4] = 7;      // All High
    DEMO_MODES[5] = 0;      // All Low
    
    DEMO_SIZE = 6;

    ESP_LOGI(TAG, "Signal Controller Initialized. Pattern Size: %d", DEMO_SIZE);
}

// ---------------------------------------------------------------------------
// CONTINUOUS LOOP TASK
// ---------------------------------------------------------------------------
static void signal_loop_task(void* arg) {
    ESP_LOGI(TAG, "Continuous Signal Task Started on Core %d", xPortGetCoreID());
    
    // Pre-calculate lookup tables to make the loop as tight as possible
    uint32_t lut_set[8];   
    uint32_t lut_clear[8]; 

    for(int m=0; m<8; m++) {
        uint32_t s = 0;
        uint32_t c = 0;
        if (m & 4) s |= MASK_OUT_6; else c |= MASK_OUT_6;
        if (m & 2) s |= MASK_OUT_5; else c |= MASK_OUT_5;
        if (m & 1) s |= MASK_OUT_4; else c |= MASK_OUT_4;
        lut_set[m] = s;
        lut_clear[m] = c;
    }

    // -------------------------------------------------------
    // CRITICAL SECTION START
    // We disable interrupts and NEVER leave until Stop is called.
    // Since WDT is disabled for this core, this is safe.
    // -------------------------------------------------------
    taskENTER_CRITICAL(&signalMutex);

    uint16_t *time_durations = DEMO_DURATIONS;
    uint8_t *modes = DEMO_MODES;

    while (s_signal_state == SIGNAL_RUNNING) {
        // Iterate through the pattern
        for (int i = 0; i < DEMO_SIZE; i++) {
            // 1. Fetch data
            // uint8_t mode = DEMO_MODES[i] & 0x07;
            // uint16_t us = DEMO_DURATIONS[i];
            
            uint16_t us = time_durations[i];
            uint8_t mode = modes[i] & 0x07;

            // 2. Atomic GPIO write (Single CPU cycle)
            GPIO.out_w1ts = lut_set[mode];
            GPIO.out_w1tc = lut_clear[mode];

            // 3. Precision Delay
            if (us > 0) {
                esp_rom_delay_us(us);
            }
        }
        // Loop wraps around instantly here with negligible overhead
    }

    // -------------------------------------------------------
    // CRITICAL SECTION END
    // -------------------------------------------------------
    taskEXIT_CRITICAL(&signalMutex);

    ESP_LOGI(TAG, "Continuous Signal Task Stopped");
    
    // Ensure pins are low
    gpio_set_level(PIN_OUT_6, 0);
    gpio_set_level(PIN_OUT_5, 0);
    gpio_set_level(PIN_OUT_4, 0);

    s_signal_task_handle = NULL;
    vTaskDelete(NULL);
}

void signal_start_continuous() {
    if (s_signal_state == SIGNAL_RUNNING || s_signal_task_handle != NULL) {
        ESP_LOGW(TAG, "Signal already running!");
        return;
    }
    
    if (DEMO_SIZE == 0) {
        ESP_LOGE(TAG, "Pattern empty, cannot start");
        return;
    }

    s_signal_state = SIGNAL_RUNNING;
    
    // Pin to Core 1 (APP_CPU)
    // Since WDT is disabled, this task will take 100% of Core 1.
    xTaskCreatePinnedToCore(
        signal_loop_task,   
        "sig_loop",         
        4096,               
        NULL,               
        10,                 
        &s_signal_task_handle, 
        1                   
    );
}

void signal_stop() {
    if (s_signal_state == SIGNAL_IDLE) {
        ESP_LOGW(TAG, "Signal is not running");
        return;
    }

    ESP_LOGI(TAG, "Stopping Signal...");
    
    // This variable is volatile, so the loop on Core 1 will see this change
    // on its next iteration and break out of the while() loop.
    s_signal_state = SIGNAL_IDLE;
    
    // Note: We don't need to force pins low here immediately because the 
    // task will do it as soon as it exits the loop (which is microseconds away).
}

// Placeholder for interface compatibility
void signal_execute_sequence(const uint16_t* durations, const uint8_t* modes, int segment_count, int repeats) {
    // Not used in this optimized version
}