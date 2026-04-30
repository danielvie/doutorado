#include "ui_command_router.h"

#include <algorithm>
#include <cstring>
#include <string>

#include "ble_controller.h"
#include "esp_log.h"
#include "helper_common.h"
#include "signal_controller.h"

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
    std::string json = "{\"commands\":[";
    for (size_t i = 0; i < s_command_count; ++i) {
        if (i > 0) {
            json += ",";
        }
        json += "\"";
        json += s_commands[i].name;
        json += "\"";
    }
    json += "]}";

    return ok("Command list generated", json);
}

static UiCommandResultData handle_system_get_status(const UiCommandContext& ctx) {
    ble_router_status();
    return ok("Status notification queued");
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

static UiCommandResultData handle_signal_set_dead_time(const UiCommandContext& ctx) {
    uint32_t up_cycles;
    uint32_t down_cycles;
    if (!json_get_u32(ctx.json, "up_cycles", &up_cycles)) {
        return invalid_arg("Expected numeric up_cycles");
    }
    if (!json_get_u32(ctx.json, "down_cycles", &down_cycles)) {
        return invalid_arg("Expected numeric down_cycles");
    }

    g_dead_time_cycles_up = up_cycles;
    g_dead_time_cycles_down = down_cycles;
    signal_precompute_steps(&g_dataset_a);
    signal_precompute_steps(&g_dataset_b);
    ESP_LOGI(TAG, "Set dead time up=%lu down=%lu cycles", up_cycles, down_cycles);
    return ok("Dead time updated");
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

static UiCommandResultData handle_analog_read_once(const UiCommandContext& ctx) {
    ble_router_read();
    return ok("Analog read notification queued");
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

void ui_command_router_init(void) {
    s_command_count = 0;

    register_command("system.list_commands", handle_system_list_commands);
    register_command("system.get_status", handle_system_get_status);
    register_command("signal.start", handle_signal_start);
    register_command("signal.stop", handle_signal_stop);
    register_command("signal.set_alpha", handle_signal_set_alpha);
    register_command("signal.set_pattern", handle_signal_set_pattern);
    register_command("signal.set_cycle_interval", handle_signal_set_cycle_interval);
    register_command("signal.set_dead_time", handle_signal_set_dead_time);
    register_command("analog.set_monitor_period", handle_analog_set_monitor_period);
    register_command("analog.read_once", handle_analog_read_once);
    register_command("control.enable", handle_control_enable);
    register_command("control.disable", handle_control_disable);
}

UiCommandResultData ui_command_dispatch(const UiCommand& command) {
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

void ui_command_fill_result_packet(BlePacket* packet,
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
