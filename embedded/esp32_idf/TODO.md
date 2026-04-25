# Code Analysis Tasks

## Analysis Scope
- [x] Overview: ESP32 BLE LED Controller firmware
- [x] Architecture: Multi-task design with FreeRTOS
- [x] Dependencies: BLE, ADC, LED, Signal Controller modules
- [x] Security: Input validation, semaphore usage
- [x] Performance: Task priorities, memory allocation

## Tasks

### Structure Analysis
- [x] Analyze main.cpp entry point and task creation
- [x] Map include dependencies (ble_controller, helper_*, signal_controller)
- [x] Review app_init() initialization sequence

### Security Assessment
- [x] Check NVS flash initialization error handling
- [x] Review semaphore usage in analog_action_task
- [x] Validate ble_is_connected() usage patterns

### Performance Analysis
- [x] Evaluate task stack sizes (8192, 4096, 2048 bytes)
- [x] Review vTaskDelay intervals and CPU core pinning
- [x] Analyze memory allocation with std::make_unique in loops

### Pattern Recognition
- [x] Identify design patterns (observer, producer-consumer)
- [x] Review global state management (g_adc_*, g_system_state)
- [x] Check error handling patterns (ESP_ERROR_CHECK)

### Risks
- [x] Hardcoded debug ESP_LOGE calls
- [x] Potential memory leak in blink_create_task
- [x] Unprotected global variable access between tasks

## Fixes Applied

- [x] `ble_is_connected()` race condition fixed — `conn_id` changed to `std::atomic<uint16_t>`
- [x] `g_adc_*` globals fixed — changed to `std::atomic<float>` with release/acquire semantics

## Skills

- [x] SKILL_naming_variables.md created — Naming conventions from TigerBeetle TIGER_STYLE.md

## Current Review Tasks

- [x] Read and analyze project structure
- [x] Analyze architecture and patterns
- [x] Assess security risks
- [x] Evaluate performance and real-time constraints
- [x] Identify maintainability issues
- [x] Synthesize and deliver review report

## Web UI Implementation Tasks

- [x] Change HelpPanel background to red (annotation mo9siljh-jjdi08)
- [x] Resolve annotation in agentation

## Current Build Fix Tasks

- [x] Run `task build` and capture the failure
- [x] Identify the root cause of the build error
- [x] Apply the minimal code or configuration fix
- [x] Re-run `task build` and verify success

## Dataset Generator Tasks

- [x] Analyze current generated dataset flow between MATLAB and ESP-IDF
- [x] Replace oversized alpha-to-lambda map with a more compact generated representation
- [x] Update `helper_datasetter.cpp` to compute lookup index from alpha
- [x] Generate `helper_datasetter.cpp` and `helper_datasetter.h` from MATLAB
- [x] Keep generated dataset values aligned with current simulation output
- [x] Verify embedded compile compatibility of generated files

## Annotation Implementation Tasks

- [x] Update dashboard size selector to support height presets (`1x1`, `1x2`) where needed
- [x] Make annotated panel maximize to fullscreen
- [x] Limit oversized tall panels like `Quick Actions` with internal scrolling
- [x] Verify affected dashboard components still render correctly
- [x] Resolve accepted annotations after implementation

## Follow-up Annotation Fix Tasks

- [x] Fix `Signal Analysis` size selector so the panel can return to `1x1`
- [x] Reduce `System Logs` panel height to better match the dashboard grid
- [x] Reduce `Signal Generator` panel height to better match the dashboard grid
- [x] Reduce oversized `SizeSelector` dropdown height in `HelpPanel`
- [x] Resolve accepted follow-up annotations after implementation

## Overflow Matching Tasks

- [x] Lock dashboard row height to the configured size so `1x1` panels visually match
- [x] Add internal scrolling to `Signal Analysis` when content exceeds the configured panel height
- [x] Verify other dashboard panels keep matching heights with overflow constrained inside the card
- [x] Remove `Quick Actions` height cap so it fills the configured grid height
- [x] Resolve overflow-matching annotations after implementation

## 3x Height Support Tasks

- [x] Extend dashboard panel size types to support `x3` heights
- [x] Update the size selector UI to expose a `3x` height option
- [x] Add grid row-span mappings for `1x3`, `2x3`, and `3x3`
- [x] Verify oversized panels use internal scrolling correctly with `x3` heights
- [x] Resolve `3x` height support annotations after implementation

## Signal Analysis Annotation Fix Tasks

- [x] Make the `Signal Analysis` chart area grow correctly when the panel height is `x3`
- [x] Ensure `Signal Analysis` fullscreen stays above the other dashboard panels
- [x] Verify `Signal Analysis` sizing and fullscreen behavior after the fixes
- [x] Resolve `Signal Analysis` annotations after implementation

## Latest Annotation Fix Tasks

- [x] Center the `Signal Analysis` fullscreen panel correctly
- [x] Make the `Signal Analysis` chart fit `2x` height without triggering an unnecessary scrollbar
- [x] Reorganize `Signal Generator` layout so controls are not packed or misaligned
- [x] Add more vertical spacing between the top controls and the vector sections in `Signal Generator`
- [x] Add a side note showing the `sum()` of the elements for the annotated `Signal Generator` input field
- [x] Verify `Signal Analysis` and `Signal Generator` after the latest annotation fixes
- [x] Resolve the latest annotations after implementation

## Final Signal Analysis Height-Fit Task

- [x] Make the `Signal Analysis` chart area shrink to match the panel height without remaining too tall
- [x] Remove the forced extra inner height in `Signal Analysis` so the chart matches the panel without cropping
- [x] Fix the fullscreen alignment root cause in `Signal Analysis` by removing the transformed ancestor behavior that breaks fixed positioning
- [x] Fix `Signal Analysis` fullscreen positioning relative to the dashboard content area so it occupies the usable area and stays centered below the header
- [x] Fix the remaining fullscreen offset root cause from the layout transform wrapper so `Signal Analysis` fullscreen is truly viewport-centered
- [x] Reduce the gap between dashboard panels

## BLE Messaging Analysis

- [x] Analyze `ble_controller.h/cpp` (Firmware side)
- [x] Analyze `web/src/components/bluetooth.ts` (App side)
- [x] Map the messaging protocol (commands, status, notifications)
- [x] Evaluate security risks in messaging
- [x] Evaluate performance/latency in BLE communication
- [x] Identify design patterns used in BLE handling
- [x] Synthesize comprehensive analysis report
- [x] Propose improvements for BLE messaging protocol

## Protobuf Implementation

- [x] Create `proto/messaging.proto` schema
- [x] Integrate `nanopb` into ESP-IDF project
- [x] Integrate `protobufjs` into Web App project
- [x] Add generation tasks to `Taskfile.yml`
- [x] Implement Protobuf encoding in `ble_controller.cpp` for telemetry
- [x] Implement Protobuf decoding in `web/src/components/bluetooth.ts`
- [x] Add `0x01` binary prefix to discriminate between ASCII and Protobuf
- [x] Document architecture in `docs/BLE_PROTOBUF_ARCHITECTURE.md`