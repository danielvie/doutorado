# ISR-notified control measurement acquisition

Status: accepted

The ADC continuous driver remains responsible for sampling and DMA buffering, but the control-measurement acquisition task is now woken directly by the ADC conversion-done callback. The callback only records the frame timestamp, maintains the timestamp ring, and notifies the acquisition task. The task then reads the ADC frame, assembles the latest control measurement, and publishes it for the Core 1 control point.

This replaces polling/yield-based acquisition for continuous mode. BLE and telemetry remain consumers of published measurements, not drivers of measurement acquisition.

## Considered Options

- **Keep polling/yield acquisition** — rejected: hardware tests showed measurement age occasionally exceeded the signal cycle window even when BLE load was reduced.
- **Publish complete measurements inside the ADC callback** — rejected for now: it would minimize latency further, but puts parsing, channel pairing, and calibration closer to ISR context. That path is reserved if ISR-notified task acquisition still cannot meet the cycle window.
- **Increase the control age budget** — rejected as the primary fix: it would hide stale measurements instead of making current-cycle measurements reliable.

## Consequences

- The acquisition task has priority over app/BLE command work, but blocks on ADC notifications, so it should not busy-starve Core 0.
- The ADC callback must stay small: no logging, allocation, protobuf work, or calibration.
- Timestamp overflow drops the oldest timestamp so fresh DMA frames are not paired with stale frame times.
- BLE/status traffic can still consume CPU, but it no longer determines when the acquisition task wakes to publish a control measurement.
