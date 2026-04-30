# Code Design Analysis Report

Date: 2026-04-30

Scope: ESP-IDF firmware in `main/`, shared protobuf contract in `proto/`, and the React/Web Bluetooth client in `web/src/`.

Analysis lens: module depth, responsibility boundaries, change amplification, scaling limits, observability, and safety constraints for an embedded real-time control system.

## Executive Summary

This project has a strong architectural center: a real-time ESP32 signal generator, a BLE transport layer, a shared protobuf schema, and a browser-based control/telemetry UI. The most encouraging design direction is the move from ad hoc runtime work toward precomputed execution data: `signal_precompute_steps()` translates high-level signal modes into hardware-ready masks before the high-speed loop runs. That is exactly the kind of deep module this codebase needs.

The main complexity debt is not raw code volume. It is shared mutable system state crossing task, core, protocol, and UI boundaries. The firmware currently has several global control variables, a mixed text/protobuf command surface, and safety limits that are either implicit, documented elsewhere, or partially enforced. Those issues are manageable, but they should be tightened before the control loop and OTA path become more central to experiments.

## System Shape

The system divides into four major responsibilities:

1. Real-time signal generation on Core 1: `main/src/signal_controller.cpp`
2. BLE GATT transport, command routing, telemetry, and OTA dispatch on Core 0: `main/src/ble_controller.cpp`
3. Analog acquisition and closed-loop control state handoff: `main/main.cpp`, `main/src/helper_analog.cpp`, `main/include/control_action.h`
4. Browser client connection, decoding, logging, and OTA upload: `web/src/services/`

The intended data flow is sound:

```mermaid
flowchart LR
    UI["Web UI"] -->|"Text commands / OTA protobuf"| BLE["BLE controller"]
    BLE -->|"Inactive dataset update"| DS["Dataset A/B"]
    DS -->|"Atomic swap request"| SIG["Signal loop on Core 1"]
    ADC["Analog tasks"] -->|"Atomic sampled values"| SIG
    SIG -->|"Semaphore trigger"| ADC
    BLE -->|"Protobuf notifications"| UI
```

## Complexity Debt Score

Overall Rating: C+

Scaling/Performance Risks: 4

- `an_monitor_ms` can still be set directly from BLE without a lower bound in `main/src/ble_controller.cpp`.
- The signal loop disables interrupts for each full pattern cycle in `main/src/signal_controller.cpp`.
- Dataset parsing allocates vectors and parses strings in the command path.
- OTA upload accepts chunks and file size without enforcing sequence, total written size, or digest verification.

Architectural Leaks: 5

- BLE router knows about LED, GPIO pins, signal datasets, control enablement, analog read state, OTA, and status formatting.
- Global state in `helper_common` is the real integration API between modules.
- Text commands and binary protobuf coexist without a single command contract.
- Web client formats firmware status strings instead of rendering structured UI state from a typed domain model.
- Documentation claims some behavior that the current code does not enforce.

Observability Gaps: 4

- BLE send failures are returned but many callers do not act on them.
- OTA does not report chunk sequence mismatches, digest mismatch, or oversized transfer attempts.
- Signal loop warnings log total pattern duration but do not reject unsafe patterns.
- Control corrections and saturation are not emitted as structured telemetry.

Safety Violations: 6

- `cycles:0` can make `g_cycle_count = (...) % g_cycle_nrun` divide by zero.
- `an_monitor_ms:0` can create a busy analog telemetry loop.
- `std::stof()` and `std::stoi()` can throw from BLE command input.
- `parse_signal()` does not validate equal time/mode lengths.
- `matrix_multiply_vector3()` assumes at least three columns and enough output space.
- OTA accepts declared file size and chunks without hard partition-size validation in the application layer.

## What Is Working Well

### Deep signal execution module

`signal_precompute_steps()` in `main/src/signal_controller.cpp` is a good design decision. It hides the messy details of complementary GPIO masks, dead-time selection, and transition detection behind a simple dataset-level operation. The signal loop then consumes `SignalStep` records with minimal branching. This is a deep module: the interface is small, and the implementation removes real complexity from the timing-critical path.

### BLE callback offload

The GATTS write handler copies commands into a FreeRTOS queue and processes them in `ble_command_task`. That keeps the BLE callback from becoming a heavy command interpreter. This is a strong boundary improvement, especially because commands such as `SIGNAL:` and `SET_ALPHA:` can parse, allocate, and update datasets.

### Shared protobuf for telemetry

The project already has a shared schema in `proto/messaging.proto`, firmware encoding via nanopb, and TypeScript decoding in `web/src/services/BleManager.ts`. That gives the project a path away from fragile status strings.

### Explicit performance measurements

ADC latency tracking and control timing fields in `LogDuration` are a useful start. The project is already measuring some of the right things.

## Main Design Risks

### 1. Command routing is too wide

`ble_router()` in `main/src/ble_controller.cpp` is currently the system command bus. It parses command text, mutates global timing parameters, starts/stops signal generation, touches GPIO ports, enables control, triggers status serialization, and dispatches OTA protobuf commands.

This causes change amplification. Adding or validating one new system behavior often means touching BLE parsing, global state, status formatting, web logs, and sometimes signal control.

Recommended direction:

- Introduce a small typed command layer, even if the incoming transport remains text for now.
- Split handlers by domain: signal commands, control commands, analog commands, hardware debug commands, OTA commands.
- Keep BLE responsible for transport, framing, and connection state; keep domain modules responsible for validating and applying commands.

### 2. Shared global state is the hidden architecture

The project uses atomics in several places, which is good, but the ownership model is unclear. Variables such as `g_system_state`, `g_cycle_nrun`, `g_dead_time_cycles_up`, `g_dead_time_cycles_down`, `g_adc_fresh`, and the active dataset flags form an implicit API between tasks.

The sharpest example is in `signal_loop_task()`: it reads control state, ADC freshness, dataset flags, cycle counts, and analog read state while also owning timing-critical GPIO output.

Recommended direction:

- Create explicit owner modules for signal runtime state, analog snapshot state, and BLE-visible status.
- Replace direct external writes to timing globals with setter functions that validate units and ranges.
- Keep global variables private to the module that owns them wherever possible.

### 3. Safety limits are inconsistent

Some limits are present: `MAX_SIGNAL_SIZE`, note buffer sizes, OTA packet-size logging on the web side, and a warning if pattern duration exceeds 10 ms.

Other limits are missing or non-enforcing:

- `cycles:%u` accepts zero, which can break modulo arithmetic in `signal_loop_task()`.
- `an_monitor_ms:%u` accepts zero or extremely low values.
- `us_delay` values are accepted without an upper bound.
- OTA `file_size` is accepted without comparing it to the update partition size before `esp_ota_begin()`.
- `SIGNAL:` accepts parsed input without checking that the time and mode vectors have the same length.

Recommended direction:

- Define one validation table for BLE commands: min, max, unit, and error message.
- Convert warnings that protect real-time safety into rejections when the input is unsafe.
- Use unit-bearing names at the interface: `dead_time_cycles`, `monitor_period_ms`, `duration_us`.

### 4. Text/protobuf protocol split is transitional

Outbound telemetry/status has moved toward protobuf, but inbound commands are mostly text except OTA. This creates two protocol worlds:

- `0x01` prefix: firmware-to-client protobuf packet.
- `0x02` prefix: client-to-firmware OTA protobuf command.
- ASCII strings: most client-to-firmware commands and some firmware-to-client legacy messages.

That is workable during development, but it makes compatibility and testing harder as the system grows.

Recommended direction:

- Add a `Command` protobuf with oneof fields for signal, control, analog config, LED/debug, and OTA.
- Keep text commands as a temporary debug console path.
- Add protocol version and capability fields to `SystemStatus`.

### 5. OTA lacks integrity and ordering enforcement

`OtaChunk` includes `seq`, and `OtaEnd` includes `sha256`, but the firmware does not currently enforce either. `web/src/services/OtaManager.ts` sends an empty SHA-256 string. This means the OTA module relies heavily on BLE write ordering and ESP-IDF image validation, but does not validate the application-level transfer.

Recommended direction:

- Track expected sequence number and reject duplicates/skips.
- Reject writes that would exceed `binary_file_size`.
- Reject `file_size == 0`.
- Compare `file_size` against `update_partition->size`.
- Implement SHA-256 validation or remove the field until it is real.

### 6. Documentation has drifted from code

`docs/BLE_COMMUNICATION_ANALYSIS.md` says telemetry has a hard floor of 50 ms for `g_analog_monitor_period_ms`, but `ble_router()` still assigns `an_monitor_ms` directly. That mismatch matters because a future change may trust the documentation and accidentally create a busy loop or BLE saturation during testing.

Recommended direction:

- Treat architecture docs as executable expectations: each resolved item should have a code reference or test.
- Add a short "Last verified against commit/date" section to docs that describe current behavior.

## High-Value Refactoring Plan

### Phase 1: Safety guards with low blast radius

Add validation to existing command handlers:

- Reject `cycles < 1`.
- Clamp or reject `an_monitor_ms < 50`.
- Bound `us_delay_*` to a documented maximum.
- Catch parse exceptions from `std::stof()` and `std::stoi()`.
- Validate `SIGNAL:` has equal nonzero time/mode lengths.

This phase is small, but it removes several real failure modes.

### Phase 2: Make domain ownership explicit

Create narrow APIs:

- `signal_config_set_cycle_interval(uint32_t cycles)`
- `signal_config_set_dead_time(uint32_t up_cycles, uint32_t down_cycles)`
- `analog_config_set_monitor_period_ms(uint32_t period_ms)`
- `control_set_enabled(bool enabled)`

The first win is not abstraction for its own sake. The win is that validation, logging, and unit semantics live beside the state they protect.

### Phase 3: Split BLE routing by responsibility

Keep `ble_router()` as a dispatcher only. Move handlers into focused modules:

- `ble_signal_commands`
- `ble_analog_commands`
- `ble_control_commands`
- `ble_debug_commands`
- `ota_controller`

That will make it easier to add protobuf commands later without dragging all firmware behavior through one large function.

### Phase 4: Consolidate protocol

Introduce a protobuf `BleCommand` top-level message. Keep the ASCII commands behind a `debug_text_command` field or a separate debug characteristic if needed.

This reduces mismatch between firmware and web, makes testing easier, and gives OTA, signal updates, and configuration changes the same validation story.

## Priority Findings

### P1: Division by zero risk in cycle configuration

`cycles:%u` writes directly to `g_cycle_nrun`. Later, `signal_loop_task()` computes modulo `g_cycle_nrun`. A BLE command of `cycles:0` can therefore crash or fault the signal task. This should be rejected at the command boundary.

References:

- `main/src/ble_controller.cpp`: `cycles:%u` handling around line 271
- `main/src/signal_controller.cpp`: modulo use around line 356

### P1: OTA integrity fields are not enforced

The schema carries `seq` and `sha256`, but firmware does not validate sequence order or digest, and the web client sends an empty SHA-256. OTA should not expose fields that look like safety checks unless they are actually enforced.

References:

- `proto/messaging.proto`: `OtaChunk.seq`, `OtaEnd.sha256`
- `main/src/ota_controller.cpp`: chunk/end handling
- `web/src/services/OtaManager.ts`: empty SHA-256 in end command

### P2: Telemetry period has no enforced lower bound

`an_monitor_ms:%u` writes directly to `g_analog_monitor_period_ms`, and `analog_reading_task()` uses it directly in `vTaskDelay()`. A value of zero or very low values can saturate CPU/BLE and invalidate timing experiments.

References:

- `main/src/ble_controller.cpp`: `an_monitor_ms:%u` handling around line 287
- `main/main.cpp`: `vTaskDelay(pdMS_TO_TICKS(g_analog_monitor_period_ms))`

### P2: Signal parser can accept malformed shape

`parse_signal()` returns success if it finds a semicolon and parses both sections. It does not check for equal vector lengths, nonzero segment count, duration bounds, or mode bounds. `signal_update_from_string()` then uses `times.size()` and indexes `modes[i]`, which can read past the mode vector when malformed input has more durations than modes.

References:

- `main/src/helper_common.cpp`: `parse_signal()`
- `main/src/signal_controller.cpp`: copy loop in `signal_update_from_string()`

### P2: BLE router is becoming a shallow mega-module

The BLE module does transport, parsing, routing, domain mutation, status serialization, and debug formatting. It is not yet unmanageable, but it is the most likely place for future change amplification.

Reference:

- `main/src/ble_controller.cpp`: `ble_router()` and related command handlers

## Suggested Success Criteria

For the next design pass, we should be able to say:

- Every BLE-settable numeric value has a min, max, and unit at the command boundary.
- Signal updates either apply completely to the inactive dataset or fail without changing it.
- OTA rejects out-of-order, oversized, or digest-mismatched transfers.
- BLE transport can be understood without knowing signal-control internals.
- Status telemetry is structured and does not require the web client to reconstruct firmware domain meaning from text.

## Bottom Line

The architecture is promising because the real-time signal path is already being shaped into a deep module. The next step is to make the rest of the system match that discipline: explicit ownership of shared state, typed command boundaries, and hard validation at every external input. Those changes will reduce experiment risk and make the project easier to extend without making the timing-critical code more complicated.
