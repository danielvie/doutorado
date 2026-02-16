#include "signal_controller.h"
#include "control_action.h"

static const char *TAG = "SIG_CTRL";

// ---------------------------------------------------------------------------
// HARDWARE CONFIGURATION
// ---------------------------------------------------------------------------
const uint32_t MASK_OUT_6 = (1U << PIN_OUT_6);
const uint32_t MASK_OUT_5 = (1U << PIN_OUT_5);
const uint32_t MASK_OUT_4 = (1U << PIN_OUT_4);
const uint32_t MASK_OUT_6_ = (1U << PIN_OUT_6_);
const uint32_t MASK_OUT_5_ = (1U << PIN_OUT_5_);
const uint32_t MASK_OUT_4_ = (1U << PIN_OUT_4_);

const uint32_t MASK_OUT_SIG = (1U << PIN_OUT_SIG);

static TaskHandle_t s_signal_task_handle = NULL;
// static volatile SignalState s_signal_state = SignalState::IDLE;

// ---------------------------------------------------------------------------
// DOUBLE BUFFERING DATA
// ---------------------------------------------------------------------------

DataSet g_dataset_a;
DataSet g_dataset_b;

volatile uint32_t g_cycle_count = 0;
volatile uint32_t g_cycle_nrun = 10000;

// Track which set is currently active in the loop
volatile SignalSet g_active_set = SignalSet::SET_A;

// Flag to tell the loop that the OTHER set has new data and we should swap
volatile bool g_ds_update_pending = false;

// delay -> cycle 1/240mhz = 1/240 ~= 4.166 ns
volatile uint32_t g_dead_time_cycles_up = 215;
volatile uint32_t g_dead_time_cycles_down = 215;

void signal_controller_init() {
    // 1. Configure GPIOs
    gpio_config_t io_conf = {};
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << PIN_OUT_6) | (1ULL << PIN_OUT_5) |
                           (1ULL << PIN_OUT_4) | (1ULL << PIN_OUT_6_) |
                           (1ULL << PIN_OUT_5_) | (1ULL << PIN_OUT_4_);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&io_conf);

    // Initialize LOW
    gpio_set_level(PIN_OUT_6, 0);
    gpio_set_level(PIN_OUT_5, 0);
    gpio_set_level(PIN_OUT_4, 0);
    gpio_set_level(PIN_OUT_6_, 0);
    gpio_set_level(PIN_OUT_5_, 0);
    gpio_set_level(PIN_OUT_4_, 0);
    gpio_set_level(PIN_OUT_SIG, 0);

    // 2. Populate Default Pattern into Set A
    g_dataset_a.time_durations[0] = 10;
    g_dataset_a.time_durations[1] = 20;
    g_dataset_a.time_durations[2] = 10;
    g_dataset_a.time_durations[3] = 20;

    // Mode 7 (111)
    g_dataset_a.modes_d6[0] = 1;
    g_dataset_a.modes_d5[0] = 1;
    g_dataset_a.modes_d4[0] = 1;
    // Mode 0 (000)
    g_dataset_a.modes_d6[1] = 0;
    g_dataset_a.modes_d5[1] = 0;
    g_dataset_a.modes_d4[1] = 0;
    // Mode 7 (111)
    g_dataset_a.modes_d6[2] = 1;
    g_dataset_a.modes_d5[2] = 1;
    g_dataset_a.modes_d4[2] = 1;
    // Mode 0 (000)
    g_dataset_a.modes_d6[3] = 0;
    g_dataset_a.modes_d5[3] = 0;
    g_dataset_a.modes_d4[3] = 0;

    g_dataset_a.size = 4;

    // Ensure Set A is active initially
    g_active_set = SignalSet::SET_A;
    g_ds_update_pending = false;

    ESP_LOGI(TAG, "Signal Controller Initialized. Default Pattern Size: %d",
             g_dataset_a.size);
}

// ---------------------------------------------------------------------------
// DATA UPDATE LOGIC (Called from BLE Task)
// ---------------------------------------------------------------------------
void signal_update_from_string(const std::string &message) {

    // 1. Determine which dataset is INACTIVE (Safe to write to)
    DataSet *target_dataset = nullptr;
    SignalSet target_signalset;

    // We read the volatile variable once.
    // If Set A is active, we write to Set B.
    if (g_active_set == SignalSet::SET_A) {
        target_dataset = &g_dataset_b;
        target_signalset = SignalSet::SET_B;
    } else {
        target_dataset = &g_dataset_a;
        target_signalset = SignalSet::SET_A;
    }

    // 2. Parse the signal string
    std::vector<uint32_t> times;
    std::vector<uint32_t> modes;

    // // clean "SIGNAL:{}" prefix
    // std::string clean_msg = message;
    // if (clean_msg.rfind("SIGNAL:", 0) == 0) {
    //     clean_msg = clean_msg.substr(7);
    // }

    if (parse_signal(message, times, modes) != 1) {
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
        target_dataset->time_durations[i] = times[i];
        uint32_t m = modes[i];
        target_dataset->modes_d4[i] = (m & 1) ? 1 : 0;
        target_dataset->modes_d5[i] = (m & 2) ? 1 : 0;
        target_dataset->modes_d6[i] = (m & 4) ? 1 : 0;
    }
    target_dataset->size = (uint8_t)count;

    ESP_LOGI(TAG, "Parsed %d segments into %s. Requesting swap...",
             target_dataset->size,
             (target_signalset == SignalSet::SET_A ? "Set A" : "Set B"));

    // mark upadte pending
    g_ds_update_pending = true;
}

// ---------------------------------------------------------------------------
// CONTINUOUS LOOP TASK (High Priority)
// ---------------------------------------------------------------------------
static void signal_loop_task(void *arg) {
    ESP_LOGI(TAG, "Continuous Signal Task Started on Core %d",
             xPortGetCoreID());

    // Pointer to the data we are currently looping over
    // Start with whatever init set up (Set A)
    DataSet *dataset = &g_dataset_a;

    // turn led on to indicate signal running (might need refactor to account
    // for blink signal)
    led_on();

    // -------------------------------------------------------
    // DISABLE INTERRUPTS MANUALLY
    // -------------------------------------------------------
    portDISABLE_INTERRUPTS();

    // Track last applied modes to detect transitions
    // Initialize to a value that forces a transition on first run (e.g. 2)
    uint32_t last_d6 = 2;
    uint32_t last_d5 = 2;
    uint32_t last_d4 = 2;

    while (g_system_state.signal_state == SignalState::RUNNING) {

        // ---------------------------------------------------
        // CHECK FOR UPDATES (Start of Loop)
        // ---------------------------------------------------
        if (g_ds_update_pending) {
            // Swap logic
            if (g_active_set == SignalSet::SET_A) {
                // A was active, so B must be ready
                dataset = &g_dataset_b;
                g_active_set = SignalSet::SET_B;
            } else {
                // B was active, so A must be ready
                dataset = &g_dataset_a;
                g_active_set = SignalSet::SET_A;
            }
            // Clear flag
            g_ds_update_pending = false;
        }

        // ---------------------------------------------------
        // CONTROL ACTION (if enabled and ADC data is fresh)
        // ---------------------------------------------------
        if (g_control_enabled && g_adc_fresh) {
            g_adc_fresh = false;
            float dtk[CONTROL_MAX_DTK];

            // compute control action
            bool res = compute_control_correction(dataset, g_adc_an3, g_adc_an5,
                                                  g_adc_an6, dtk);

            // update time durations
            if (res) {
                update_time_durations(dataset, dtk, dataset->size - 1,
                                      dataset->size);
            }
        }

        // ---------------------------------------------------
        // EXECUTE PATTERN
        // ---------------------------------------------------
        // Use a local size variable for slight speed opt
        uint8_t sz = dataset->size;

        for (int i = 0; i < sz; i++) {
            uint32_t us = dataset->time_durations[i];

            // Get current modes (0 or 1)
            uint32_t d6 = dataset->modes_d6[i] ? 1 : 0;
            uint32_t d5 = dataset->modes_d5[i] ? 1 : 0;
            uint32_t d4 = dataset->modes_d4[i] ? 1 : 0;

            // Check for transitions
            bool change_6 = (d6 != last_d6);
            bool change_5 = (d5 != last_d5);
            bool change_4 = (d4 != last_d4);

            // Determine which pins need to go to Dead Time (Low)
            uint32_t clear_mask = 0;
            if (change_6)
                clear_mask |= (MASK_OUT_6 | MASK_OUT_6_);
            if (change_5)
                clear_mask |= (MASK_OUT_5 | MASK_OUT_5_);
            if (change_4)
                clear_mask |= (MASK_OUT_4 | MASK_OUT_4_);

            // Determine the new state (High pins)
            uint32_t set_mask = 0;
            if (d6)
                set_mask |= MASK_OUT_6;
            else
                set_mask |= MASK_OUT_6_;
            if (d5)
                set_mask |= MASK_OUT_5;
            else
                set_mask |= MASK_OUT_5_;
            if (d4)
                set_mask |= MASK_OUT_4;
            else
                set_mask |= MASK_OUT_4_;

            // Apply Dead Time if needed
            if (clear_mask) {
                GPIO.out_w1tc = clear_mask;

                // Determine delay based on direction
                bool is_rising =
                    (change_6 && d6) || (change_5 && d5) || (change_4 && d4);
                uint32_t delay_cycles_val =
                    is_rising ? g_dead_time_cycles_up : g_dead_time_cycles_down;

                helper_delay_cycles(delay_cycles_val);

                // Apply new state
                GPIO.out_w1ts = set_mask;

                // Wait remaining time
                if (us > 1) {
                    esp_rom_delay_us(us - 1);
                }
            } else {
                // No transition, just ensure state (redundant but safe)
                GPIO.out_w1ts = set_mask;

                // Wait full time
                if (us > 0) {
                    esp_rom_delay_us(us);
                }
            }

            // Update last state
            last_d6 = d6;
            last_d5 = d5;
            last_d4 = d4;

            // trigger analog reading if needed
            if (i == 0 && g_system_state.ble_an_read_state !=
                              BLEAnalogReadState::DISABLED) {
                g_cycle_count = (g_cycle_count + 1) % g_cycle_nrun;
                if (g_cycle_count == 0) {
                    g_system_state.ble_an_read_state =
                        BLEAnalogReadState::READING;

                    xSemaphoreGive(sem_analog_read_trigger);
                }
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
    gpio_set_level(PIN_OUT_6_, 0);
    gpio_set_level(PIN_OUT_5_, 0);
    gpio_set_level(PIN_OUT_4_, 0);

    led_off();

    s_signal_task_handle = NULL;
    vTaskDelete(NULL);
}

void signal_start_continuous() {
    if (g_system_state.signal_state == SignalState::RUNNING ||
        s_signal_task_handle != NULL) {
        ESP_LOGW(TAG, "Signal already running!");
        return;
    }

    if (g_dataset_a.size == 0) {
        ESP_LOGE(TAG, "Pattern empty, cannot start");
        return;
    }

    g_system_state.signal_state = SignalState::RUNNING;

    // Pin to Core 1 (APP_CPU)
    xTaskCreatePinnedToCore(signal_loop_task, "sig_loop", 4096, NULL, 10,
                            &s_signal_task_handle, CORE_1);
}

void signal_stop() {
    if (g_system_state.signal_state == SignalState::IDLE) {
        ESP_LOGW(TAG, "Signal is not running");
        return;
    }

    ESP_LOGI(TAG, "Stopping Signal...");

    // updating signal when stop
    g_system_state.signal_state = SignalState::IDLE;
    if (g_system_state.ble_an_read_state != BLEAnalogReadState::DISABLED) {
        g_system_state.ble_an_read_state = BLEAnalogReadState::IDLE;
    }
}

DataSet *get_dataset_active(void) {
    DataSet *dataset =
        (g_active_set == SignalSet::SET_A) ? &g_dataset_a : &g_dataset_b;
    return dataset;
}

// Placeholder for interface compatibility
void signal_execute_sequence(const uint16_t *durations, const uint8_t *modes,
                             int segment_count, int repeats) {}