/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */

#include <cstdio>
#include <cstring>
#include <cctype>
#include <cmath>
#include <memory>

#include "ble_controller.h"
#include "helper_analog.h"
#include "helper_note.h"
#include "helper_led.h"
#include "helper_common.h"
#include "signal_controller.h"
#include "messaging.pb.h"

#include "helper_matrix.h"

// REQUIRED to read the clock speed
#include "esp_rom_sys.h"
#include "esp_chip_info.h"

#include <stdbool.h>
#include "esp_cpu.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"

static const char *TAG = "BLE_LED";

static const char* signal_state_name() {
    return g_system_state.signal_state.load(std::memory_order_acquire) == SignalState::RUNNING
               ? "running"
               : "idle";
}

static const char* control_mode_name() {
    if (!g_control_enabled.load(std::memory_order_acquire)) {
        return "off";
    }
    return g_control_dry_run.load(std::memory_order_acquire) ? "compute" : "live";
}

static const char* signal_engine_name() {
    return g_signal_engine.load(std::memory_order_acquire) == SignalEngine::DMA
               ? "dma"
               : "cpu";
}

static const char* bool_json(bool value) {
    return value ? "true" : "false";
}

static void uart_print_status() {
    AnalogRuntimeStatus analog;
    analog_get_status(&analog);

    DataSet* active_ds = get_dataset_active();
    const char* active_set =
        g_active_set.load(std::memory_order_acquire) == SignalSet::SET_A ? "A" : "B";

    printf("UART_STATUS {");
    printf("\"signal\":\"%s\",", signal_state_name());
    printf("\"engine\":\"%s\",", signal_engine_name());
    printf("\"control\":\"%s\",", control_mode_name());
    printf("\"active_set\":\"%s\",", active_set);
    if (active_ds != nullptr && !std::isnan(active_ds->alpha)) {
        printf("\"alpha\":%.3f,", (double)active_ds->alpha);
    } else {
        printf("\"alpha\":null,");
    }
    printf("\"cycles\":{\"current\":%lu,\"total\":%lu},",
           (unsigned long)g_cycle_count,
           (unsigned long)g_cycle_nrun);
    printf("\"analog\":{");
    printf("\"seq\":%lu,", (unsigned long)analog.seq);
    printf("\"valid\":%s,", bool_json(analog.valid));
    printf("\"age_us\":%lu,", (unsigned long)analog.age_us);
    printf("\"budget_us\":%lu,", (unsigned long)analog.control_max_age_us);
    printf("\"floor_us\":%lu,", (unsigned long)analog.min_snapshot_age_us);
    printf("\"rate_tps\":%lu,", (unsigned long)analog.measured_triples_per_second);
    printf("\"raw\":{\"an3\":%lu,\"an5\":%lu,\"an6\":%lu},",
           (unsigned long)analog.raw_an3,
           (unsigned long)analog.raw_an5,
           (unsigned long)analog.raw_an6);
    printf("\"cal\":{\"an3\":%.4f,\"an5\":%.4f,\"an6\":%.4f},",
           (double)analog.calibrated_an3,
           (double)analog.calibrated_an5,
           (double)analog.calibrated_an6);
    printf("\"latency_us\":{\"avg\":%lu,\"p95\":%lu,\"min\":%lu,\"max\":%lu},",
           (unsigned long)analog.latency_avg_us,
           (unsigned long)analog.latency_p95_us,
           (unsigned long)analog.latency_min_us,
           (unsigned long)analog.latency_max_us);
    printf("\"age_used\":{\"max_us\":%lu,\"count\":%lu},",
           (unsigned long)analog.age_used_max_us,
           (unsigned long)analog.age_used_count);
    printf("\"counters\":{");
    printf("\"fault\":%lu,", (unsigned long)analog.fault_code);
    printf("\"overflows\":%lu,", (unsigned long)analog.overflow_count);
    printf("\"misses\":%lu,", (unsigned long)analog.miss_count);
    printf("\"consecutive_misses\":%lu,", (unsigned long)analog.consecutive_misses);
    printf("\"samples_rejected\":%lu,", (unsigned long)analog.samples_rejected);
    printf("\"order_anomalies\":%lu,", (unsigned long)analog.channel_order_anomalies);
    printf("\"partial_triples\":%lu,", (unsigned long)analog.partial_triples);
    printf("\"frame_drops\":%lu,", (unsigned long)analog.frame_drops);
    printf("\"pool_flushes\":%lu,", (unsigned long)analog.pool_flushes);
    printf("\"ts_fallbacks\":%lu", (unsigned long)analog.frame_ts_fallbacks);
    printf("}}}\n");
    fflush(stdout);
}

static void uart_print_agent_prepare_control_latency() {
    DataSet* active_ds = get_dataset_active();
    const bool has_gain = active_ds != nullptr && active_ds->gain_k.is_valid;
    if (has_gain) {
        analog_clear_consecutive_misses();
        analog_reset_age_used();
        analog_probe_reset();
        analog_phase_reset();
        g_control_dry_run.store(true, std::memory_order_release);
        g_control_enabled.store(true, std::memory_order_release);
        g_system_state.control_state.store(ControlState::ON, std::memory_order_release);
    }

    printf("AGENT_RESULT {");
    printf("\"task\":\"prepare-control-latency\",");
    printf("\"pass\":%s,", bool_json(has_gain));
    printf("\"signal\":\"%s\",", signal_state_name());
    printf("\"engine\":\"%s\",", signal_engine_name());
    printf("\"control\":\"%s\",", control_mode_name());
    printf("\"has_gain\":%s", bool_json(has_gain));
    printf("}\n");
    fflush(stdout);
}

static void uart_print_agent_control_latency() {
    AnalogRuntimeStatus analog;
    analog_get_status(&analog);

    const bool signal_running =
        g_system_state.signal_state.load(std::memory_order_acquire) == SignalState::RUNNING;
    // The telemetry snapshot refreshes once per control trigger (one signal
    // cycle), so its instantaneous age sampled at a random phase is nominally
    // up to one cycle, or two when a trigger found no new frame. This check
    // is "telemetry alive", bounded at two refresh intervals; the control
    // quality gate is age_used_* below, which measures what the control point
    // actually consumed.
    const bool over_budget = analog.age_us > 2 * analog.control_max_age_us;
    const bool used_over_budget =
        analog.age_used_count > 0 && analog.age_used_max_us > analog.control_max_age_us;
    const bool raw_zero =
        analog.raw_an3 == 0 || analog.raw_an5 == 0 || analog.raw_an6 == 0;
    const bool pass = signal_running && analog.valid && !over_budget && !used_over_budget &&
                      analog.consecutive_misses == 0 && analog.frame_ts_fallbacks == 0;

    printf("AGENT_RESULT {");
    printf("\"task\":\"control-latency\",");
    printf("\"pass\":%s,", bool_json(pass));
    printf("\"signal\":\"%s\",", signal_state_name());
    printf("\"engine\":\"%s\",", signal_engine_name());
    printf("\"control\":\"%s\",", control_mode_name());
    printf("\"snapshot_age_us\":%lu,", (unsigned long)analog.age_us);
    printf("\"budget_us\":%lu,", (unsigned long)analog.control_max_age_us);
    printf("\"floor_us\":%lu,", (unsigned long)analog.min_snapshot_age_us);
    printf("\"over_budget\":%s,", bool_json(over_budget));
    printf("\"age_used_max_us\":%lu,", (unsigned long)analog.age_used_max_us);
    printf("\"age_used_count\":%lu,", (unsigned long)analog.age_used_count);
    printf("\"age_used_over_budget_count\":%lu,",
           (unsigned long)analog.age_used_over_budget_count);
    printf("\"age_used_over_budget\":%s,", bool_json(used_over_budget));
    printf("\"control_triggers\":%lu,", (unsigned long)analog.control_trigger_count);
    printf("\"publishes\":%lu,", (unsigned long)analog.publish_count);
    printf("\"drain_max_us\":%lu,", (unsigned long)analog.control_drain_max_us);
    {
        static const char* probe_names[ANALOG_PROBE_STAGE_COUNT] = {
            "adc_read", "parse", "assemble", "calib",
            "publish", "snapshot", "math", "render",
        };
        printf("\"probe\":{");
        for (int stage = 0; stage < ANALOG_PROBE_STAGE_COUNT; ++stage) {
            uint32_t n, avg_ns, max_ns;
            analog_probe_get((AnalogProbeStage)stage, &n, &avg_ns, &max_ns);
            printf("\"%s\":{\"n\":%lu,\"avg_ns\":%lu,\"max_ns\":%lu}%s",
                   probe_names[stage], (unsigned long)n, (unsigned long)avg_ns,
                   (unsigned long)max_ns,
                   stage + 1 < ANALOG_PROBE_STAGE_COUNT ? "," : "");
        }
        printf("},");
    }
    {
        uint32_t phase_n, phase_min_us, phase_max_us;
        uint32_t phase_hist[ANALOG_PHASE_HIST_BINS];
        analog_phase_get(&phase_n, &phase_min_us, &phase_max_us, phase_hist);
        printf("\"phase\":{\"n\":%lu,\"min_us\":%lu,\"max_us\":%lu,"
               "\"bin_us\":%u,\"hist\":[",
               (unsigned long)phase_n, (unsigned long)phase_min_us,
               (unsigned long)phase_max_us, (unsigned)ANALOG_PHASE_HIST_BIN_US);
        for (int bin = 0; bin < ANALOG_PHASE_HIST_BINS; ++bin) {
            printf("%lu%s", (unsigned long)phase_hist[bin],
                   bin + 1 < ANALOG_PHASE_HIST_BINS ? "," : "");
        }
        printf("]},");
    }
    printf("\"rate_tps\":%lu,", (unsigned long)analog.measured_triples_per_second);
    printf("\"adc_latency_p95_us\":%lu,", (unsigned long)analog.latency_p95_us);
    printf("\"fault\":%lu,", (unsigned long)analog.fault_code);
    printf("\"misses\":%lu,", (unsigned long)analog.miss_count);
    printf("\"miss_stale\":%lu,", (unsigned long)analog.miss_stale_count);
    printf("\"miss_contention\":%lu,",
           (unsigned long)analog.miss_contention_count);
    printf("\"miss_missing\":%lu,", (unsigned long)analog.miss_missing_count);
    printf("\"consecutive_misses\":%lu,", (unsigned long)analog.consecutive_misses);
    printf("\"frame_drops\":%lu,", (unsigned long)analog.frame_drops);
    printf("\"pool_flushes\":%lu,", (unsigned long)analog.pool_flushes);
    printf("\"ts_fallbacks\":%lu,", (unsigned long)analog.frame_ts_fallbacks);
    printf("\"raw_zero\":%s,", bool_json(raw_zero));
    printf("\"raw\":{\"an3\":%lu,\"an5\":%lu,\"an6\":%lu}",
           (unsigned long)analog.raw_an3,
           (unsigned long)analog.raw_an5,
           (unsigned long)analog.raw_an6);
    printf("}\n");
    fflush(stdout);
}

static void uart_print_agent_result(const char* task) {
    if (strcmp(task, "prepare-control-latency") == 0 || strcmp(task, "prepare-latency") == 0) {
        uart_print_agent_prepare_control_latency();
        return;
    }
    if (strcmp(task, "control-latency") == 0 || strcmp(task, "latency") == 0) {
        uart_print_agent_control_latency();
        return;
    }
    printf("AGENT_ERROR {\"error\":\"unknown_task\",\"task\":\"%s\"}\n", task);
}

static void uart_normalize_command(char* line) {
    size_t write = 0;
    bool previous_space = true;
    for (size_t read = 0; line[read] != '\0'; ++read) {
        unsigned char ch = (unsigned char)line[read];
        if (ch == '\r' || ch == '\n') {
            break;
        }
        if (std::isspace(ch)) {
            if (!previous_space) {
                line[write++] = ' ';
                previous_space = true;
            }
            continue;
        }
        line[write++] = (char)std::tolower(ch);
        previous_space = false;
    }
    if (write > 0 && line[write - 1] == ' ') {
        write--;
    }
    line[write] = '\0';
}

static void uart_status_task(void* arg) {
    setvbuf(stdin, nullptr, _IONBF, 0);
    setvbuf(stdout, nullptr, _IONBF, 0);
    printf("UART_STATUS_READY commands=status,agent prepare-control-latency,agent control-latency,help\n");

    char line[64];
    for (;;) {
        if (fgets(line, sizeof(line), stdin) == nullptr) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
        uart_normalize_command(line);
        if (line[0] == '\0') {
            continue;
        }
        if (strcmp(line, "status") == 0 || strcmp(line, "s") == 0) {
            uart_print_status();
        } else if (strncmp(line, "agent ", 6) == 0) {
            uart_print_agent_result(line + 6);
        } else if (strcmp(line, "help") == 0 || strcmp(line, "h") == 0 || strcmp(line, "?") == 0) {
            printf("UART_STATUS_HELP commands: status|s, agent prepare-control-latency, agent control-latency, help|h|?\n");
        } else {
            printf("UART_STATUS_ERROR unknown_command=%s\n", line);
        }
    }
}

/* Blink control via State Machine */

void blink_stop_task(void)
{
    ESP_LOGI(TAG, "Stopping blink (State Machine)");
    g_system_state.led_mode.store(LedMode::NORMAL, std::memory_order_release);
}

void blink_create_task() {
    ESP_LOGI(TAG, "Starting blink (State Machine)");
    g_system_state.led_mode.store(LedMode::BLINKING, std::memory_order_release);
}

esp_err_t app_init() {
    esp_err_t ret;

    led_init();

    // initialize analog ports (ADC)
    analog_init();

    // Initialize Signal Controller GPIOs & Test Pattern
    signal_controller_init();

    // Initialize NVS
    ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Initialize BLE controller
    ret = ble_controller_init();
    if (ret) {
        ESP_LOGE("INIT", "BLE controller init failed: %s", esp_err_to_name(ret));
        return ret;
    }

    // Set initial alpha 0.5
    signal_set_alpha(0.5f);

    // Initialize LED Manager (State + Queue driven)
    led_create_manager_task();

    // create semaphore
    sem_analog_read_trigger = xSemaphoreCreateBinary();
    if (sem_analog_read_trigger == NULL) {
        ESP_LOGE("INIT", "Failed to create semaphore");
    }

    return ret;
}

static void analog_reading_task(void* arg) {
    ESP_LOGI(TAG, "Analog Task Started");

    for (;;) {
        if (ble_is_connected()) {
            AnalogRuntimeStatus analog_status;
            analog_get_status(&analog_status);

            BlePacket packet = BlePacket_init_zero;
            packet.which_payload = BlePacket_telemetry_tag;
            packet.payload.telemetry.an3 = analog_status.calibrated_an3;
            packet.payload.telemetry.an5 = analog_status.calibrated_an5;
            packet.payload.telemetry.an6 = analog_status.calibrated_an6;
            packet.payload.telemetry.timestamp_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;

            ble_send_protobuf(&packet);
        }
        vTaskDelay(pdMS_TO_TICKS(g_analog_monitor_period_ms));
    }
}

extern "C" void app_main(void)
{
    uint32_t cpu_freq_mhz = esp_rom_get_cpu_ticks_per_us();

    esp_chip_info_t chip_info;
    esp_chip_info(&chip_info);

    ESP_LOGW(TAG, "================================================");
    ESP_LOGW(TAG, "  Chip: %s | Rev: %d.%d | Cores: %d",
             CONFIG_IDF_TARGET, chip_info.revision / 100, chip_info.revision % 100, chip_info.cores);
    ESP_LOGW(TAG, "  CPU: %lu MHz | Flash: %s | BLE: %s",
             cpu_freq_mhz,
             (chip_info.features & CHIP_FEATURE_EMB_FLASH) ? "embedded" : "external",
             (chip_info.features & CHIP_FEATURE_BLE) ? "yes" : "no");
    ESP_LOGW(TAG, "================================================");

    esp_err_t ret = app_init();
    if (ret) {
        ESP_LOGW(TAG, "COULD NOT INITIALIZE APP!!");
    } else {
        signal_start_continuous();
    }

    xTaskCreatePinnedToCore(uart_status_task, "uart_status", 4096, NULL, tskIDLE_PRIORITY + 1, NULL, CORE_0);
    xTaskCreatePinnedToCore(analog_reading_task, "Analog Task", 8192, NULL, tskIDLE_PRIORITY + 1, NULL, CORE_0);
    // The acquisition task produces the control input on Core 0, sharing the
    // core with the BLE controller and Bluedroid host. At IDLE+8 the host's
    // ~1 ms processing bursts preempted it, so the freshest published triple
    // could be ~1 ms stale whenever a Core-1 control read landed in the gap.
    // notifications, so give it priority over app/BLE command work and let it
    // publish the newest control measurement before telemetry catches up.
    //
    // Priority tuning result (2026-07-06): the residual ~0.3-0.5% "snapshot
    // over budget" tail comes from ~1 ms Bluedroid-host bursts on this core.
    // Raising this task to IDLE+12 (still below the host) did not shrink the
    // tail; raising it above the host (IDLE+21) starved the Core-0 console/UART
    // task entirely. There is no safe priority window here that closes the tail
    // -- it is an architectural floor of sharing Core 0 with the BLE host while
    // Core 1 is reserved for the interrupt-disabled signal loop.
    xTaskCreatePinnedToCore(analog_acquisition_task, "Analog Acquisition", 4096, NULL, tskIDLE_PRIORITY + 8, NULL, CORE_0);

    matrix_test();

    blink(4);
}
