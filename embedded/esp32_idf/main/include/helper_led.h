/*
 * SPDX-FileCopyrightText: 2024 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Unlicense OR CC0-1.0
 */
#ifndef HELPER_LED_H
#define HELPER_LED_H

/* Includes */
/* ESP APIs */
#include "driver/gpio.h"
#include "common.h"
#include "esp_log.h"

/* Defines */
#define BLINK_GPIO CONFIG_EXAMPLE_BLINK_GPIO

#ifdef __cplusplus
extern "C" {
#endif
    

/* Public function declarations */
uint8_t get_led_state(void);
void led_on(void);
void led_off(void);
void led_init(void);


#ifdef __cplusplus
}
#endif

#endif // HELPER_LED_H
