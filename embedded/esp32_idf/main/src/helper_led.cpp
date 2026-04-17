/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */
/* Includes */
#include "helper_led.h"

/* Private variables */
static uint8_t led_state;

/* Public functions */
uint8_t get_led_state(void)
{
    return led_state;
}

void led_on(void)
{
    gpio_set_level(static_cast<gpio_num_t>(BLINK_GPIO), true);
    led_state = 1;
}

void led_off(void)
{
    gpio_set_level(static_cast<gpio_num_t>(BLINK_GPIO), false);
    led_state = 0;
}

void led_init(void)
{

    gpio_reset_pin(static_cast<gpio_num_t>(BLINK_GPIO));
    /* Set the GPIO as a push/pull output */
    gpio_set_direction(static_cast<gpio_num_t>(BLINK_GPIO), GPIO_MODE_OUTPUT);
    led_off();
}