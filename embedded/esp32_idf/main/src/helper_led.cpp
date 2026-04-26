/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */
/* Includes */
#include "helper_led.h"
#include "helper_common.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

/* Private types */
enum LedCommandType {
    LED_CMD_ON,
    LED_CMD_OFF,
    LED_CMD_BLINK,
    LED_CMD_SYNC
};

struct LedCommand {
    LedCommandType type;
    uint8_t count;
};

/* Private variables */
static QueueHandle_t led_queue = NULL;

/* Private functions */
static void led_physical_set(bool on) {
    gpio_set_level(static_cast<gpio_num_t>(BLINK_GPIO), on);
}

static void led_manager_task(void* arg) {
    LedCommand cmd;
    for (;;) {
        // Read current blink delays
        uint16_t d1 = g_blink_delay1_ms.load(std::memory_order_acquire);
        uint16_t d2 = g_blink_delay2_ms.load(std::memory_order_acquire);
        
        // Use d2 as the default timeout for the sweeper when blinking
        LedMode mode = g_system_state.led_mode.load(std::memory_order_acquire);
        uint32_t timeout_ms = (mode == LedMode::BLINKING) ? d2 : 1000;

        // Wait for a command
        if (xQueueReceive(led_queue, &cmd, pdMS_TO_TICKS(timeout_ms)) == pdPASS) {
            switch (cmd.type) {
                case LED_CMD_ON:
                    led_physical_set(true);
                    continue; 
                case LED_CMD_OFF:
                    led_physical_set(false);
                    continue; 
                case LED_CMD_BLINK:
                    for (uint8_t i = 0; i < cmd.count; i++) {
                        led_physical_set(true);
                        vTaskDelay(pdMS_TO_TICKS(d1));
                        led_physical_set(false);
                        vTaskDelay(pdMS_TO_TICKS(d1));
                    }
                    break;
                case LED_CMD_SYNC:
                    break;
            }
        } else {
            // Safety Sweeper / State Renderer
            if (mode == LedMode::BLINKING) {
                // Continuous blink phase: Start the next ON cycle
                led_physical_set(true);
                vTaskDelay(pdMS_TO_TICKS(d1));
                led_physical_set(false);
                // The next loop iteration's xQueueReceive timeout will handle the d2 (OFF) phase
            } else {
                // NORMAL mode: Follow the signal state
                extern bool led_get_desired_state(); 
                led_physical_set(led_get_desired_state());
            }
        }
    }
}

/* Public functions */
void led_on(void) {
    LedCommand cmd = { .type = LED_CMD_ON, .count = 0 };
    if (led_queue) xQueueSend(led_queue, &cmd, 0);
}

void led_off(void) {
    LedCommand cmd = { .type = LED_CMD_OFF, .count = 0 };
    if (led_queue) xQueueSend(led_queue, &cmd, 0);
}

void blink(uint8_t N) {
    LedCommand cmd = { .type = LED_CMD_BLINK, .count = N };
    if (led_queue) xQueueSend(led_queue, &cmd, 0);
}

void led_init(void) {
    gpio_reset_pin(static_cast<gpio_num_t>(BLINK_GPIO));
    gpio_set_direction(static_cast<gpio_num_t>(BLINK_GPIO), GPIO_MODE_OUTPUT);
    led_physical_set(false);
    
    if (led_queue == NULL) {
        led_queue = xQueueCreate(10, sizeof(LedCommand));
    }
}

void led_create_manager_task(void) {
    if (led_queue == NULL) led_init();
    xTaskCreatePinnedToCore(led_manager_task, "led_mgr", 2048, NULL, 5, NULL, 0);
}