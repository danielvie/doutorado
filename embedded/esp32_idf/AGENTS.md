# ESP32 Signal Controller — Contributor and Agent Guide

This file is the entry point for changes to this real-time control firmware. Read the
applicable documents before changing behavior; do not treat historical analysis or
handoff material as the current architecture.

## Read in this order

1. [CONTEXT.md](CONTEXT.md) — canonical domain glossary. Use its terms in
   requirements, UI text, and documentation. It is not an implementation specification.
2. [Project goals and requirements](docs/PROJECT_GOALS.md) — behavioral and
   signal-timing requirements.
3. Accepted architectural decisions:
   - [ADR 0001: CPU and DMA signal engines](docs/adr/0001-dual-signal-engine-i2s-dma.md)
   - [ADR 0002: control-measurement acquisition](docs/adr/0002-isr-notified-control-measurement-acquisition.md)
4. [Analog reader validation](docs/TEST_ANALOG_READER_VALIDATION.md) — lab and
   telemetry validation expectations for control measurements.
5. Current implementation and target configuration — `main/`, `sdkconfig`, and
   `sdkconfig.defaults*`. If these conflict with the documents above, identify the
   discrepancy and resolve it deliberately; do not silently preserve a stale design.

[README.md](README.md) is a general project overview. Files under `docs/agent/`,
`handoff/`, root-level tutorial HTML files in `docs/`, and the `*ANALYSIS*.md`
reports are historical or supporting material, not architecture authority.

## Real-time Core 1 invariants

Signal generation has two runtime-selectable engines. Preserve their separate
execution models:

- **CPU engine:** `signal_loop_task` is pinned to Core 1. It disables interrupts
  only for timing-critical GPIO playback; this prevents jitter that could fault a
  power converter. The interrupt-masked region must contain no logging, allocation,
  parsing, synchronization, or FreeRTOS calls. Keep unrelated application work on
  Core 0 while this engine is active.
- **DMA engine:** the Core 1 DMA control task and I2S ISR own waveform playback.
  Interrupts remain enabled for its control work, and its task explicitly participates
  in the task watchdog. Do not apply CPU-engine interrupt restrictions to DMA control
  work without a documented timing reason.
- The automatic Core 1 interrupt-watchdog check and Core 1 idle-task watchdog
  monitoring are intentionally disabled in `sdkconfig`
  (`CONFIG_ESP_INT_WDT_CHECK_CPU1` and
  `CONFIG_ESP_TASK_WDT_CHECK_IDLE_TASK_CPU1` are unset). This does not mean that
  every Core 1 task is unmonitored: DMA explicitly registers its control task with
  the task watchdog.

Do not change Core 1 task pinning, watchdog configuration, GPIO playback timing, or
the CPU interrupt-masking scope without an explicit architecture decision and
oscilloscope timing validation.
