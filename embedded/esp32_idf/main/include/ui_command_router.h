#pragma once

#include <string>

#include "esp_err.h"
#include "proto/messaging.pb.h"

struct UiCommandResultData {
    bool ok;
    std::string code;
    std::string message;
    std::string json;
};

void ui_command_router_init(void);
UiCommandResultData ui_command_dispatch(const UiCommand& command);
void ui_command_fill_result_packet(BlePacket* packet,
                                   const UiCommand& command,
                                   const UiCommandResultData& result);
