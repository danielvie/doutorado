# ADC Latency Monitoring (Oneshot)

- [x] Add `adc_min`, `adc_max`, `adc_avg` fields to `SystemStatus` protobuf
- [x] Implement lock-free circular buffer (128 samples) in `helper_analog.cpp`
- [x] Implement cycle-accurate measurement in the analog reading block
- [x] Update `ble_router_status` to calculate and send statistics
- [x] Update Web Dashboard to display the new latency metrics

# Upcoming Tasks
- [x] Implement BLE OTA (Flashing via Bluetooth)
    - [x] Create `partitions.csv` with OTA support
    - [x] Update `sdkconfig` to use custom partitions
    - [x] Define OTA Protobuf messages in `messaging.proto`
    - [x] Implement `ota_controller` (ESP32) for handling chunks
    - [x] Implement `OtaManager` (Web) for file upload and chunking
- [ ] Refactor `ImageModal.tsx` to accept images as props (Deep Module)
- [ ] Move Mock Data logic from `Header.tsx` to `services/MockBleService.ts`
- [ ] Add bounds check for `us` delay in `signal_controller.cpp`

# Signal Loop Organization
- [x] Split `signal_loop_task` into focused static helpers
- [x] Keep interrupt-disabled GPIO playback in one timing-critical helper
- [x] Verify the refactor builds or report any build blocker

# Signal Pattern Comments
- [x] Clarify comments inside `execute_signal_pattern`
- [x] Verify comment-only change

# Help Panel Command Filter
- [x] Add command search field to `HelpPanel`
- [x] Render filtered command list
- [x] Run web build and report `Agentation` unused import blocker

# Shared Dead Time Command
- [x] Add BLE UI command for equal up/down dead time
- [x] Document command in Help panel
- [x] Verify C++ build

# BLE OTA Reconnect Robustness
- [x] Inspect BLE connection, OTA flash, and UI state lifecycle
- [x] Add reconnect-safe Web Bluetooth handling after ESP32 OTA reboot
- [x] Reuse previously granted browser Bluetooth device when available
- [x] Verify the web build
