#include "ble_router.h"

#include "signal_controller.h"

void ble_router_start() {
    if (xSemaphoreTake(g_signal_mutex, portMAX_DELAY) == pdTRUE) {
        g_signal_task_state = SignalTaskState::SIGNAL_RUN;
        xSemaphoreGive(g_signal_mutex);
    }
    digitalWrite(2, HIGH);  // LED GPIO
    start_signal_timer();
}

void ble_router_high() {
    if (xSemaphoreTake(g_signal_mutex, portMAX_DELAY) == pdTRUE) {
        g_signal_task_state = SignalTaskState::HIGH_ALL;
        xSemaphoreGive(g_signal_mutex);
    }
    stop_signal_timer();
    digitalWrite(2, LOW);
    set_all_outputs_high();
}

void ble_router_idle() {
    if (xSemaphoreTake(g_signal_mutex, portMAX_DELAY) == pdTRUE) {
        g_signal_task_state = SignalTaskState::IDLE;
        xSemaphoreGive(g_signal_mutex);
    }
    stop_signal_timer();
    digitalWrite(2, LOW);
    set_all_outputs_low();
}

void ble_router_run_signal(std::string& signal) {
    ble_task_state = BLETaskState::SIGNAL_READING;
    signal_update_pattern(signal);
}

void ble_router_message_data(std::string& message) {
    ble_task_state = BLETaskState::SIGNAL_READING;
    signal_update_full_control(message); // NOTE: 0 -> read new message
}