# Context Map

## Contexts

- [Doctorate Repository](./CONTEXT.md) — names the research artifacts maintained by the doctorate project
- [Variable-Switching-Instant Control](./simulations/matlab-sim/CONTEXT.md) — defines the thesis-aligned model for schedules, periodic orbits, and predictive control
- [Proportional Switching-Time Control](./LATEX/papers/paper-proportional-switching-time-controller/CONTEXT.md) — specializes the shared control language for static proportional feedback and dwell-time conditioning
- [ESP32 Signal Controller](./embedded/esp32_idf/CONTEXT.md) — specializes the shared control language for hardware signal generation, measurement, and next-cycle actuation

## Relationships

- **Thesis → Control contexts**: The thesis defines the mathematical meaning; the MATLAB glossary records the canonical disambiguations used across the simulation, article, and embedded experiment.
- **MATLAB simulation → Proportional controller article**: Both use `Nominal Switching Schedule`, `Nominal Periodic Orbit`, `Orbit Anchor`, `Orbit Deviation`, and `Switching-Instant Offset`; the article adds `Proportional Switching-Time Controller` and `Dwell-Time Conditioning`.
- **MATLAB simulation → ESP32 signal controller**: A dataset carries a nominal schedule, active state setpoint, and gain matrix into the embedded experiment. The embedded controller converts `Switching-Instant Offset` values into quantized `Signal-Duration Correction` values for playback.
- **Shared switch encoding**: `Switch State` is the simultaneous physical switch configuration, `Physical Mode ID` encodes that configuration, and `Dynamics Index` identifies the affine dynamics used by a model. These terms are not interchangeable.

## Supporting Agent Context

- [ESP32 operational agent context](./embedded/esp32_idf/docs/agent/AGENT_CONTEXT.md) — records local toolchain and editor setup; it is not a domain glossary
