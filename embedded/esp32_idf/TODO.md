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