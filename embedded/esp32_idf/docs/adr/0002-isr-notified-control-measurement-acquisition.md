# ISR-notified control measurement acquisition

Status: accepted

The ADC continuous driver remains responsible for sampling and DMA buffering. Its conversion-done callback only notifies the Core 0 acquisition task. The active reader drains frames, timestamps each frame with `esp_timer_get_time()` immediately after `adc_continuous_read()` returns, backdates samples by the configured conversion interval, assembles the newest complete control measurement, and publishes it for the control point.

In CPU-engine operation, the Core 0 acquisition task is the active reader and publisher. In continuous DMA-engine operation, Core 0 starts the ADC driver and hands the single-reader token to the Core 1 DMA control task, which drains and publishes at its control point. BLE and telemetry remain consumers of published measurements, not drivers of acquisition.

## Considered Options

- **Keep polling/yield acquisition** — rejected: hardware tests showed measurement age occasionally exceeded the signal cycle window even when BLE load was reduced.
- **Publish complete measurements inside the ADC callback** — rejected for now: it would minimize latency further, but puts parsing, channel pairing, and calibration closer to ISR context. That path is reserved if ISR-notified task acquisition still cannot meet the cycle window.
- **Increase the control age budget** — rejected as the primary fix: it would hide stale measurements instead of making current-cycle measurements reliable.

## Consequences

- The Core 0 acquisition task has priority over app/BLE command work, but blocks on ADC notifications while it owns the reader, so it should not busy-starve Core 0.
- The ADC callback must stay small: no logging, allocation, protobuf work, calibration, or timestamp bookkeeping.
- `flush_pool` intentionally favors fresh data. Frame timestamps are read-time-derived estimates, so Core 0 scheduling delay remains visible as measurement age instead of being hidden by a stale timestamp ring.
- In continuous DMA-engine operation, the Core 1 DMA control task owns frame draining and publication; Core 0 retains driver lifecycle and reader-token handoff.
- BLE/status traffic can still consume Core 0, but it does not determine when the DMA control task drains a measurement at its control point.
