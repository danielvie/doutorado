# BLE Protobuf Architecture

This document describes the hybrid messaging architecture used for communication between the ESP32 firmware and the Web App.

## 1. Overview

To balance **performance** (for high-frequency telemetry) and **readability** (for debugging and logs), the system uses a hybrid protocol:
- **Binary (Protobuf)**: Used for telemetry data (`anX` samples) and structured state.
- **ASCII (Text)**: Used for human-readable logs, status reports, and legacy commands.

## 2. Wire Format

All BLE messages sent from the ESP32 include a discrimination prefix if they are binary.

| First Byte | Interpretation | Format |
| :--- | :--- | :--- |
| `0x01` | **Protobuf** | The remaining bytes are a serialized `BlePacket`. |
| *Other* (ASCII) | **Text** | The entire buffer is a UTF-8 string (e.g., `STATUS`, `LOG`). |

## 3. Schema (`proto/messaging.proto`)

The contract is defined in a single `.proto` file, ensuring consistency between C++ and TypeScript.

```proto
syntax = "proto3";

message Telemetry {
    float an3 = 1;
    float an5 = 2;
    float an6 = 3;
    uint32 timestamp_ms = 4;
}

message SystemStatus {
    enum SignalState {
        STOPPED = 0;
        RUNNING = 1;
    }
    SignalState state = 1;
    float alpha = 2;
    uint32 cycle_count = 3;
}

message BlePacket {
    oneof payload {
        Telemetry telemetry = 1;
        SystemStatus status = 2;
    }
}
```

## 4. Generation Pipeline

Tasks in the root `Taskfile.yml` handle code generation:

- **Firmware (Nanopb)**: Generates `messaging.pb.h` and `messaging.pb.c` using `nanopb_generator`.
- **Web (Protobuf.js)**: Generates `messaging.js` and `messaging.d.ts` using `pbjs`.

Command: `task proto:gen`

## 5. Implementation Details

### ESP32 (C++)
- Uses `pb_encode` from Nanopb.
- `ble_send_protobuf()` prepends `0x01` and sends the serialized buffer.
- High-frequency tasks (like `analog_reading_task`) use this to stream data efficiently.

### Web (TypeScript)
- The notification handler in `bluetooth.ts` checks the first byte of the `DataView`.
- If `0x01`, it slices the buffer and calls `decodeBlePacket()`.
- Data is then passed to the UI via the same callbacks (`g_fn_probe`), ensuring zero breakage for existing components.
