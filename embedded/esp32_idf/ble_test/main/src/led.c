/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */
/* Includes */
#include "led.h"
#include "common.h"
#include "esp_log.h"

/* Private variables */
static uint8_t led_state;

/* Public functions */
uint8_t get_led_state(void)
{
    return led_state;
}

void led_on(void)
{
    gpio_set_level(CONFIG_EXAMPLE_BLINK_GPIO, true);
}

void led_off(void)
{
    gpio_set_level(CONFIG_EXAMPLE_BLINK_GPIO, false);
}

void led_init(void)
{
    // ESP_LOGI(TAG, "example configured to blink gpio led!");
    gpio_reset_pin(CONFIG_EXAMPLE_BLINK_GPIO);
    /* Set the GPIO as a push/pull output */
    gpio_set_direction(CONFIG_EXAMPLE_BLINK_GPIO, GPIO_MODE_OUTPUT);
    gpio_set_level(CONFIG_EXAMPLE_BLINK_GPIO, 1);
}