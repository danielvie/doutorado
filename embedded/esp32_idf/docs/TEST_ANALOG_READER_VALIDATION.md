# Analog Reader — Expected Behavior and Validation

This document uses the domain language defined in [CONTEXT.md](../CONTEXT.md). It describes what the analog acquisition subsystem is supposed to do, how to exercise it on the bench, and what to check during control-measurement timing validation.

Scope: the acquisition pipeline in `main/src/helper_analog.cpp` and its consumption at the control point in `main/src/signal_controller.cpp`.

## 1. Expected Behavior

### 1.1 Acquisition

- The controller measures three analog channels using the control measurement channel mapping: `AN3 -> VR`, `AN5 -> V_C1`, `AN6 -> V_C2` (ADC1 channels 4, 6, 0 / GPIO 32, 34, 36).
- Default mode is **continuous DMA** at 250 kHz total conversion rate (~83 k triples/s), running in the acquisition task on Core 0 at priority `tskIDLE_PRIORITY + 6`. A **oneshot** fallback mode samples one triple per configured period (default 1000 µs).
- The DMA driver delivers frames of 16 triples (48 samples). Samples are routed into three per-channel queues and reassembled into complete AN3/AN5/AN6 triples without trusting hardware ordering.

### 1.2 Timestamps (measurement age)

- Every DMA frame is timestamped **in the conversion-done ISR**, and each sample is backdated from the frame-completion time by its position in the frame. The published timestamp is therefore the **conversion time**, not the time the Core-0 task got scheduled.
- An assembled triple carries the **oldest** of its three sample timestamps (conservative: measurement age is never underestimated).
- In oneshot mode the timestamp is taken before the first of the three conversions (same conservative rule).
- On any event that breaks frame/timestamp pairing (partial frame, read error, pool flush, driver restart) the timestamp ring resyncs and falls back to read time for that frame.

### 1.3 Publication

- Triples are published into a lock-free seqlock snapshot (single writer: the acquisition task). Only the **newest** triple of each processed frame is written; skipped triples still count toward `measured_triples_per_second`, so the telemetry rate reflects real assembly throughput.
- If any per-channel queue overflows (channel imbalance), **all three queues are flushed** and the event is counted in `channel_order_anomalies` / `partial_triples`. A published triple never pairs samples from distant conversion rounds.

### 1.4 Consumption at the control point

- At the control point (the maintenance interval between signal cycle playbacks), the signal loop on Core 1 calls `analog_read_control_snapshot` with an age budget derived from the **active dataset's signal cycle window** (nominal pattern cycles ÷ 240 MHz). Fallback is 280 µs if the window is not computable.
- The pipeline clamps the budget upward to `analog_min_snapshot_age_us()` — one DMA frame of accumulation plus 50% margin (~288 µs at 250 kHz) — because samples fresher than one frame are physically unavailable.
- The read path is lightweight: a bounded seqlock read (8 attempts) plus an age check. No latency statistics or sorting run at the control point.
- A control update is **skipped** (missed control update: previous correction kept, fault recorded) when:
  - the snapshot sequence equals the last-consumed sequence (no new sample), or
  - measurement age exceeds the effective budget (stale sample), or
  - a coherent snapshot cannot be read within the retry bound (writer contention), or
  - the calibration LUT is not ready, or no valid triple exists.
- After **3 consecutive misses**, the controller disables itself (`ControlState::OFF`) while signal generation continues undisturbed — a recoverable timing fault handled per the signal timing contract.

### 1.5 Fault codes (telemetry field `fault_code`)

| Code | Name | Meaning |
|---|---|---|
| 0 | NONE | Healthy |
| 1 | REPEATED_MISS | ≥3 consecutive missed control updates |
| 2 | STALE_SAMPLE | New-sample or age check failed at the control point |
| 3 | MISSING_TRIPLE | No valid triple in the snapshot |
| 4 | DMA_OVERFLOW | Continuous driver overflow / read failure |
| 5 | CALIBRATION_UNAVAILABLE | Calibration LUT not built yet |
| 6 | SNAPSHOT_CONTENTION | Bounded seqlock read gave up (Core-0 writer starved) |

The status message also reports the freshness bookkeeping directly: `min_snapshot_age_us` (pipeline floor), `control_max_age_us` (effective age budget enforced at the control point), and `frame_ts_fallbacks` (times a frame timestamp fell back to read time because the ISR timestamp ring was empty or desynchronized). The web console prints these on the `Age` and `TS fallbacks` lines of the analog status block.

## 2. How to Test

### 2.1 Bench setup

1. Feed known DC voltages (within 0–3.3 V after the front-end divider) into AN3, AN5, AN6. A resistor divider from a bench supply is enough; distinct values per channel (e.g. 0.5 / 1.5 / 2.5 V) catch channel-mapping swaps.
2. Connect the web dashboard (or BLE console) and open the analog status/telemetry view.
3. For timing correlation, put the oscilloscope on one output-group test point as in lab timing characterization.

### 2.2 Static accuracy and mapping test

1. With the signal stopped, enable analog monitoring and read calibrated values for AN3/AN5/AN6.
2. Swap the input voltages between channels and confirm the readings follow the physical channel (verifies `AN3->VR`, `AN5->V_C1`, `AN6->V_C2` and the ADC-channel mapping).
3. Sweep the supply 0.1 → 3.2 V on one channel and compare against a multimeter (verifies the calibration LUT; expect the piecewise-linear table's residual error, typically < 50 mV mid-range).

### 2.3 Acquisition health test (continuous mode)

Run the signal at alpha 0.5 with control **disabled**, let it sit for ≥60 s, then check the analog status:

- `measured_triples_per_second` vs. the configured rate.
- `overflow_count`, `frame_drops`, `pool_flushes`, `channel_order_anomalies`, `samples_rejected` — should stay flat after startup.
- `age_us` observed repeatedly — should stay within the expected envelope (see §3).
- Repeat while a BLE client is actively polling status, since BLE load on Core 0 is the main disturbance source.

### 2.4 Control-point freshness test

1. Enable control at alpha 0.5 (example dataset, signal cycle window 279.9 µs).
2. Observe `miss_count`, `consecutive_misses`, `fault_code` over several minutes.
3. Force a stale condition: switch acquisition to oneshot mode with a 5000 µs period while control runs. Expect STALE_SAMPLE misses, then REPEATED_MISS and controller auto-disable **without** any disturbance of the generated signal on the scope.
4. Return to continuous mode, re-enable control, confirm recovery (fault code back to 0).

### 2.5 Control-measurement timing validation (oscilloscope)

Per the validation method in [PROJECT_GOALS.md](PROJECT_GOALS.md): correlate the snapshot `timestamp_us` and control-point timing against the signal cycle window. A practical approach: feed a slow known ramp into one channel, log `(timestamp_us, value)` pairs from telemetry, and verify the value/timestamp pairs land on the ramp within one cycle window. Any systematic offset larger than the pipeline floor indicates timestamping regression.

## 3. What to Check — Pass Criteria

Numeric acceptance thresholds for signal timing remain deferred until lab timing characterization; the criteria below are structural expectations of the analog pipeline itself.

| Check | Expectation at 250 kHz continuous |
|---|---|
| `measured_triples_per_second` | ≈ sample rate ÷ 3 (~83 000); stable ±5% |
| `age_us` at the control point | ≤ `control_max_age_us` (~288 µs at 250 kHz); never grows unbounded |
| `frame_ts_fallbacks` | Flat after startup; growth means ISR timestamping is not pairing with reads and ages have silently degraded to read-time stamps |
| `target_triples_per_cycle` | ≥ 4 triples per signal cycle window achieved by measured rate |
| `fault_code` steady state | 0 while control runs on the example dataset |
| `miss_count` growth | Occasional misses acceptable; `consecutive_misses` must reset to 0, controller must not auto-disable in steady state |
| `channel_order_anomalies`, `partial_triples` | Flat after startup; growth means channel imbalance → triples are being flushed |
| `overflow_count`, `frame_drops`, `pool_flushes` | Flat after startup; growth under BLE load means the acquisition task is being starved |
| Fault code 6 (SNAPSHOT_CONTENTION) | Rare to absent; repeated occurrences mean the Core-0 publisher is starved — check task priorities |
| Signal on scope during any analog fault | Commanded signal cycle unchanged — analog faults must never disturb the signal timing contract |
| Controller auto-disable | Only after 3 consecutive misses, reported via `ControlState::OFF`, signal keeps running |

### Red flags during testing

- `age_us` frequently near the budget while triple rate is nominal → publishes delayed on Core 0 (scheduling), not sampling: check BLE activity and task priorities.
- Calibrated values follow the wrong input channel → mapping regression; stop and fix before any control run.
- Misses only when a dataset with a short cycle window is active → age budget vs. pipeline floor interaction; consider raising the sample rate or shrinking `ADC_CONTINUOUS_FRAME_TRIPLES` (16 → 8 halves frame accumulation to ~96 µs).
- Growing `samples_rejected` → DMA is delivering unexpected channels; check the pattern configuration.
