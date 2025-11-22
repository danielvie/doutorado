#include "signal_controller.h"
#include "helper_common.h" // Required for parsing
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <vector>
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
// DOUBLE BUFFERING DATA
// ---------------------------------------------------------------------------

static DataSet dataset_a;
static DataSet dataset_b;

// Track which set is currently active in the loop
static volatile SignalSet g_active_set = SignalSet::SET_A;

// Flag to tell the loop that the OTHER set has new data and we should swap
static volatile bool g_update_pending = false;

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

    // 2. Populate Default Pattern into Set A
    dataset_a.time_durations[0] = 10; 
    dataset_a.time_durations[1] = 20; 
    dataset_a.time_durations[2] = 10; 
    dataset_a.time_durations[3] = 20; 

    dataset_a.modes[0] = 7;      
    dataset_a.modes[1] = 0;      
    dataset_a.modes[2] = 7;      
    dataset_a.modes[3] = 0;      
    
    dataset_a.size = 4;

    // Ensure Set A is active initially
    g_active_set = SignalSet::SET_A;
    g_update_pending = false;

    ESP_LOGI(TAG, "Signal Controller Initialized. Default Pattern Size: %d", dataset_a.size);
}

// ---------------------------------------------------------------------------
// DATA UPDATE LOGIC (Called from BLE Task)
// ---------------------------------------------------------------------------
void signal_update_from_string(const std::string& message) {
    
    // 1. Determine which dataset is INACTIVE (Safe to write to)
    DataSet* target_dataset = nullptr;
    SignalSet target_set_enum;

    // We read the volatile variable once. 
    // If Set A is active, we write to Set B.
    if (g_active_set == SignalSet::SET_A) {
        target_dataset = &dataset_b;
        target_set_enum = SignalSet::SET_B;
    } else {
        target_dataset = &dataset_a;
        target_set_enum = SignalSet::SET_A;
    }

    // 2. Parse the signal string
    std::vector<uint32_t> times;
    std::vector<uint32_t> modes;

    // Assuming message format "SIGNAL:..." or just numbers. 
    // parse_signal expects the full string or substring? 
    // Based on helper_common, it parses "times;modes".
    // The caller (BLE) usually strips "SIGNAL:".
    // Let's handle both just in case.
    std::string clean_msg = message;
    if (clean_msg.rfind("SIGNAL:", 0) == 0) {
        clean_msg = clean_msg.substr(7);
    }

    if (parse_signal(clean_msg, times, modes) != 1) {
        ESP_LOGE(TAG, "Failed to parse signal string");
        return;
    }

    // 3. Copy to Fixed Size Array
    size_t count = times.size();
    if (count > MAX_SIGNAL_SIZE) {
        ESP_LOGW(TAG, "Signal truncated! %d > %d", count, MAX_SIGNAL_SIZE);
        count = MAX_SIGNAL_SIZE;
    }

    for (size_t i = 0; i < count; i++) {
        target_dataset->time_durations[i] = (uint16_t)times[i];
        target_dataset->modes[i] = (uint8_t)modes[i];
    }
    target_dataset->size = (uint8_t)count;

    ESP_LOGI(TAG, "Parsed %d segments into %s. Requesting swap...", 
             target_dataset->size, 
             (target_set_enum == SignalSet::SET_A ? "Set A" : "Set B"));

    // 4. Signal the Loop to Swap
    // The loop checks g_update_pending. 
    // We don't change g_active_set here; the loop does it to ensure sync.
    g_update_pending = true;
}

// ---------------------------------------------------------------------------
// CONTINUOUS LOOP TASK (High Priority)
// ---------------------------------------------------------------------------
static void signal_loop_task(void* arg) {
    ESP_LOGI(TAG, "Continuous Signal Task Started on Core %d", xPortGetCoreID());
    
    // Pre-calculate lookup tables
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

    // Pointer to the data we are currently looping over
    // Start with whatever init set up (Set A)
    DataSet* current_ptr = &dataset_a;

    // -------------------------------------------------------
    // DISABLE INTERRUPTS MANUALLY
    // -------------------------------------------------------
    portDISABLE_INTERRUPTS();

    while (s_signal_state == SIGNAL_RUNNING) {
        
        // ---------------------------------------------------
        // CHECK FOR UPDATES (Start of Loop)
        // ---------------------------------------------------
        if (g_update_pending) {
            // Swap logic
            if (g_active_set == SignalSet::SET_A) {
                // A was active, so B must be ready
                current_ptr = &dataset_b;
                g_active_set = SignalSet::SET_B;
            } else {
                // B was active, so A must be ready
                current_ptr = &dataset_a;
                g_active_set = SignalSet::SET_A;
            }
            // Clear flag
            g_update_pending = false;
        }

        // ---------------------------------------------------
        // EXECUTE PATTERN
        // ---------------------------------------------------
        // Use a local size variable for slight speed opt
        uint8_t sz = current_ptr->size;

        for (int i = 0; i < sz; i++) {
            uint8_t mode = current_ptr->modes[i] & 0x07;
            uint16_t us = current_ptr->time_durations[i];

            GPIO.out_w1ts = lut_set[mode];
            GPIO.out_w1tc = lut_clear[mode];

            if (us > 0) {
                esp_rom_delay_us(us);
            }
        }
    }

    // -------------------------------------------------------
    // RE-ENABLE INTERRUPTS
    // -------------------------------------------------------
    portENABLE_INTERRUPTS();

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
    
    if (dataset_a.size == 0) {
        ESP_LOGE(TAG, "Pattern empty, cannot start");
        return;
    }

    s_signal_state = SIGNAL_RUNNING;
    
    // Pin to Core 1 (APP_CPU)
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
    s_signal_state = SIGNAL_IDLE;
}

// Placeholder for interface compatibility
void signal_execute_sequence(const uint16_t* durations, const uint8_t* modes, int segment_count, int repeats) {
}