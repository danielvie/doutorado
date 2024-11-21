#include <Arduino.h>
#include "driver/timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "soc/timer_group_struct.h"
#include "driver/gpio.h"
#include "rom/ets_sys.h"

// Define output pin
#define PIN_DI4 GPIO_NUM_21
#define PIN_DI5 GPIO_NUM_22
#define PIN_DI6 GPIO_NUM_23

// Structure to hold pulse timing information
struct PulseTiming {
    uint32_t highTime;  // High time in microseconds
    uint32_t lowTime;   // Low time in microseconds
};

// Array of pulse patterns
const PulseTiming pulsePattern[] = {
    {1, 1},  // 2us HIGH, 2us LOW
    // {2, 2}   // 2us HIGH, 2us LOW
};

const int patternLength = sizeof(pulsePattern) / sizeof(pulsePattern[0]);
volatile int currentPulseIndex = 0;

// Timer group and index definitions
#define TIMER_GROUP TIMER_GROUP_0
#define TIMER_INDEX TIMER_0
#define TIMER_DIVIDER 80    // Hardware timer clock divider (80MHz/80 = 1MHz)
#define TIMER_SCALE   1     // Used to calculate counter values

// CPU frequency for cycle calculations (240MHz)
#define CPU_FREQ_MHZ 240

// Core assignments
#define TIMER_CORE 0    // Core for timer and pulse generation
#define MONITOR_CORE 1  // Core for monitoring task

// Convert microseconds to CPU cycles
#define US_TO_CYCLES(us) ((us) * CPU_FREQ_MHZ)

// Initialize GPIO using direct register access
void initGPIO() {
    gpio_pad_select_gpio(PIN_DI4);
    gpio_set_direction(PIN_DI4, GPIO_MODE_OUTPUT);
    gpio_set_level(PIN_DI4, 0);

    gpio_pad_select_gpio(PIN_DI5);
    gpio_set_direction(PIN_DI5, GPIO_MODE_OUTPUT);
    gpio_set_level(PIN_DI5, 0);

    gpio_pad_select_gpio(PIN_DI6);
    gpio_set_direction(PIN_DI6, GPIO_MODE_OUTPUT);
    gpio_set_level(PIN_DI6, 0);
}

// Inline assembly function to wait for exact number of cycles
static inline void IRAM_ATTR delay_cycles(unsigned cycles) {
    if (cycles > 0) {
        unsigned start = xthal_get_ccount();
        unsigned target = start + cycles;
        // Handle counter overflow
        if (target < start) {
            while (xthal_get_ccount() > start) {}
        }
        while (xthal_get_ccount() < target) {}
    }
}

// Inline functions for fast GPIO control
static inline void IRAM_ATTR gpio_set_high(gpio_num_t pin) {
    GPIO.out_w1ts = (1 << pin);
}

static inline void IRAM_ATTR gpio_set_low(gpio_num_t pin) {
    GPIO.out_w1tc = (1 << pin);
}

// Timer ISR handle
timer_isr_handle_t timerIsrHandle;

// Timer ISR function
bool IRAM_ATTR timerISR(void* arg) {
    // Clear the interrupt and re-enable alarm
    timer_group_clr_intr_status_in_isr(TIMER_GROUP, TIMER_INDEX);
    timer_group_enable_alarm_in_isr(TIMER_GROUP, TIMER_INDEX);
    
    // Get current pattern timing
    uint32_t highCycles = US_TO_CYCLES(pulsePattern[currentPulseIndex].highTime);
    uint32_t lowCycles = US_TO_CYCLES(pulsePattern[currentPulseIndex].lowTime);
    
    // Generate HIGH pulse
    gpio_set_high(PIN_DI4);
    delay_cycles(US_TO_CYCLES(1));

    // Generate LOW pulse
    gpio_set_low(PIN_DI4);
    delay_cycles(US_TO_CYCLES(1));
    
    // Move to next pulse pattern
    currentPulseIndex = (currentPulseIndex + 1) % patternLength;
    
    return false;
}

// Initialize hardware timer
void initTimer() {
    timer_config_t config = {
        .alarm_en = TIMER_ALARM_EN,
        .counter_en = TIMER_START,
        .intr_type = TIMER_INTR_LEVEL,
        .counter_dir = TIMER_COUNT_UP,
        .auto_reload = TIMER_AUTORELOAD_EN,
        .divider = TIMER_DIVIDER
    };

    ESP_ERROR_CHECK(timer_init(TIMER_GROUP, TIMER_INDEX, &config));
    ESP_ERROR_CHECK(timer_set_counter_value(TIMER_GROUP, TIMER_INDEX, 0));
    ESP_ERROR_CHECK(timer_enable_intr(TIMER_GROUP, TIMER_INDEX));
    ESP_ERROR_CHECK(timer_isr_callback_add(TIMER_GROUP, TIMER_INDEX, timerISR, NULL, 0));
}

// Task to monitor the pulse generator
void monitorTask(void *pvParameters) {
    // Set task priority to maximum for this core
    vTaskPrioritySet(NULL, configMAX_PRIORITIES - 1);
    
    Serial.println("Monitor task started on core ");
    Serial.println(xPortGetCoreID());
    
    while (1) {
        Serial.printf("Current pulse index: %d\n", currentPulseIndex);
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

void setup() {
    // Initialize serial for debugging
    Serial.begin(115200);
    while (!Serial) {
        delay(100);
    }
    Serial.println("\nStarting pulse generator...");
    
    // Set CPU frequency to maximum
    setCpuFrequencyMhz(240);
    
    // Configure GPIO
    initGPIO();

    // Create monitor task pinned to core 1
    xTaskCreatePinnedToCore(
        monitorTask,
        "MonitorTask",
        4096,
        NULL,
        1,  // Priority
        NULL,
        MONITOR_CORE  // Run on core 1
    );

    // Initialize and start timer (will run on core 0)
    Serial.println("Initializing timer...");
    initTimer();

    // Start timer with initial period
    uint64_t initialPeriod = (pulsePattern[0].highTime + 
                             pulsePattern[0].lowTime) * TIMER_SCALE;
    ESP_ERROR_CHECK(timer_set_alarm_value(TIMER_GROUP, TIMER_INDEX, initialPeriod));
    ESP_ERROR_CHECK(timer_start(TIMER_GROUP, TIMER_INDEX));

    Serial.println("Setup complete!");
}

void loop() {
    // Main loop runs on core 0 - keep it minimal
    vTaskDelay(pdMS_TO_TICKS(1000));
}