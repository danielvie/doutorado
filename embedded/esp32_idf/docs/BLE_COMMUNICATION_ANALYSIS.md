# BLE Communication — Performance Analysis

## System Overview

The system is a **BLE 4.2 GATT Server** running on an ESP32, controlling a 3-phase signal pattern generator with closed-loop feedback. Communication flows through a single GATT characteristic (read/write/notify) using two serialization formats:

| Format | Direction | Use |
|---|---|---|
| **Text (ASCII)** | Client → ESP32 | Commands (`start`, `SIGNAL:...`, `status`) |
| **Protobuf (nanopb)** | ESP32 → Client | Telemetry, Status, Logs (binary prefix `0x01`) |
| **Text (ASCII)** | ESP32 → Client | Legacy `NoteData` messages (dataset dumps, matrix, etc.) |

## Data Flow Architecture

```
┌─────────────────────────── Core 0 ───────────────────────────┐
│                                                               │
│  BLE Stack ──► GATTS Callback ──► ble_router()               │
│       │                              │                        │
│       │                              ├─ SIGNAL: ──► Inactive DataSet ──┐
│       │                              ├─ SET_ALPHA: ──► Lookup + Copy ──┤
│       │                              └─ status/read ──► BLE Send      │
│       │                                                       │        │
│       ◄── ble_send_protobuf() ◄── analog_reading_task        │        │
│       ◄── ble_send_message()  ◄── analog_action_task         │        │
│                                       ▲                       │        │
└───────────────────────────────────────┼───────────────────────┘        │
                                        │ semaphore                      │
┌─────────────────────────── Core 1 ────┼───────────────────────┐        │
│                                       │                       │        │
│  signal_loop_task (priority 10)       │                       │        │
│    ├─ check g_ds_update_pending ◄─────────────────────────────────────┘
│    ├─ control correction (atomics) ───┘                       │
│    ├─ portDISABLE_INTERRUPTS()                                │
│    ├─ GPIO.out_w1ts / GPIO.out_w1tc (pattern execution)       │
│    ├─ portENABLE_INTERRUPTS()                                 │
│    └─ vTaskDelay(0) yield                                     │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Bottleneck Analysis

### ~~1. No BLE Connection Parameter Negotiation~~ ✅ RESOLVED

**Severity: ~~CRITICAL~~ — Fixed**

~~The code never calls `esp_ble_gap_update_conn_params()` after a client connects. The connection interval is entirely determined by the client (phone/laptop), which typically defaults to 30–50 ms for power savings.~~

~~**Impact:** At a 50 ms connection interval, the maximum is ~20 packets/second. With a 500-byte MTU, that caps at ~10 KB/s.~~

~~At a negotiated 7.5 ms interval: ~133 packets/second → ~65 KB/s. **A 6.5× improvement.**~~

**Fix applied:** Added `esp_ble_gap_update_conn_params()` in `ESP_GATTS_CONNECT_EVT` handler requesting 7.5 ms connection interval (`min_int = max_int = 0x06`).

**Location:** `ble_controller.cpp` — `ESP_GATTS_CONNECT_EVT` handler.

---

### 2. ~~`note_ble_send()` Sends Full Buffer, Not Content~~ ✅ RESOLVED

**Severity: ~~CRITICAL~~ — Fixed**

```c
// helper_note.cpp:121-123
void note_ble_send(NoteData &buffer, BLEMode mode) {
    ble_send_message(buffer.buffer, buffer.idx, mode);  // ← now sends actual content length
}
```

~~`buffer.size` is the **allocated capacity** (497), not the **used length** (`buffer.idx`). Every legacy text message sends 497 bytes even if the content is 30 bytes. This wastes ~94% of BLE airtime for short messages.~~

**Fix applied:** Changed `buffer.size` → `buffer.idx` in `note_ble_send()`.

---

### ~~3. No MTU Exchange Verification~~ ✅ RESOLVED

**Severity: ~~MEDIUM~~ — Fixed**

~~`esp_ble_gatt_set_local_mtu(500)` sets the local preference, but the `ESP_GATTS_MTU_EVT` event is never handled in `profile_event_handler`. If the client doesn't initiate MTU exchange, the effective MTU stays at the BLE default of 23 bytes (20 bytes payload).~~

~~**Impact:** At 20-byte payload, each 500-byte protobuf packet requires 25 link-layer fragments.~~

**Fix applied:** Added `ESP_GATTS_MTU_EVT` handler that stores the negotiated MTU in `g_negotiated_mtu`. Resets to 23 on disconnect.

---

### ~~4. Blocking Command Processing in BLE Callback~~ ✅ RESOLVED

**Severity: ~~MEDIUM~~ — Fixed**

~~`ble_router()` runs synchronously inside the GATTS write event handler. Some paths do heavy work:~~

| Command | Work in Callback |
|---|---|
| `SIGNAL:...` | `std::string` alloc, `std::vector` alloc, parse, precompute |
| `SET_ALPHA:` | `std::stof()`, lookup, dataset copy, precompute |
| `status_matrix_a/b` | `make_unique<NoteData>`, matrix formatting, BLE send |

~~**Impact:** Long processing delays ACKs and can stall subsequent packet reception.~~

**Fix applied:** Write handler now ACKs immediately, copies data into `BleCommand` struct, and posts to a FreeRTOS queue (depth 4). `ble_command_task` on Core 0 dequeues and calls `ble_router` asynchronously.

---

### 5. BLE 4.2 Only — No 2M PHY ⚠️ N/A

**Severity: ~~MEDIUM~~ — Hardware Limitation**

~~`sdkconfig.defaults` disables BLE 5.0:~~

The ESP32-D0WD-V3 (this project's chip) only has a BLE 4.2 radio. 2M PHY requires ESP32-S3/C3/C6. This item cannot be fixed in software.

---

### ~~6. No TX Flow Control~~ ✅ RESOLVED

**Severity: ~~MEDIUM~~ — Fixed**

~~When calling `esp_ble_gatts_send_indicate()`, if the BLE TX queue is full it returns `ESP_FAIL` and data is silently dropped. No retry, no backpressure, no congestion event handling (`ESP_GATTS_CONGEST_EVT`).~~

**Fix applied:** Added `g_ble_congested` flag toggled by `ESP_GATTS_CONGEST_EVT`. `ble_send_message()` now drops packets when congested instead of queuing them — eliminates transport delay for real-time telemetry.

---

### ~~7. Unthrottled Telemetry Rate~~ ✅ RESOLVED

**Severity: ~~LOW~~ — Fixed**

~~`analog_reading_task` sends protobuf telemetry every `g_analog_monitor_period_ms` (default 500 ms). The BLE command `an_monitor_ms:10` can set this to 10 ms — producing 100 packets/second with no queue depth check.~~

**Fix applied:** 
1. Added a **hard floor of 50ms** (20Hz) to `g_analog_monitor_period_ms` in `ble_router` to prevent CPU/link saturation.
2. Added `ble_congested` field to `SystemStatus` protobuf so the client is aware when packets are being dropped.
3. Task already checks `ble_is_connected()` and `ble_send_message()` handles congestion by dropping stale data.

---

## Impact Summary

| Rank | Bottleneck | Throughput Impact | Fix Effort |
|---|---|---|---|
| 1 | ~~No connection interval negotiation~~ ✅ | ~~6.5× loss~~ | Done |
| 2 | ~~`note_ble_send` sends full buffer~~ ✅ | ~~94% airtime waste~~ | Done |
| 3 | ~~No MTU exchange verification~~ ✅ | ~~20-byte fragmentation~~ | Done |
| 4 | ~~Blocking command processing~~ ✅ | ~~BLE stack stalls~~ | Done |
| 5 | BLE 4.2 only ⚠️ | Hardware limitation | N/A |
| 6 | ~~No TX flow control~~ ✅ | ~~Silent data loss~~ | Done |
| 7 | ~~No telemetry rate limiting~~ ✅ | ~~CPU/Queue saturation~~ | Done |

## Throughput Estimates

| Scenario | Conn Interval | MTU | PHY | Throughput |
|---|---|---|---|---|
| Current (worst) | 50 ms | 23 B | 1M | ~400 B/s |
| Current (best, MTU ok) | 50 ms | 500 B | 1M | ~10 KB/s |
| After conn param fix | 7.5 ms | 500 B | 1M | ~65 KB/s |
| After conn param + BLE 5.0 | 7.5 ms | 500 B | 2M | ~100 KB/s |

> **Note:** Real-world BLE throughput depends on interference, client OS behavior, and whether the client honors requested connection parameters.

## Signal Loop Interaction

The signal loop on Core 1 disables interrupts for the entire pattern cycle (`signal_controller.cpp:318-346`). A typical 6-segment pattern runs ~558 µs with interrupts masked. This is within the 10 ms safety threshold and doesn't directly block BLE (which runs on Core 0), but some ESP-IDF internal synchronization is cross-core. The `vTaskDelay(0)` yield between cycles is the only window for Core 1 system tasks.

The ADC control path adds latency: semaphore → `adc_oneshot_read` (~25 µs × 3 channels) → atomics → next signal cycle. The control correction is always one full signal cycle behind the measurement.
