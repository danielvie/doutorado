# BLE Protobuf Status Implementation

- [ ] Update `proto/messaging.proto` with expanded `SystemStatus` and `LogMessage` <!-- id: 0 -->
- [ ] Create `proto/messaging.options` for string limits <!-- id: 1 -->
- [ ] Regenerate Protobuf files (Firmware & Web) <!-- id: 2 -->
- [ ] Update ESP32 `ble_router_status()` to send binary status <!-- id: 3 -->
- [ ] Update ESP32 `ble_router_print_dataset()` to use `LogMessage` or binary? (Maybe keep ASCII for datasets for now as they are large) <!-- id: 4 -->
- [ ] Update Web App `BleManager.ts` to handle new payloads <!-- id: 5 -->
- [ ] Update Web App UI to format and display binary status <!-- id: 6 -->