# Handoff — Signal Controller DMA Architecture (grill session)

## What this session is
An active **grill-with-docs** design interview (skills: `grill-me` + `domain_modeling`) about
adding an **I2S-parallel + DMA** signal-generation engine to the ESP32 signal controller, running
**in parallel** with the existing CPU busy-wait engine. Goal restated by the user: *"robust signal
generated dynamically based on the signal provided, then adjusted for the next cycle based on control
actions."*

**Mode: design only. NO CODE has been written or should be written yet.** Per project `AGENT.md`
("never start changing code when the prompt is a question") and the grill format, all edits are held
until the full decision tree is walked and the user explicitly says go.

> **STATUS (2026-07-02): GRILL COMPLETE — 10/10 questions asked, D1–D10 locked.**
> Glossary updated in `CONTEXT.md` (Signal Engine, Rendered Bitstream, Sample Clock, Correction
> Commit Deadline). ADR written: `docs/adr/0001-dual-signal-engine-i2s-dma.md`.
> Next step: implementation, awaiting the user's explicit go.

## Project context
- Repo: `/Users/danielvieira/Documents/doutorado.git/embedded/esp32_idf`
- Target: **classic ESP32** (confirmed `CONFIG_IDF_TARGET="esp32"` in sdkconfig) — has I2S
  parallel/LCD mode with DMA (the recommended offload path). MCPWM/RMT were evaluated and rejected
  (see reasoning in transcript; MCPWM can't express arbitrary 100-segment mode sequences, RMT lacks
  DMA + cross-channel sync on classic ESP32).
- Domain glossary: `CONTEXT.md` (read it — terms like Duration Tick, Dead Time, Control Point,
  Next-Cycle Control Action, Missed Control Update, Signal Timing Contract are load-bearing).
- Key source files already reviewed:
  - `main/src/signal_controller.cpp` — current CPU engine (busy-wait `wait_until_cycle`,
    `portDISABLE_INTERRUPTS()`, `execute_signal_pattern`, `signal_precompute_steps`, double-buffer
    `g_dataset_a/b` swap, `SignalTimingSample` telemetry).
  - `main/include/signal_controller.h` — `SignalStep`, `DataSet`, constants
    (`SIGNAL_TIME_TICKS_PER_US = 10` → 0.1 µs tick; `SIGNAL_CYCLES_PER_TIME_TICK = 24`; 240 MHz CPU).
  - `main/src/helper_datasetter.cpp` — 81 alpha operating points (0.10–0.90), per-alpha
    `time_duration_values`, `mode_pattern_index`, `target_values`, `gain_k_values`. Datasets are
    small (dataset_size segments; typical cycle window ~279 µs).
  - `main/include/helper_common.h` — `DEFAULT_DEAD_TIME_US 2`,
    `DEFAULT_SIGNAL_EDGE_OVERHEAD_UP_CYCLES 0`, `DEFAULT_SIGNAL_EDGE_OVERHEAD_DOWN_CYCLES 35`.

## Decisions locked (D1–D4) + one pending (D5/Q5)

**D1 — Two engines coexist, runtime-selectable.** CPU busy-wait engine kept as characterized
reference; new I2S-DMA engine added beside it, chosen before `signal_start_continuous()`. Shared
`DataSet` + double-buffer machinery. Accepted tradeoffs: temporary dual-precompute maintenance
burden + IRAM pressure from the dormant CPU hot path (`IRAM_ATTR` loop). Intended to be temporary —
retire CPU engine after DMA passes lab characterization at all operating points.

**D2 — Sample clock starts at 10 MHz (100 ns/sample), in a single named constant.** Exact for all
commanded Duration Ticks (0.1 µs) and the 2 µs dead time (= 20 samples). Edge-compensation
granularity 100 ns to start. Bump constant to 20/40 MHz (2×/4× buffer memory) only if scope shows
gate-driver asymmetry needs sub-100 ns trimming. Working hypothesis: the CPU-path overhead that
`edge_overhead_down=35` (~146 ns) compensates *largely vanishes* under DMA. Buffer size ≈ 5.6
KB/buffer at 10 MHz for a 280 µs window (~11 KB double-buffered — trivial DRAM).

**D3 — Control Point = EOF-triggered normal task, not ISR work.** I2S EOF interrupt at each cycle
boundary only signals a normal-priority, watchdog-covered control task. That task reads the
Current-Cycle Measurement, computes Signal-Duration Corrections via the `gain_k` path, re-renders the
*inactive* bitstream buffer, atomically relinks the DMA descriptor. Miss the next EOF → DMA replays
current buffer = Missed Control Update, zero timing disturbance. Render + matrix math NEVER in the ISR.
(Re-enables watchdog on the control path — closes the CPU engine's safety gap.)

**D4 — Strict one-cycle correction contract (N→N+1), hard EOF-to-relink deadline.** Measurement from
cycle N must produce a relinked buffer before DMA latches cycle N+1's descriptor, else Missed Control
Update. Preserves the existing glossary meaning of Next-Cycle Control Action and keeps DMA engine
control-equivalent to CPU engine, so `gain_k` matrices (assume one-cycle actuation delay) stay valid.
Relink deadline is a measured quantity, expected to fit easily in ~279 µs (matrix mult is small 5×3,
already logged as `matrix_multiply_us`; render is ~5.6 KB fill) — **to be verified, not assumed.**

**D5 — Share front-end, fork back-end.** `signal_precompute_steps()` stays the single source of
`SignalStep[]` (masks, dead_time, is_rising, per-segment durations); new
`signal_render_bitstream(DataSet*, buffer)` expands `SignalStep[]` into per-sample 6-bit parallel
words (dead-time samples with both terminals of changing groups inactive = shoot-through guard,
then active-hold samples). Renderer uses a derived `duration_samples` (10 MHz) recomputed from
`duration_ticks` (source of truth), not `duration_cycles` (240 MHz). Dead-time/shoot-through/edge
classification stays single-sourced → mitigates the D1 dual-precompute hazard.

**D6 — Graceful commanded stop, immediate fault stop.** Commanded `signal_stop()` finishes the
current cycle (halt at next EOF), then re-routes all six pins from the I2S matrix back to GPIO with
output latch preset 0 (all terminals inactive, matching CPU engine's safe state) *before* DMA
teardown. DMA underrun/descriptor error = Unrecoverable Timing Fault → same detach path but
immediate, mid-cycle.

**D7 — `PIN_OUT_SIG` stays plain GPIO.** Bitstream carries only the 6 output-group terminal bits
(bit 6 of the byte-wide sample word unused). Scope triggering during characterization uses the
power signals. (Code confirmed OUT_SIG is dormant today: init-LOW, never toggled.)

**D8 — Engine selection: `signal.engine` command, `"cpu"|"dma"`, stopped-only, volatile.** Rejected
while running; not persisted to NVS (reboot → CPU default). Web UI gets an engine selector. Default
CPU until DMA passes Lab Timing Characterization.

**D9 — Telemetry: one schema, common core + engine-specific section.** Shared fields (`engine`,
cycle period requested/observed, missed-control-update count, `matrix_multiply_us`) plus nested
`cpu:{overruns, wait slack…}` or `dma:{eof_to_relink_us, render_us…}`. Web UI keys off `engine`.

**D10 — DMA renderer starts at zero edge compensation.** The CPU engine's `edge_overhead_down=35`
compensates software overhead absent under DMA — not ported. Per-boundary trim fields (whole 100 ns
samples) reserved, default 0, populated only from oscilloscope measurement; sub-100 ns needs
trigger the D2 sample-clock bump instead. CPU engine keeps its cycle-based calibration untouched.

## Docs written this session
- `CONTEXT.md` — added: Signal Engine, Rendered Bitstream, Sample Clock, Correction Commit Deadline.
- `docs/adr/0001-dual-signal-engine-i2s-dma.md` — the D1 architecture decision (accepted).

## How to resume (implementation phase, once user says go)
Grill is complete; identifiers D1–D10/Q1–Q10 are retired — new items use I1, I2, …
Suggested implementation order:
1. **I1** — `signal_render_bitstream()` + `duration_samples` derivation on top of `SignalStep[]` (D5, D10).
2. **I2** — I2S-parallel/DMA engine: init, descriptor ping-pong (two self-looping chains, relink =
   one atomic tail-pointer write), EOF → control task notification (D2, D3, D4).
3. **I3** — Safe-state/stop paths incl. pin re-route to GPIO-low (D6); GPIO23 IO_MUX quirk applies.
4. **I4** — `signal.engine` command in `ble_ui_command_router.cpp` (D8).
5. **I5** — Telemetry restructure + web UI (D9) — then run `task web:build` per AGENT.md.
6. Lab Timing Characterization at all operating points before retiring the CPU engine (D1).

## Suggested skills for the next session
- `grill-with-docs` (which chains `grill-me` + `domain_modeling`) — to continue this exact interview
  format and keep `CONTEXT.md`/ADRs updated inline as decisions crystallise.
- `domain_modeling` alone if only glossary/ADR upkeep is needed.
- Later, once design is approved and coding begins: `run` / `verify` and the project's `task
  web:build` step (per AGENT.md) for any web-touching telemetry changes.
