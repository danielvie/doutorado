% Set the ESP32 Bluetooth device name and channel (default is 1)
bt = bluetooth("ESP32_BT", 1);

write(bt, 'D4', 'string');