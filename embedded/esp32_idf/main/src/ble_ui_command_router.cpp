#include "messaging.pb.h"
#include "ui_command_router.h"

#include <algorithm>
#include <atomic>
#include <cstring>
#include <string>

#include "ble_controller.h"
#include "esp_log.h"
#include "esp_rom_sys.h"
#include "esp_timer.h"
#include "helper_analog.h"
#include "helper_common.h"
#include "helper_led.h"
#include "signal_controller.h"

#include "driver/gpio.h"
#include "freertos/semphr.h"
#include "freertos/task.h"

extern "C" {
#include "cJSON.h"
}

static const char* TAG = "UI_CMD";

struct UiCommandContext {
    const UiCommand& command;
    cJSON* json;
};

using UiCommandHandler = UiCommandResultData (*)(const UiCommandContext& ctx);

struct UiCommandEntry {
    const char* name;
    UiCommandHandler handler;
};

static UiCommandEntry s_commands[32];
static size_t s_command_count = 0;
volatile uint32_t g_dead_time_tail_overhead_cycles = DEFAULT_DEAD_TIME_TAIL_OVERHEAD_CYCLES;
volatile uint32_t g_dead_time_us = DEFAULT_DEAD_TIME_US;
static bool s_dead_time_request_valid = false;
static std::atomic<bool> s_analog_test_running(false);
static SemaphoreHandle_t s_analog_test_result_mutex = NULL;
static AnalogDiagnosticResult s_analog_test_result = AnalogDiagnosticResult_init_zero;

struct AnalogDiagnosticTestConfig {
    uint32_t duration_ms;
};

static UiCommandResultData ok(const char* message = "ok", const std::string& json = "") {
    return {
        .ok = true,
        .code = "ok",
        .message = message,
        .json = json,
    };
}

static UiCommandResultData invalid_arg(const char* message) {
    return {
        .ok = false,
        .code = "invalid_argument",
        .message = message,
        .json = "",
    };
}

static UiCommandResultData unknown_command(const char* name) {
    return {
        .ok = false,
        .code = "unknown_command",
        .message = std::string("Unknown command: ") + name,
        .json = "",
    };
}

static bool register_command(const char* name, UiCommandHandler handler) {
    if (s_command_count >= std::size(s_commands)) {
        ESP_LOGE(TAG, "Command registry full, cannot register %s", name);
        return false;
    }

    s_commands[s_command_count++] = {
        .name = name,
        .handler = handler,
    };
    return true;
}

static bool json_get_u32(cJSON* root, const char* key, uint32_t* out) {
    cJSON* value = cJSON_GetObjectItem(root, key);
    if (!cJSON_IsNumber(value) || value->valuedouble < 0.0) {
        return false;
    }

    *out = (uint32_t)value->valuedouble;
    return true;
}

static bool json_get_float(cJSON* root, const char* key, float* out) {
    cJSON* value = cJSON_GetObjectItem(root, key);
    if (!cJSON_IsNumber(value)) {
        return false;
    }

    *out = (float)value->valuedouble;
    return true;
}

static UiCommandResultData handle_system_list_commands(const UiCommandContext& ctx) {
    std::string json = "{\"commands\":\"";
    for (size_t i = 0; i < s_command_count; ++i) {
        if (i > 0) {
            json += ",";
        }
        json += s_commands[i].name;
    }
    json += "\"}";

    return ok("ok", json);
}

static UiCommandResultData handle_system_get_status(const UiCommandContext& ctx) {
    ble_send_status();
    return ok("Status notification queued");
}

static UiCommandResultData handle_system_hello(const UiCommandContext& ctx) {
    ble_send_log(BleLogLevel_BLE_LOG_INFO, 
        "bla! \
        agora do windows!!\
        terug op mac hehaaaa!!\
        !!\
        "
    );
    
    return ok("Hello response sent");
}


static UiCommandResultData handle_signal_start(const UiCommandContext& ctx) {
    signal_start_continuous();
    return ok("Signal started");
}

static UiCommandResultData handle_signal_stop(const UiCommandContext& ctx) {
    signal_stop();
    return ok("Signal stopped");
}

static UiCommandResultData handle_signal_set_alpha(const UiCommandContext& ctx) {
    float alpha;
    if (!json_get_float(ctx.json, "alpha", &alpha)) {
        return invalid_arg("Expected numeric alpha");
    }

    signal_set_alpha(alpha);
    return ok("Alpha updated");
}

static UiCommandResultData handle_signal_set_pattern(const UiCommandContext& ctx) {
    cJSON* time = cJSON_GetObjectItem(ctx.json, "time");
    cJSON* mode = cJSON_GetObjectItem(ctx.json, "mode");
    if (!cJSON_IsString(time) || !cJSON_IsString(mode)) {
        return invalid_arg("Expected string time and mode");
    }

    std::string pattern = std::string(time->valuestring) + ";" + mode->valuestring;
    signal_update_from_string(pattern);
    return ok("Signal pattern updated");
}

static UiCommandResultData handle_signal_set_cycle_interval(const UiCommandContext& ctx) {
    uint32_t cycles;
    if (!json_get_u32(ctx.json, "cycles", &cycles)) {
        return invalid_arg("Expected numeric cycles");
    }
    if (cycles == 0) {
        return invalid_arg("cycles must be greater than zero");
    }

    g_cycle_nrun = cycles;
    ESP_LOGI(TAG, "Set cycle interval to %lu", cycles);
    return ok("Cycle interval updated");
}

static void set_dead_time_us(uint32_t time_us) {
    g_dead_time_us = time_us;
    s_dead_time_request_valid = true;

    // Measure the delay helper overhead so requested dead time stays close to wall time.
    uint32_t overhead_cycles = UINT32_MAX;
    for (uint32_t i = 0; i < 16; ++i) {
        const uint32_t start = esp_cpu_get_cycle_count();
        helper_delay_cycles(0);
        const uint32_t cycles = esp_cpu_get_cycle_count() - start;
        if (cycles < overhead_cycles) {
            overhead_cycles = cycles;
        }
    }
    // Add the GPIO-write tail measured on the scope after the delay helper returns.
    overhead_cycles += g_dead_time_tail_overhead_cycles;

    // Convert the user-facing microsecond values to raw CPU cycles.
    const uint32_t ticks_per_us = esp_rom_get_cpu_ticks_per_us();
    const uint64_t requested_cycles = (uint64_t)time_us * ticks_per_us;

    // Subtract only the helper overhead; clamp tiny requests to zero instead of underflowing.
    const uint64_t compensated_cycles =
        requested_cycles > overhead_cycles ? requested_cycles - overhead_cycles : 0;

    // Store the same compensated cycle count for both directions in the hot signal loop.
    const uint32_t cycles =
        compensated_cycles > UINT32_MAX ? UINT32_MAX : (uint32_t)compensated_cycles;

    g_dead_time_cycles_up = cycles;
    g_dead_time_cycles_down = cycles;
    signal_precompute_steps(&g_dataset_a);
    signal_precompute_steps(&g_dataset_b);
    ESP_LOGI(TAG,
             "Set dead time=%lu us (%lu cycles), overhead=%lu cycles, tail=%lu cycles",
             time_us,
             cycles,
             overhead_cycles,
             g_dead_time_tail_overhead_cycles);
}

static UiCommandResultData busy(const char* message) {
    return {
        .ok = false,
        .code = "busy",
        .message = message,
        .json = "",
    };
}

static void analog_test_set_message(AnalogDiagnosticResult* result, const char* message) {
    if (result == nullptr) {
        return;
    }
    strncpy(result->message, message ? message : "", sizeof(result->message) - 1);
    result->message[sizeof(result->message) - 1] = '\0';
}

static void analog_test_store_result(const AnalogDiagnosticResult& result) {
    if (s_analog_test_result_mutex &&
        xSemaphoreTake(s_analog_test_result_mutex, pdMS_TO_TICKS(100)) == pdPASS) {
        s_analog_test_result = result;
        xSemaphoreGive(s_analog_test_result_mutex);
    }
}

static AnalogDiagnosticResult analog_test_get_result() {
    AnalogDiagnosticResult result = AnalogDiagnosticResult_init_zero;
    if (s_analog_test_result_mutex &&
        xSemaphoreTake(s_analog_test_result_mutex, pdMS_TO_TICKS(100)) == pdPASS) {
        result = s_analog_test_result;
        xSemaphoreGive(s_analog_test_result_mutex);
    } else {
        result.running = true;
        analog_test_set_message(&result, "Diagnostic result is busy");
    }
    return result;
}

static void analog_test_send_result(const AnalogDiagnosticResult& result) {
    BlePacket packet = BlePacket_init_zero;
    packet.which_payload = BlePacket_analog_diagnostic_result_tag;
    packet.payload.analog_diagnostic_result = result;
    ble_send_protobuf(&packet);
}

static void analog_diagnostic_test_task(void* arg) {
    AnalogDiagnosticTestConfig config = *static_cast<AnalogDiagnosticTestConfig*>(arg);
    delete static_cast<AnalogDiagnosticTestConfig*>(arg);

    AnalogRuntimeStatus before;
    AnalogRuntimeStatus after;
    analog_get_status(&before);
    uint64_t start_us = (uint64_t)esp_timer_get_time();

    led_on();
    signal_start_continuous();
    vTaskDelay(pdMS_TO_TICKS(config.duration_ms));
    signal_stop();
    vTaskDelay(pdMS_TO_TICKS(20));
    led_off();

    uint64_t end_us = (uint64_t)esp_timer_get_time();
    analog_get_status(&after);

    uint32_t seq_delta = after.seq >= before.seq ? after.seq - before.seq : 0;
    uint32_t miss_delta = after.miss_count >= before.miss_count ? after.miss_count - before.miss_count : 0;
    uint32_t overflow_delta =
        after.overflow_count >= before.overflow_count ? after.overflow_count - before.overflow_count : 0;

    SignalTimingCompact timing;
    signal_get_timing_compact(&timing);

    AnalogDiagnosticResult result = AnalogDiagnosticResult_init_zero;
    result.valid = true;
    result.running = false;
    result.duration_ms = config.duration_ms;
    result.elapsed_us = end_us - start_us;
    result.seq_delta = seq_delta;
    result.miss_delta = miss_delta;
    result.overflow_delta = overflow_delta;
    result.seq = after.seq;
    result.age_us = after.age_us;
    result.rate_tps = after.measured_triples_per_second;
    result.raw_an3 = after.raw_an3;
    result.raw_an5 = after.raw_an5;
    result.raw_an6 = after.raw_an6;
    result.cal_an3 = after.calibrated_an3;
    result.cal_an5 = after.calibrated_an5;
    result.cal_an6 = after.calibrated_an6;
    result.latency_avg_us = after.latency_avg_us;
    result.latency_p95_us = after.latency_p95_us;
    result.fault_code = after.fault_code;
    result.timing_samples = timing.samples;
    result.playback_avg_us = timing.playback_avg_us;
    result.loop_us = timing.loop_us;
    result.overruns = timing.overruns;
    result.timing_faults = timing.timing_faults;
    analog_test_set_message(&result, "Analog diagnostic test complete");

    analog_test_store_result(result);
    ble_send_log(BleLogLevel_BLE_LOG_INFO, "Analog diagnostic test finished; fetch debug.analog_test_result");
    s_analog_test_running.store(false, std::memory_order_release);
    vTaskDelete(NULL);
}

static UiCommandResultData handle_signal_set_dead_time(const UiCommandContext& ctx) {
    uint32_t time_us;
    if (!json_get_u32(ctx.json, "time_us", &time_us)) {
        return invalid_arg("Expected numeric time_us");
    }

    set_dead_time_us(time_us);
    return ok("Dead time updated");
}

static UiCommandResultData handle_signal_set_dead_time_tail_overhead(const UiCommandContext& ctx) {
    uint32_t cycles;
    if (!json_get_u32(ctx.json, "cycles", &cycles)) {
        return invalid_arg("Expected numeric cycles");
    }

    g_dead_time_tail_overhead_cycles = cycles;
    if (s_dead_time_request_valid) {
        set_dead_time_us(g_dead_time_us);
    }

    ESP_LOGI(TAG, "Set dead time tail overhead to %lu cycles", cycles);
    return ok("Dead time tail overhead updated");
}

static UiCommandResultData handle_analog_set_monitor_period(const UiCommandContext& ctx) {
    uint32_t period_ms;
    if (!json_get_u32(ctx.json, "period_ms", &period_ms)) {
        return invalid_arg("Expected numeric period_ms");
    }
    if (period_ms == 0) {
        return invalid_arg("period_ms must be greater than zero");
    }

    g_analog_monitor_period_ms = period_ms;
    ESP_LOGI(TAG, "Set analog monitor period to %lu ms", period_ms);
    return ok("Analog monitor period updated");
}

static UiCommandResultData handle_analog_set_acquisition_period(const UiCommandContext& ctx) {
    uint32_t period_us;
    if (!json_get_u32(ctx.json, "period_us", &period_us)) {
        return invalid_arg("Expected numeric period_us");
    }
    if (period_us > 1000000) {
        return invalid_arg("period_us must be <= 1000000");
    }

    g_analog_acquisition_period_us = period_us;
    ESP_LOGI(TAG, "Set analog acquisition period to %lu us", period_us);
    return ok("Analog acquisition period updated");
}

static UiCommandResultData handle_analog_read_once(const UiCommandContext& ctx) {
    ble_send_analog_read();
    return ok("Analog read notification queued");
}

static UiCommandResultData handle_analog_ble_read_enable(const UiCommandContext& ctx) {
    g_system_state.ble_an_read_state.store(BLEAnalogReadState::IDLE, std::memory_order_release);
    return ok("BLE analog reads enabled");
}

static UiCommandResultData handle_analog_ble_read_disable(const UiCommandContext& ctx) {
    g_system_state.ble_an_read_state.store(BLEAnalogReadState::DISABLED, std::memory_order_release);
    return ok("BLE analog reads disabled");
}

static UiCommandResultData handle_control_enable(const UiCommandContext& ctx) {
    g_control_enabled.store(true, std::memory_order_release);
    g_system_state.control_state.store(ControlState::ON, std::memory_order_release);
    return ok("Control enabled");
}

static UiCommandResultData handle_control_disable(const UiCommandContext& ctx) {
    g_control_enabled.store(false, std::memory_order_release);
    g_system_state.control_state.store(ControlState::OFF, std::memory_order_release);
    return ok("Control disabled");
}

static UiCommandResultData handle_led_on(const UiCommandContext& ctx) {
    g_system_state.led_mode.store(LedMode::NORMAL, std::memory_order_release);
    led_on();
    return ok("LED on");
}

static UiCommandResultData handle_led_off(const UiCommandContext& ctx) {
    g_system_state.led_mode.store(LedMode::NORMAL, std::memory_order_release);
    led_off();
    return ok("LED off");
}

static UiCommandResultData handle_led_blink(const UiCommandContext& ctx) {
    uint32_t delay1_ms;
    uint32_t delay2_ms;
    if (json_get_u32(ctx.json, "delay1_ms", &delay1_ms) && delay1_ms > 0) {
        g_blink_delay1_ms.store((uint16_t)delay1_ms, std::memory_order_release);
    }
    if (json_get_u32(ctx.json, "delay2_ms", &delay2_ms) && delay2_ms > 0) {
        g_blink_delay2_ms.store((uint16_t)delay2_ms, std::memory_order_release);
    }

    g_system_state.led_mode.store(LedMode::BLINKING, std::memory_order_release);
    return ok("LED blinking");
}

static UiCommandResultData handle_debug_dataset_active(const UiCommandContext& ctx) {
    ble_send_dataset(get_dataset_active(), g_active_set);
    return ok("Active dataset notification queued");
}

static UiCommandResultData handle_debug_dataset_a(const UiCommandContext& ctx) {
    ble_send_dataset(&g_dataset_a, SignalSet::SET_A);
    return ok("Dataset A notification queued");
}

static UiCommandResultData handle_debug_dataset_b(const UiCommandContext& ctx) {
    ble_send_dataset(&g_dataset_b, SignalSet::SET_B);
    return ok("Dataset B notification queued");
}

static UiCommandResultData handle_debug_matrix_a(const UiCommandContext& ctx) {
    ble_send_status_matrix(SignalSet::SET_A);
    return ok("Matrix A notification queued");
}

static UiCommandResultData handle_debug_matrix_b(const UiCommandContext& ctx) {
    ble_send_status_matrix(SignalSet::SET_B);
    return ok("Matrix B notification queued");
}

static UiCommandResultData handle_debug_log_duration(const UiCommandContext& ctx) {
    ble_send_log_duration();
    return ok("Duration log notification queued");
}

static UiCommandResultData handle_debug_signal_timing(const UiCommandContext& ctx) {
    return ok("Signal timing snapshot", signal_get_timing_snapshot_json());
}

static UiCommandResultData handle_debug_analog_test_run(const UiCommandContext& ctx) {
    if (s_analog_test_running.load(std::memory_order_acquire)) {
        return busy("Analog diagnostic test already running");
    }

    if (g_system_state.signal_state.load(std::memory_order_acquire) == SignalState::RUNNING) {
        return busy("Signal is already running; stop it before starting the diagnostic test");
    }

    uint32_t duration_ms = 2000;
    cJSON* duration = cJSON_GetObjectItem(ctx.json, "duration_ms");
    if (duration != nullptr && !json_get_u32(ctx.json, "duration_ms", &duration_ms)) {
        return invalid_arg("Expected numeric duration_ms");
    }
    if (duration_ms == 0 || duration_ms > 60000) {
        return invalid_arg("duration_ms must be between 1 and 60000");
    }

    auto* config = new AnalogDiagnosticTestConfig{ .duration_ms = duration_ms };
    s_analog_test_running.store(true, std::memory_order_release);
    AnalogDiagnosticResult running_result = AnalogDiagnosticResult_init_zero;
    running_result.running = true;
    running_result.duration_ms = duration_ms;
    analog_test_set_message(&running_result, "Analog diagnostic test running");
    analog_test_store_result(running_result);

    BaseType_t created = xTaskCreatePinnedToCore(
        analog_diagnostic_test_task,
        "analog_diag",
        8192,
        config,
        tskIDLE_PRIORITY + 2,
        NULL,
        CORE_0);

    if (created != pdPASS) {
        delete config;
        s_analog_test_running.store(false, std::memory_order_release);
        AnalogDiagnosticResult failed_result = AnalogDiagnosticResult_init_zero;
        analog_test_set_message(&failed_result, "Failed to start analog diagnostic test");
        analog_test_store_result(failed_result);
        return busy("Failed to start analog diagnostic test task");
    }

    return ok("Analog diagnostic test started");
}

static UiCommandResultData handle_debug_analog_test_result(const UiCommandContext& ctx) {
    analog_test_send_result(analog_test_get_result());
    return ok("Analog diagnostic test result notification queued");
}

static UiCommandResultData handle_debug_gpio_set(const UiCommandContext& ctx) {
    uint32_t port;
    uint32_t value;
    if (!json_get_u32(ctx.json, "port", &port)) {
        return invalid_arg("Expected numeric port");
    }
    if (!json_get_u32(ctx.json, "value", &value)) {
        return invalid_arg("Expected numeric value");
    }

    gpio_num_t pin;
    switch (port) {
    case 1:
        pin = PIN_U3_HIGH;
        break;
    case 2:
        pin = PIN_U2_HIGH;
        break;
    case 3:
        pin = PIN_U1_HIGH;
        break;
    case 4:
        pin = PIN_U3_LOW;
        break;
    case 5:
        pin = PIN_U2_LOW;
        break;
    case 6:
        pin = PIN_U1_LOW;
        break;
    default:
        return invalid_arg("port must be 1..6");
    }

    gpio_set_level(pin, value ? 1 : 0);
    return ok("GPIO updated");
}

static UiCommandResultData handle_debug_all_high(const UiCommandContext& ctx) {
    gpio_set_level(PIN_U1_LOW, 1);
    gpio_set_level(PIN_U2_LOW, 1);
    gpio_set_level(PIN_U3_LOW, 1);
    gpio_set_level(PIN_U1_HIGH, 1);
    gpio_set_level(PIN_U2_HIGH, 1);
    gpio_set_level(PIN_U3_HIGH, 1);
    return ok("All signal pins high");
}

static UiCommandResultData handle_debug_all_low(const UiCommandContext& ctx) {
    gpio_set_level(PIN_U1_LOW, 0);
    gpio_set_level(PIN_U2_LOW, 0);
    gpio_set_level(PIN_U3_LOW, 0);
    gpio_set_level(PIN_U1_HIGH, 0);
    gpio_set_level(PIN_U2_HIGH, 0);
    gpio_set_level(PIN_U3_HIGH, 0);
    return ok("All signal pins low");
}

void ui_command_router_init(void) {
    s_command_count = 0;
    if (s_analog_test_result_mutex == NULL) {
        s_analog_test_result_mutex = xSemaphoreCreateMutex();
        AnalogDiagnosticResult initial_result = AnalogDiagnosticResult_init_zero;
        analog_test_set_message(&initial_result, "No analog diagnostic test has run yet");
        analog_test_store_result(initial_result);
    }
    set_dead_time_us(g_dead_time_us);

    register_command("system.list_commands", handle_system_list_commands);
    register_command("system.get_status", handle_system_get_status);
    register_command("system.hello", handle_system_hello);
    register_command("signal.start", handle_signal_start);
    register_command("signal.stop", handle_signal_stop);
    register_command("signal.set_alpha", handle_signal_set_alpha);
    register_command("signal.set_pattern", handle_signal_set_pattern);
    register_command("signal.set_cycle_interval", handle_signal_set_cycle_interval);
    register_command("signal.set_dead_time", handle_signal_set_dead_time);
    register_command("signal.set_dead_time_tail_overhead", handle_signal_set_dead_time_tail_overhead);
    register_command("analog.set_monitor_period", handle_analog_set_monitor_period);
    register_command("analog.set_acquisition_period", handle_analog_set_acquisition_period);
    register_command("analog.read_once", handle_analog_read_once);
    register_command("analog.ble_read_enable", handle_analog_ble_read_enable);
    register_command("analog.ble_read_disable", handle_analog_ble_read_disable);
    register_command("control.enable", handle_control_enable);
    register_command("control.disable", handle_control_disable);
    register_command("led.on", handle_led_on);
    register_command("led.off", handle_led_off);
    register_command("led.blink", handle_led_blink);
    register_command("debug.dataset_active", handle_debug_dataset_active);
    register_command("debug.dataset_a", handle_debug_dataset_a);
    register_command("debug.dataset_b", handle_debug_dataset_b);
    register_command("debug.matrix_a", handle_debug_matrix_a);
    register_command("debug.matrix_b", handle_debug_matrix_b);
    register_command("debug.log_duration", handle_debug_log_duration);
    register_command("debug.signal_timing", handle_debug_signal_timing);
    register_command("debug.analog_test_run", handle_debug_analog_test_run);
    register_command("debug.analog_test_result", handle_debug_analog_test_result);
    register_command("debug.gpio_set", handle_debug_gpio_set);
    register_command("debug.all_high", handle_debug_all_high);
    register_command("debug.all_low", handle_debug_all_low);
}

UiCommandResultData ble_ui_command_dispatch(const UiCommand& command) {
    cJSON* json = cJSON_Parse(command.json[0] ? command.json : "{}");
    if (!json) {
        return invalid_arg("Payload must be valid JSON");
    }

    UiCommandContext ctx = {
        .command = command,
        .json = json,
    };

    UiCommandResultData result = unknown_command(command.name);
    for (size_t i = 0; i < s_command_count; ++i) {
        if (strcmp(command.name, s_commands[i].name) == 0) {
            result = s_commands[i].handler(ctx);
            break;
        }
    }

    cJSON_Delete(json);
    return result;
}

static void copy_field(char* dest, size_t dest_size, const std::string& value) {
    if (dest_size == 0) {
        return;
    }

    strncpy(dest, value.c_str(), dest_size - 1);
    dest[dest_size - 1] = '\0';
}

static void copy_field(char* dest, size_t dest_size, const char* value) {
    copy_field(dest, dest_size, std::string(value ? value : ""));
}

void ble_ui_command_fill_result_packet(BlePacket* packet,
                                   const UiCommand& command,
                                   const UiCommandResultData& result) {
    *packet = BlePacket_init_zero;
    packet->which_payload = BlePacket_command_result_tag;

    UiCommandResult* payload = &packet->payload.command_result;
    payload->request_id = command.request_id;
    copy_field(payload->name, sizeof(payload->name), command.name);
    payload->ok = result.ok;
    copy_field(payload->code, sizeof(payload->code), result.code);
    copy_field(payload->message, sizeof(payload->message), result.message);
    copy_field(payload->json, sizeof(payload->json), result.json);
}
