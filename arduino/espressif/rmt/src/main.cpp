#include <Arduino.h>
#include <driver/rmt.h>

// RMT Configuration
#define RMT_TX_CHANNEL    RMT_CHANNEL_0
#define RMT_TX_GPIO       18
#define RMT_CLK_DIV       80  // 80MHz/80 = 1MHz (1us resolution)

void setup() {
    // Configure RMT transmitter
    rmt_config_t rmt_tx_config;
    rmt_tx_config.rmt_mode = RMT_MODE_TX;
    rmt_tx_config.channel = RMT_TX_CHANNEL;
    rmt_tx_config.gpio_num = (gpio_num_t)RMT_TX_GPIO;
    rmt_tx_config.mem_block_num = 1;
    rmt_tx_config.tx_config.loop_en = false;
    rmt_tx_config.tx_config.carrier_en = false;
    rmt_tx_config.tx_config.idle_output_en = true;
    rmt_tx_config.tx_config.idle_level = RMT_IDLE_LEVEL_LOW;
    rmt_tx_config.clk_div = RMT_CLK_DIV;

    // Initialize RMT
    rmt_config(&rmt_tx_config);
    rmt_driver_install(rmt_tx_config.channel, 0, 0);

    // Create RMT signal pattern
    rmt_item32_t rmt_data[3];
    rmt_data[0].level0 = 1;        // High level
    rmt_data[0].duration0 = 10;    // High for 50 microseconds
    rmt_data[0].level1 = 0;        // Low level
    rmt_data[0].duration1 = 10;    // Low for 10 microseconds

    rmt_data[1].level0 = 1;        // High level
    rmt_data[1].duration0 = 20;    // High for 50 microseconds
    rmt_data[1].level1 = 0;        // Low level
    rmt_data[1].duration1 = 10;    // Low for 10 microseconds

    rmt_data[2].level0 = 1;        // High level
    rmt_data[2].duration0 = 30;    // High for 50 microseconds
    rmt_data[2].level1 = 0;        // Low level
    rmt_data[2].duration1 = 10;    // Low for 10 microseconds

    // rmt_item32_t rmt_data;
    // rmt_data.level0 = 1;        // High level
    // rmt_data.duration0 = 10;    // High for 50 microseconds
    // rmt_data.level1 = 0;        // Low level
    // rmt_data.duration1 = 10;    // Low for 10 microseconds

    // Continuously send the signal
    while(1) {
        rmt_write_items(RMT_TX_CHANNEL, rmt_data, 3, true);
        // No delay needed as RMT hardware handles the timing
    }
}

void loop() {
    // Empty - signal generation handled in setup()
}