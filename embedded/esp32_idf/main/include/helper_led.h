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
#include "esp_log.h"

/* Defines */
#define BLINK_GPIO 2

#ifdef __cplusplus
extern "C" {
#endif
    

/* Public function declarations */
void led_on(void);
void led_off(void);
void led_init(void);
void led_create_manager_task(void);
void blink(uint8_t N);


#ifdef __cplusplus
}
#endif

#endif // HELPER_LED_H
