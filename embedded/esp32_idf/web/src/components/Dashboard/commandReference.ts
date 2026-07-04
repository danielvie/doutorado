export interface CommandReferenceEntry {
  commands: string;
  description: string;
}

export const COMMAND_REFERENCE: CommandReferenceEntry[] = [
  {
    commands: "system.list_commands",
    description: "Lists registered UI commands",
  },
  {
    commands: "system.get_status",
    description: "Requests a structured status notification",
  },
  {
    commands: "system.hello",
    description: "Sends a test BLE log response",
  },
  {
    commands: "signal.start",
    description: "Starts continuous signal execution",
  },
  {
    commands: "signal.stop",
    description: "Stops continuous signal execution",
  },
  {
    commands: 'signal.set_alpha {"alpha":0.5}',
    description: "Loads the precomputed dataset for an alpha value",
  },
  {
    commands: 'signal.set_pattern {"time":"100,200,100,200","mode":"7,0,7,0"}',
    description:
      "Uploads a custom signal pattern; time values are 0.1 us ticks",
  },
  {
    commands: 'signal.set_cycle_interval {"cycles":100}',
    description: "Sets the analog trigger cycle interval",
  },
  {
    commands: 'signal.engine {"engine":"cpu"}',
    description: "Selects cpu or dma signal engine while stopped",
  },
  {
    commands: 'signal.engine {"engine":"dma"}',
    description: "Selects cpu or dma signal engine while stopped",
  },
  {
    commands: 'signal.set_dead_time {"time_tenths_us":0}',
    description:
      "Sets symmetric dead time to 0 ticks: no both-off interval before the target terminal turns on",
  },
  {
    commands: 'signal.set_dead_time {"time_tenths_us":20}',
    description:
      "Sets both rising and falling dead time to 20 ticks = 2.0 us; current terminal turns off, both terminals stay off, then target turns on",
  },
  {
    commands: 'signal.set_dead_time_down {"time_tenths_us":20}',
    description:
      "Sets only falling-boundary dead time: command goes LOW, both terminals stay off for 2.0 us, then complement goes HIGH",
  },
  {
    commands: 'signal.set_dead_time_tail_overhead {"cycles":35}',
    description:
      "CPU-engine calibration only: subtracts GPIO/write tail cycles from commanded dead time; DMA uses commanded ticks directly",
  },

  {
    commands: 'signal.set_edge_overhead_up {"cycles":35}',
    description:
      "CPU-engine rising-boundary edge compensation in CPU cycles; distinct from dead time",
  },
  {
    commands: 'signal.set_edge_overhead_down {"cycles":35}',
    description:
      "CPU-engine falling-boundary edge compensation in CPU cycles; distinct from dead time",
  },
  {
    commands: 'analog.set_monitor_period {"period_ms":100}',
    description: "Sets periodic analog telemetry interval",
  },
  {
    commands: 'analog.set_acquisition_period {"period_us":1000}',
    description: "Sets background analog acquisition spacing",
  },
  {
    commands: 'analog.set_acquisition_mode {"mode":"continuous"}',
    description: "Uses ADC continuous DMA for background acquisition",
  },
  {
    commands: 'analog.set_acquisition_mode {"mode":"oneshot"}',
    description: "Returns background acquisition to safe oneshot mode",
  },
  {
    commands: 'debug.test.an.mode {"mode":"continuous"}',
    description: "Uses ADC continuous DMA for analog test acquisition",
  },
  {
    commands: 'debug.test.an.mode {"mode":"oneshot"}',
    description: "Returns analog test acquisition to safe oneshot mode",
  },
  {
    commands: 'analog.set_continuous_sample_rate {"sample_hz":250000}',
    description: "Sets ADC continuous channel sample rate",
  },
  {
    commands: "analog.read_once",
    description: "Requests one analog telemetry sample",
  },
  {
    commands: "analog.ble_read_enable",
    description: "Enables continuous BLE analog read state",
  },
  {
    commands: "analog.ble_read_disable",
    description: "Disables continuous BLE analog read state",
  },
  {
    commands: "control.enable",
    description: "Enables closed-loop control",
  },
  {
    commands: "control.disable",
    description: "Disables closed-loop control",
  },
  {
    commands: "led.on",
    description: "Turns the onboard LED on",
  },
  {
    commands: "led.off",
    description: "Turns the onboard LED off",
  },
  {
    commands: 'led.blink {"delay1_ms":100,"delay2_ms":100}',
    description: "Sets LED blink mode, optionally with blink delays",
  },
  {
    commands: "debug.dataset_active",
    description: "Sends the active signal dataset",
  },
  {
    commands: "debug.dataset_a",
    description: "Sends signal dataset A",
  },
  {
    commands: "debug.dataset_b",
    description: "Sends signal dataset B",
  },
  {
    commands: "debug.matrix_a",
    description: "Sends the precomputed matrix for dataset A",
  },
  {
    commands: "debug.matrix_b",
    description: "Sends the precomputed matrix for dataset B",
  },
  {
    commands: "debug.log_duration",
    description: "Sends cycle duration diagnostics",
  },
  {
    commands: "debug.signal_timing",
    description: "Sends signal timing diagnostics",
  },
  {
    commands: 'debug.analog_test_run {"duration_ms":4000}',
    description: "Legacy alias for running the analog diagnostic test",
  },
  {
    commands: "debug.analog_test_result",
    description: "Legacy alias for fetching the analog diagnostic test result",
  },
  {
    commands: "debug.analog_dma_json",
    description: "Legacy alias for fetching ADC DMA per-channel debug counters",
  },
  {
    commands: 'debug.test.an.run {"duration_ms":4000}',
    description: "Runs a bounded signal plus analog diagnostic test",
  },
  {
    commands: "debug.test.an.result",
    description: "Fetches the latest stored analog diagnostic test result",
  },
  {
    commands: "debug.test.an.dma_json",
    description: "Fetches ADC DMA per-channel debug counters",
  },
  {
    commands:
      'debug.test.an.config_run {"duration_ms":4000,"sample_hz":[129000,250000,500000]}',
    description: "Runs the analog acquisition configuration sweep",
  },
  {
    commands: "debug.test.an.config_result",
    description: "Fetches the latest analog configuration sweep result",
  },
  {
    commands: "debug.test.an.get_status",
    description: "Alias for system.get_status within the analog test namespace",
  },
  {
    commands: 'debug.test.an.set_continuous_sample_rate {"sample_hz":250000}',
    description:
      "Alias for analog.set_continuous_sample_rate within the analog test namespace",
  },
  {
    commands: 'debug.gpio_set {"port":1,"value":1}',
    description: "Sets one debug GPIO port",
  },
  {
    commands: "debug.all_high",
    description: "Sets all signal GPIO pins high",
  },
  {
    commands: "debug.all_low",
    description: "Sets all signal GPIO pins low",
  },
];
