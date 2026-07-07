# Handoff - Analog latency UART loop, seqlock fix, stale-sample next step

**Date:** 2026-07-06  
**Repo root:** `C:\Users\daniel\Documents\DOUTORADO\embedded\esp32_idf`  
**Branch:** `main`  
**Remote:** `origin https://github.com/danielvie/doutorado`

## Goal

Make the DMA-engine control point consume a fresh analog control measurement inside the active signal-cycle budget.

Current acceptance target from the UART agent loop:

- `control == "compute"`
- `signal == "running"`
- `engine == "dma"`
- `snapshot_age_us <= budget_us`
- `age_used_over_budget_count == 0` or near zero after root-cause work
- `miss_contention == 0` or near zero
- `miss_stale == 0` or explained by expected cadence
- `ts_fallbacks == 0` ideally
- `pass == true`

## Current status

The UART hardware loop works when flashing with plain:

```sh
task flash
```

Avoid relying on `task agent:control-latency` for flashing if COM3 gets flaky; it had repeated transfer failures in the same session. `task flash` succeeded repeatedly.

Latest pushed commits:

```text
2d46f60 Reduce analog snapshot contention misses
e49f2c7 Track control snapshot age overruns
```

Latest measured result after `2d46f60`:

```json
{
  "age_used_count": 3938,
  "age_used_max_us": 972,
  "age_used_over_budget_count": 22,
  "budget_us": 282,
  "floor_us": 72,
  "miss_contention": 7,
  "miss_missing": 0,
  "miss_stale": 77,
  "misses": 84,
  "snapshot_age_us": 71,
  "ts_fallbacks": 4,
  "pass": false
}
```

## What changed

### `e49f2c7`

- Added `age_used_over_budget_count` to `AnalogRuntimeStatus`.
- Printed it in `agent control-latency`.
- Fixed miss-counter semantics:
  - Before: every valid ADC publish cleared `s_consecutive_misses`.
  - Now: only an accepted control snapshot clears it.
- Reason: live control auto-disable depends on consecutive control-read misses, not generic ADC publishing.

### `2d46f60`

- Added task-scoped miss breakdown counters:
  - `miss_stale`
  - `miss_contention`
  - `miss_missing`
- Raised `ANALOG_CONTROL_SEQLOCK_RETRIES` from `8` to `32`.
- Result: contention misses dropped from about `212` to `4-7`; total misses dropped from about `288` to about `84`.

## How to test

Use this sequence:

```sh
task flash
task uart:control-latency
```

`task uart:control-latency` does:

1. open COM3,
2. wait 2 s,
3. send `agent prepare-control-latency`,
4. wait 1 s,
5. send `agent control-latency`,
6. print one JSON result.

Useful repeat sampling:

```sh
task uart:control-latency
task uart:control-latency
task uart:control-latency
```

Do not run UART samples in parallel. COM3 is exclusive; one parallel run failed with `Access is denied`.

## Interpretation

Before the seqlock retry fix:

- `miss_contention` dominated.
- Example: `miss_contention: 212`, `miss_stale: 76`, `misses: 288`.

After the fix:

- `miss_contention` is mostly gone.
- Remaining failures are mostly `miss_stale`.
- That means the control trigger sometimes arrives before a newer analog snapshot is published.

## Next investigation

Focus on stale samples in the DMA control path.

Relevant path:

- `main/src/signal_engine_dma.cpp`
  - `dma_control_task`
  - `NOTIF_TRIGGER`
  - calls `signal_control_update_corrections(ctl)`
- `main/src/signal_controller.cpp`
  - `signal_control_update_corrections`
  - passes `ctx.last_analog_seq` into `analog_read_control_snapshot`
- `main/src/helper_analog.cpp`
  - `analog_read_control_snapshot`
  - stale check: `seq == last_seq`

Hypothesis:

The DMA control trigger cadence can outrun the analog snapshot publication cadence for some cycles, even though aggregate ADC throughput is high. The next useful metric is not more ADC rate tuning; it is timing correlation between control trigger intervals and snapshot publish intervals.

Minimal next counters:

- count control trigger calls during the measurement window,
- count accepted control snapshots,
- count stale misses by previous/current `seq` delta if cheap,
- optionally expose latest `seq` and `last_seq` in `agent control-latency`.

Avoid for now:

- ISR-side sample parsing,
- changing ADC sample rate,
- changing DMA frame size,
- web/protobuf UI changes.

## Known separate issue

Raw ADC readings still often show zeros:

```json
"raw": { "an3": 0, "an5": 0, "an6": 0 }
```

This is separate from the latency loop. Debug channel mapping, attenuation, wiring, or energized sense lines after the timing loop is understood.

## Git state at handoff

Pushed:

```text
2d46f60 Reduce analog snapshot contention misses
e49f2c7 Track control snapshot age overruns
```

Known uncommitted local dirt:

```text
 M main/src/helper_common.cpp
?? .claude/settings.local.json
```

`main/src/helper_common.cpp` was no-content line-ending dirt from earlier sample-rate experiments. Do not include it in future commits unless there is an actual content diff.

