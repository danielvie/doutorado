# Handoff — Agentic UART loop for analog latency work

**Date:** 2026-07-06
**Repo root:** `C:\Users\daniel\Documents\DOUTORADO\embedded\esp32_idf`
**Next-session focus:** close the build/flash/test feedback loop over UART and use it to keep improving analog control-measurement latency without BLE.

## One-line status

A UART-based agent feedback loop has been partially implemented: firmware accepts task-scoped serial requests like `agent control-latency`, and the host script/Taskfile can build, flash, and query the ESP. The latest warmup-enabled loop still needs one full hardware validation run after the last edits.

## Important prior context

Do not duplicate/restart the dry-run diagnosis work. Start from:

- `handoff/control-dry-run-snapshot-latency-handoff.md` — original diagnosis: dry-run compute mode exposed stale analog snapshots.
- `docs/adr/0002-isr-notified-control-measurement-acquisition.md` — new ADR documenting the ISR-notified acquisition path decision. This file is currently uncommitted.

## Current working-tree changes

Uncommitted files at handoff time:

- `main/src/helper_analog.cpp`
  - ADC continuous frame reduced from 16 triples to 4.
  - ADC store depth reduced to 2 frames.
  - timestamp ring now matches store depth and drops oldest timestamp on overflow.
  - ADC callback timestamps the frame and wakes acquisition task with `vTaskNotifyGiveFromISR`.
  - acquisition task blocks on `ulTaskNotifyTake`, then calls `adc_continuous_read(..., timeout=0)`.
  - while control is enabled, acquisition path avoids the periodic `vTaskDelay(1)`.
- `main/main.cpp`
  - analog acquisition task priority raised to `tskIDLE_PRIORITY + 8` on Core 0.
  - added UART0 command task on Core 0.
  - added full status command: `status` / `s` -> `UART_STATUS {json}`.
  - added task-scoped agent commands:
    - `agent prepare-control-latency` -> enables compute-only control if active dataset has gain.
    - `agent control-latency` -> returns narrow `AGENT_RESULT {json}` for latency work.
- `main/src/ble_ui_command_router.cpp`
  - resets `age_used_max_us/count` when entering Live/Compute control.
- `tools/uart_status.py`
  - host helper for UART JSON requests.
  - supports `--request`, `--prefix`, `--warmup-request`, `--warmup-delay`.
- `Taskfile.yml`
  - added `uart:status`.
  - added `uart:control-latency`.
  - added `agent:control-latency` = build, flash, UART warmup, UART result.
- `docs/adr/0002-isr-notified-control-measurement-acquisition.md`
  - ADR for the ISR-notified control-measurement acquisition path.

## Current agent loop design

Firmware serial protocol over UART0/monitor port:

```text
status
  -> UART_STATUS { full JSON status }

agent prepare-control-latency
  -> AGENT_RESULT { task:"prepare-control-latency", pass, signal, engine, control, has_gain }

agent control-latency
  -> AGENT_RESULT { task:"control-latency", pass, snapshot_age_us, budget_us, floor_us, age_used_*, frame_drops, ts_fallbacks, raw_zero, raw, ... }
```

Host commands:

```sh
task uart:status

task uart:control-latency

task agent:control-latency
```

`task agent:control-latency` should:

1. build firmware,
2. flash board on configured `COM3`,
3. open serial,
4. send `agent prepare-control-latency`,
5. wait 1 s,
6. send `agent control-latency`,
7. print only the task-scoped JSON feedback.

## Validation status

Completed before latest warmup change:

- `task build` passed.
- `tools/uart_status.py --help` passed.
- Earlier `task agent:control-latency` successfully built, flashed, and queried the ESP, proving the mechanical loop works.

Earlier query result was **not a valid latency test** because control was `off` after flash. It returned roughly:

- `signal: running`
- `engine: dma`
- `control: off`
- `snapshot_age_us: 720`
- `budget_us: 282`
- `frame_drops: 14525`
- `ts_fallbacks: 3`
- raw AN3/AN5/AN6 all `0`

After that, `agent prepare-control-latency` was added so the loop can enable compute mode before measurement.

Latest `task build` after the warmup edits printed `Project build complete`, but the user interrupted the tool call. Treat full hardware validation as still pending; do not assume `task agent:control-latency` has passed after the warmup change.

## Next recommended steps

1. Run:

   ```sh
   task agent:control-latency
   ```

2. Inspect JSON:
   - if `control != "compute"`, fix `agent prepare-control-latency` first.
   - if `has_gain` is false, check initial alpha/dataset setup after flash.
   - if `snapshot_age_us > budget_us`, continue latency work.
   - if `age_used_over_budget` is true, control loop is still consuming stale samples.
   - if `frame_drops` or `ts_fallbacks` climb, timestamp/acquisition path still desyncs.
   - if `raw_zero` is true, timing may improve but live control is still blocked by ADC input/channel/wiring issue.

3. If latency still exceeds budget often, likely next technical options:
   - drain all pending ADC frames per notification, publish newest, and count dropped backlog explicitly;
   - add task-scoped UART request for a short latency sampling window, e.g. `agent control-latency-window`, returning max/p95 over N seconds instead of one point;
   - only if task-notified path remains insufficient: publish a minimal raw control measurement closer to the ADC callback, keeping ISR work tiny.

4. Keep the UART protocol task-scoped. Add new `agent <task>` handlers only for the exact feedback needed by the current debugging task.

## Known separate blocker

Raw readings still often report:

```text
AN3 raw 0
AN5 raw 0
AN6 raw 0
```

That is separate from measurement-age latency. After the latency loop is reliable, debug ADC channel mapping / attenuation / wiring / energized sense lines.

## Project guardrails

- Core 1 signal path timing is safety-critical; do not add logging/allocation/semaphores inside interrupt-disabled signal generation blocks.
- Keep ADC callback tiny: timestamp + notify only; no logging, malloc, protobuf, or calibration.
- Do not touch `web` unless needed; if `web` is touched, run `task web:build`.
- User requested concise reporting.

## Suggested skills

- `grill-with-docs` — before escalating to ISR-side publication, stress-test exact real-time constraints and document the decision.
- `domain-modeling` — if adding new task-scoped protocol terms, update `CONTEXT.md` only for stable domain vocabulary, not implementation details.
- `code-review` if available — review ISR/task notification changes before committing.
