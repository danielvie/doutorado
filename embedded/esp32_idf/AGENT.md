The `signal_controller.cpp` disables interrupts on Core 1 during signal generation. This is required for jitter-free GPIO control of power converters, where timing variations would cause hardware faults.

WDT is disabled on Core 1 (`CONFIG_ESP_INT_WDT_CHECK_CPU1` and `CONFIG_ESP_TASK_WDT_CHECK_IDLE_TASK_CPU1` not set in sdkconfig). Core 1 runs only the signal loop; BLE and system tasks run on Core 0.

At the end of a task where a `web` was touched, run `task web:build` and check if there are errors.

Dont start an operation when the user just asks a question. To implement something wait for: "continue", "implement", "fix", "write" commands