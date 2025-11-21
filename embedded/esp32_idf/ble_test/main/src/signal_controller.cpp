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
#include "esp_task_wdt.h" // Required to manage Watchdog

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
// HARDCODED SIGNAL DATA
// ---------------------------------------------------------------------------
// 100 cycles * 30us = 3000us (3ms) per burst.
#define TEST_CYCLES 100
#define TEST_SEGMENTS (TEST_CYCLES * 2)

static uint16_t DEMO_DURATIONS[TEST_SEGMENTS];
static uint8_t  DEMO_MODES[TEST_SEGMENTS];

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

    // 2. Populate Test Pattern
    // 10us UP (Mode 7: 111), 20us DOWN (Mode 0: 000)
    for (int i = 0; i < TEST_CYCLES; i++) {
        int idx = i * 2;
        
        // Segment A: UP (10us)
        DEMO_DURATIONS[idx]     = 10; 
        DEMO_MODES[idx]         = 7;  // Binary 111 (All pins HIGH)

        // Segment B: DOWN (20us)
        DEMO_DURATIONS[idx + 1] = 20; 
        DEMO_MODES[idx + 1]     = 0;  // Binary 000 (All pins LOW)
    }

    ESP_LOGI(TAG, "Signal Controller Initialized. Pattern: 10us UP / 20us DOWN (%d cycles)", TEST_CYCLES);
}

// This function runs inside a CRITICAL SECTION.
void IRAM_ATTR signal_execute_sequence(const uint16_t* durations, const uint8_t* modes, int count) {
    
    // 1. Pre-calculate lookup tables
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

    // 2. Enter Critical Section (Disables interrupts on THIS core)
    // Since we are pinned to Core 1, this pauses Core 1 interrupts (SysTick).
    // Core 0 (BLE/WiFi) continues running happily.
    taskENTER_CRITICAL(&signalMutex);

    for (int i = 0; i < count; i++) {
        uint8_t mode = modes[i] & 0x07;
        uint16_t us = durations[i];

        // Atomic GPIO update
        GPIO.out_w1ts = lut_set[mode];
        GPIO.out_w1tc = lut_clear[mode];

        // Busy wait for precision
        if (us > 0) {
            esp_rom_delay_us(us);
        }
    }
    
    // 3. Exit Critical Section
    taskEXIT_CRITICAL(&signalMutex);
}

// ---------------------------------------------------------------------------
// CONTINUOUS LOOP TASK
// ---------------------------------------------------------------------------
static void signal_loop_task(void* arg) {
    ESP_LOGI(TAG, "Continuous Signal Task Started on Core %d", xPortGetCoreID());
    
    // 1 Burst = ~3ms. 
    // We yield every ~150ms to keep the Watchdog happy without causing massive gaps.
    const uint32_t BURSTS_BEFORE_BREATHER = 50; 
    uint32_t burst_count = 0;

    while (s_signal_state == SIGNAL_RUNNING) {
        // Execute the burst (blocking, ~3ms)
        signal_execute_sequence(DEMO_DURATIONS, DEMO_MODES, TEST_SEGMENTS);
        
        burst_count++;
        
        if (burst_count >= BURSTS_BEFORE_BREATHER) {
            // BREATHER: 
            // A delay of 1 tick (10ms) is the safest way to clear the WDT 
            // without disabling it in menuconfig.
            // vTaskDelay(1); 
            burst_count = 0;
        } else {
            // NO DELAY:
            // Just loop immediately.
            // Since we are pinned to Core 1, and BLE is on Core 0, 
            // we don't need to yield for BLE's sake, only for the Watchdog's sake.
        }
    }

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
    
    s_signal_state = SIGNAL_RUNNING;
    
    xTaskCreatePinnedToCore(
        signal_loop_task,      // Function
        "sig_loop",            // Name
        4096,                  // Stack size
        NULL,                  // Parameters
        10,                    // Priority
        &s_signal_task_handle, // Handle
        1                      // Core ID
    );
}

void signal_stop() {
    if (s_signal_state == SIGNAL_IDLE) {
        ESP_LOGW(TAG, "Signal is not running");
        return;
    }

    ESP_LOGI(TAG, "Stopping Signal...");
    s_signal_state = SIGNAL_IDLE;
    
    // Immediate safety clear
    gpio_set_level(PIN_OUT_6, 0);
    gpio_set_level(PIN_OUT_5, 0);
    gpio_set_level(PIN_OUT_4, 0);
}