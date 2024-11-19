#include <Arduino.h>
#include <driver/rmt.h>

// RMT Configuration
#define RMT_TX_CHANNEL_DI4    RMT_CHANNEL_0
#define RMT_TX_CHANNEL_DI5    RMT_CHANNEL_1
#define RMT_TX_CHANNEL_DI6    RMT_CHANNEL_2
#define RMT_TX_GPIO_DI4       21
#define RMT_TX_GPIO_DI5       22
#define RMT_TX_GPIO_DI6       23
#define RMT_CLK_DIV           80  // 80MHz/80 = 1MHz (1us resolution)

void setup() {

    pinMode(2, OUTPUT);

    // Configure RMT transmitter
    rmt_config_t rmt_tx_config_di4;
    rmt_tx_config_di4.rmt_mode = RMT_MODE_TX;
    rmt_tx_config_di4.channel = RMT_TX_CHANNEL_DI4;
    rmt_tx_config_di4.gpio_num = (gpio_num_t)RMT_TX_GPIO_DI4;
    rmt_tx_config_di4.mem_block_num = 1;
    rmt_tx_config_di4.tx_config.loop_en = false;
    rmt_tx_config_di4.tx_config.carrier_en = false;
    rmt_tx_config_di4.tx_config.idle_output_en = true;
    rmt_tx_config_di4.tx_config.idle_level = RMT_IDLE_LEVEL_LOW;
    rmt_tx_config_di4.clk_div = RMT_CLK_DIV;

    rmt_config_t rmt_tx_config_di5;
    rmt_tx_config_di5.rmt_mode = RMT_MODE_TX;
    rmt_tx_config_di5.channel = RMT_TX_CHANNEL_DI5;
    rmt_tx_config_di5.gpio_num = (gpio_num_t)RMT_TX_GPIO_DI5;
    rmt_tx_config_di5.mem_block_num = 1;
    rmt_tx_config_di5.tx_config.loop_en = false;
    rmt_tx_config_di5.tx_config.carrier_en = false;
    rmt_tx_config_di5.tx_config.idle_output_en = true;
    rmt_tx_config_di5.tx_config.idle_level = RMT_IDLE_LEVEL_LOW;
    rmt_tx_config_di5.clk_div = RMT_CLK_DIV;

    rmt_config_t rmt_tx_config_di6;
    rmt_tx_config_di6.rmt_mode = RMT_MODE_TX;
    rmt_tx_config_di6.channel = RMT_TX_CHANNEL_DI6;
    rmt_tx_config_di6.gpio_num = (gpio_num_t)RMT_TX_GPIO_DI6;
    rmt_tx_config_di6.mem_block_num = 1;
    rmt_tx_config_di6.tx_config.loop_en = false;
    rmt_tx_config_di6.tx_config.carrier_en = false;
    rmt_tx_config_di6.tx_config.idle_output_en = true;
    rmt_tx_config_di6.tx_config.idle_level = RMT_IDLE_LEVEL_LOW;
    rmt_tx_config_di6.clk_div = RMT_CLK_DIV;


    // Initialize RMT
    rmt_config(&rmt_tx_config_di4);
    rmt_config(&rmt_tx_config_di5);
    rmt_config(&rmt_tx_config_di6);
    rmt_driver_install(rmt_tx_config_di4.channel, 0, 0);
    rmt_driver_install(rmt_tx_config_di5.channel, 0, 0);
    rmt_driver_install(rmt_tx_config_di6.channel, 0, 0);

    // 5     7     3     4     2     6 -> modes
    // ----------------------------------------
    // 1     1     0     1     0     1 ->  DI6
    // 0     1     1     0     1     1 ->  DI5
    // 1     1     1     0     0     0 ->  DI4

    // ~negate to match implementation
    // 0     0     1     0     1     0 -> ~DI6
    // 1     0     0     1     0     0 -> ~DI5
    // 0     0     0     1     1     1 -> ~DI4

    // Create RMT signal pattern
    rmt_item32_t rmt_data_di4[3];
    rmt_data_di4[0].level0 = 0;        // High level
    rmt_data_di4[0].level1 = 0;        // Low level
    rmt_data_di4[1].level0 = 0;        // High level
    rmt_data_di4[1].level1 = 1;        // Low level
    rmt_data_di4[2].level0 = 1;        // High level
    rmt_data_di4[2].level1 = 1;        // Low level
    
    rmt_data_di4[0].duration0 = 46;     // High for x microseconds
    rmt_data_di4[0].duration1 = 46;     // Low for x microseconds
    rmt_data_di4[1].duration0 = 46;     // High for x microseconds
    rmt_data_di4[1].duration1 = 46;     // Low for x microseconds
    rmt_data_di4[2].duration0 = 46;     // High for x microseconds
    rmt_data_di4[2].duration1 = 46;     // Low for x microseconds

    rmt_item32_t rmt_data_di5[3];
    rmt_data_di5[0].level0 = 1;        // High level
    rmt_data_di5[0].level1 = 0;        // Low level
    rmt_data_di5[1].level0 = 0;        // High level
    rmt_data_di5[1].level1 = 1;        // Low level
    rmt_data_di5[2].level0 = 0;        // High level
    rmt_data_di5[2].level1 = 0;        // Low level

    rmt_data_di5[0].duration0 = 46;     // High for x microseconds
    rmt_data_di5[0].duration1 = 46;     // Low for x microseconds
    rmt_data_di5[1].duration0 = 46;     // High for x microseconds
    rmt_data_di5[1].duration1 = 46;     // Low for x microseconds
    rmt_data_di5[2].duration0 = 46;     // High for x microseconds
    rmt_data_di5[2].duration1 = 46;     // Low for x microseconds


    rmt_item32_t rmt_data_di6[3];
    rmt_data_di6[0].level0 = 0;        // High level
    rmt_data_di6[0].level1 = 0;        // Low level
    rmt_data_di6[1].level0 = 1;        // High level
    rmt_data_di6[1].level1 = 0;        // Low level
    rmt_data_di6[2].level0 = 1;        // High level
    rmt_data_di6[2].level1 = 0;        // Low level
    
    rmt_data_di6[0].duration0 = 46;     // High for x microseconds
    rmt_data_di6[0].duration1 = 46;     // Low for x microseconds
    rmt_data_di6[1].duration0 = 46;     // High for x microseconds
    rmt_data_di6[1].duration1 = 46;     // Low for x microseconds
    rmt_data_di6[2].duration0 = 46;     // High for x microseconds
    rmt_data_di6[2].duration1 = 46;     // Low for x microseconds

    // rmt_item32_t rmt_data_di4;
    // rmt_data_di4.level0 = 1;        // High level
    // rmt_data_di4.duration0 = 10;    // High for 50 microseconds
    // rmt_data_di4.level1 = 0;        // Low level
    // rmt_data_di4.duration1 = 10;    // Low for 10 microseconds

    // Continuously send the signal
    delay(3000);
    digitalWrite(2, HIGH);
    while(1) {
        rmt_write_items(RMT_TX_CHANNEL_DI4, rmt_data_di4, 3, true);
        rmt_write_items(RMT_TX_CHANNEL_DI5, rmt_data_di5, 3, true);
        rmt_write_items(RMT_TX_CHANNEL_DI6, rmt_data_di6, 3, true);
        // No delay needed as RMT hardware handles the timing
    }
}

void loop() {
    // Empty - signal generation handled in setup()
}