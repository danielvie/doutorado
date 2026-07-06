# Handoff — Control loop: compute-only mode + snapshot-age latency

**Date:** 2026-07-06
**Repo root:** `C:\Users\daniel\Documents\DOUTORADO` (project under `embedded/esp32_idf`)
**Branch:** `main`
**Board:** ESP32 on `COM3`, flashed with the current working tree (see below).

## One-line status

Control now stays ON in a new **compute-only ("dry-run") mode**, but the real blocker for *live* control is diagnosed: the ADC control snapshot is delivered **~1607 µs old** while the control age budget is only **~288 µs** (one signal cycle), so every sample is stale. Next session: find where that ~1.6 ms acquisition latency comes from (and why raw AN3/5/6 read 0).

## What is committed vs. uncommitted

Committed already (do not redo):
- `5a1f296` — Split status pane into **Device Status** + **Diagnostics** panels (+ `StateChip`, `mockDevice` emulator, layout wiring).
- `40a9be0` — Guard `control.enable` against missing gain matrix; `analog_clear_consecutive_misses()` on enable; `signal_update_from_string` (SYNC) invalidates `gain_k`; `signal_control_reset` drops control to OFF when active dataset has no gain.

**Uncommitted working tree = the compute-only/dry-run feature.** Inspect with `git diff` (and `git diff -- '*.proto' '*.pb.h'`). Files touched:
- Firmware: `main/src/helper_common.cpp` + `main/include/helper_common.h` (`g_control_dry_run`), `main/src/ble_ui_command_router.cpp` (`control.dry_run` cmd, `control.enable` clears dry-run, `control.disable` clears both), `main/src/signal_controller.cpp` (dry-run: no auto-disable, no apply in CPU engine), `main/src/signal_engine_dma.cpp` (dry-run: compute but no render; live→compute nominal re-render), `main/src/helper_analog.cpp` (**staleness gate bypassed in dry-run**), `main/src/ble_controller.cpp` (populate `control_dry_run`).
- Proto: `proto/messaging.proto` adds `bool control_dry_run = 25;` to `SystemStatus`; regenerated `main/src/proto/messaging.pb.h`, `web/src/proto/messaging.{js,d.ts}`.
- Web: `web/src/proto/messaging-helpers.ts` (map `controlDryRun`→`control_dry_run`), `web/src/services/BleManager.ts` (decode + status text), `web/src/store/deviceStore.ts` (`controlDryRun`), `web/src/components/Dashboard/DeviceStatusPanel.tsx` (Control chip LIVE/COMPUTE), `web/src/components/Dashboard/QuickActions.tsx` (Off/Compute/Live segmented control).

Firmware is built and flashed from this working tree. Web builds clean (`task web:build`). **Nothing is committed yet for the dry-run feature** — decide whether to commit before continuing.

## The diagnosis (from live hardware, alpha=0.5, engine=DMA, control in COMPUTE)

Device Status panel readback:
- `SNAPSHOT AGE: 1607 us / budget 288 us (floor 288)` ← age ≈ 5.6× budget.
- `AGE GATE MAX: no snapshots used yet` (before the dry-run bypass flash).
- `ADC LATENCY: avg 99 · p95 135 · min/max 3/565 us`, `RATE: 50648 triples/s`, `FAULT: none`, `ANALOG VALID`.
- `MISSES: 12361` climbing, `CONSECUTIVE MISSES: 0` (acquisition keeps publishing valid triples, which resets the consecutive counter between control reads).
- `READINGS: AN3/AN5/AN6 raw 0 → 0.1000` ← **raw values are 0** (calibrated to a 0.1 floor). Suspicious — verify sense inputs are wired/energised, independent of the timing bug.

Conclusion: the controller math is fine; it never runs because the freshest snapshot (~1607 µs) is far older than one signal cycle (~288 µs), so the staleness gate at `helper_analog.cpp` rejects 100% of samples. The earlier "+3 misses, control won't stay ON" was this same rejection tripping the (now-relaxed-in-dry-run) auto-disable.

## Why the dry-run change was made

`control.dry_run {"enabled":true}` puts control ON but computes-only (no waveform change, no auto-disable). The final edit also **bypasses the age/staleness gate in dry-run** (`helper_analog.cpp`, `analog_read_control_snapshot`): it still skips exact-repeat seqs, but accepts new-but-stale samples so `age_used_count` climbs and `age_used_max_us` reports the true (over-budget) age. Expect the Device Status "Age gate max" to show ~1600 µs in **red** (over budget) with a rising count — that red is intentional and is the diagnosis surfaced. Live mode is unchanged (still hard-rejects stale data).

## Next session focus — the ~1.6 ms acquisition latency

Goal: understand why the published control snapshot lags "now" by ~1607 µs when one DMA frame (`ADC_CONTINUOUS_FRAME_TRIPLES=16`, floor≈288 µs incl. 50% margin) is the theoretical minimum. Candidates to trace in `main/src/helper_analog.cpp`:
- The acquisition task's wake cadence / how often `analog_publish(...)` runs vs. the DMA store buffer (`ADC_CONTINUOUS_STORE_SIZE = FRAME_SIZE*4`, `ADC_CONTINUOUS_FRAMES_PER_IDLE_DELAY=32`) — is it draining frames in bursts?
- `sample_timestamp_us` origin: the ISR frame-timestamp ring (`ANALOG_FRAME_TS_RING_SIZE=8`) vs. `frame_ts_fallbacks` (check that counter on hardware — a high value means timestamps fall back to read-time, distorting age).
- Whether the control snapshot is (incorrectly) tied to the BLE monitor trigger `signal_trigger_periodic_analog_read()` (fires every `g_cycle_nrun` cycles; status showed `CYCLES .../10000`).
- Separately: root-cause **raw AN=0** (ADC channel mapping/attenuation/wiring, or calibration LUT producing a 0.1 floor).

Key code refs (paths relative to `embedded/esp32_idf`):
- `main/src/helper_analog.cpp` — `analog_read_control_snapshot` (~L404), `analog_min_snapshot_age_us` (~L385), publish/timestamp (~L245-290), frame constants (~L19-29).
- `main/src/signal_controller.cpp` — `signal_control_update_corrections` (~L518), `signal_control_reset` age budget (~L462).

## Validate-on-hardware steps (only the user can pair BLE)

The automated preview browser cannot pair Web Bluetooth. Ask the user to: open the web UI in Chrome → Connect → pick an alpha preset (loads valid gain) → Start → Quick Actions **Compute** → read Device Status: "Age gate max" should now climb (~1600 µs, red) with rising count = compute path confirmed. Then chase the latency.

## Build / flash / preview commands

- Firmware: `task build` then `task flash` (COM3). Proto regen: `task proto:gen`.
- Web: `task web:build` (per `AGENT.md`, run after touching `web`). Dev preview server name: `web-dev` (port 5173) via `.claude/launch.json`.
- Note: screenshots of the preview time out while **Mock** mode is on (continuous 100 ms repaint) — verify via `preview_snapshot`/`preview_eval` DOM inspection instead, or toggle Mock off first.

## Suggested skills

- **grill-me** (or **anthropic-skills:grill-with-docs**) — before writing acquisition-path fixes, stress-test the hypothesis about where the 1.6 ms latency originates; there are several candidates and the wrong fix is costly to flash/test.
- **code-review** — run over the uncommitted dry-run diff (and any acquisition-latency fix) before committing; it touches the Core-1 real-time control path.

## Project guardrails (from AGENT.md)

- Core 1 runs the signal loop with interrupts disabled during signal generation; no logging/alloc/semaphores in the interrupt-disabled block. WDT is disabled on Core 1.
- Run `task web:build` after any `web` change.
- Do not start editing when the user is asking a question.
