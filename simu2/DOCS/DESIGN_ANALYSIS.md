# Design Analysis

Last updated: 2026-05-05

This document tracks the current architectural/design assessment of the MATLAB
Multi-Cell Buck-Boost Converter MPC project. Keep it updated when controller,
simulation, hardware, or logging boundaries change.

## Scope

Reviewed areas:

- Entry points: `t.m`, `Taskfile.yml`
- Core simulation facade: `@Simulation/`
- Controllers: `+Controllers/`
- Dynamics propagation: `+Dynamics/`
- MPC solver path: `+Mpc/`
- Hardware/BLE boundary: `@BTBroker/`, `+Hardware/`
- Results and utility support: `+Results/`, `+Utils/`

## Identifier Scheme

Use these identifiers when referring to notes in issues, commits, TODOs, or
discussion:

- `0a`, `0b`, ...: architecture-summary notes
- `1a`, `1b`, ...: complexity-debt findings
- `2a`, `2b`, ...: priority fixes
- `3a`, `3b`, ...: future-update triggers

Keep existing identifiers stable. If a finding is resolved, mark it resolved in
place instead of reusing its identifier for another concern.

When referring to an item to fix, include the identifier of the finding it
addresses. Example: `2b` fixes `1a`.

## Architecture Summary

The project has a sensible research-code structure that is moving toward deeper
modules:

- `0a`: `@Simulation` coordinates configuration, trajectory planning, MPC setup,
  simulation execution, logging, and diagnostic helpers.
- `0b`: `+Controllers` contains the newer controller abstraction:
  `Controllers.Controller`, `Controllers.MpcController`, and
  `Controllers.Proportional`.
- `0c`: `+Dynamics` separates switching-instant propagation from dense
  propagation via `Dynamics.StepStrategy`, `Dynamics.SwitchingStrategy`, and
  `Dynamics.DenseStrategy`.
- `0d`: `+Mpc` owns MPC matrix construction and QP solve logic.
- `0e`: `@BTBroker` owns the BLE device lifecycle and message loop for the ESP32
  hardware prototype.
- `0f`: `+Options` owns user-facing setup schemas, such as
  `Options.Mpc`. These objects describe setup requests; built runtime
  artifacts live under `s.m_config`.

The strongest current design move is the strategy split for control and
dynamics. `@Simulation/run.m` now reads as a clean orchestration loop:
control step, actuation step, physics step, storage/logging, and state update.

## Complexity Debt

### 1a. Active Control Path Split

Simulation and hardware do not currently share the same control path.

- `@Simulation/run.m` calls `self.step_control(...)`, which delegates to
  `self.m_controller.compute_control(...)`.
- `@Simulation/signal_process.m` still calls legacy `run_mpc(...)`.
- `@Simulation/run_mpc.m` currently uses a proportional law from `K` while the
  QP call is commented out.

Impact: MATLAB simulation and BLE hardware can silently use different control
laws. This is the most important architectural inconsistency because it can make
bench results and hardware behavior diverge.

Recommended fix: route `signal_process()` through the same controller interface
used by `run()`, then retire or clearly mark `run_mpc.m` as legacy.

### 1b. `set_mpc()` Did Not Install a Controller

Status: resolved.

Current implementation: `Options.Mpc` is the explicit MPC setup schema.
`set_mpc(options)` owns MPC matrix construction, target resolution, controller
creation, runtime artifact assignment under `s.m_config.mpc`, and runtime
control state under `s.m_config.control`.

Resolved decisions:

- `D48`: runtime control state lives in `s.m_config.control`.
- `D49`: target lives only in `s.m_config.control.x_target`.
- `D50`: enabled state lives only in `s.m_config.control.on`.
- `D51`: `Data.Config` initializes `control.on` and `control.x_target`.
- `D52`: `get_target()` reads `s.m_config.control.x_target`.
- `D53`: hardware control messages read target from `config.control.x_target`.
- `D54`: `Results.SimulationData.target` reads `config.control.x_target`.
- `D55`: `control` has only `on` and `x_target`.
- `D56`: per-iteration target logs are sourced from `control.x_target`.
- `D57`: `signal_process()` uses `control.x_target`; full legacy
  `run_mpc()` removal remains a later `1a` cleanup.
- `D58`: legacy `run_mpc()` receives target explicitly.
- `D62`: `1b` grilling complete.

### 1c. `@Simulation` Is Still a Large Facade

`@Simulation/Simulation.m` exposes configuration, trajectory setup, MPC setup,
control, actuation, propagation wrappers, projection, export, diagnostics, and
aliases.

Impact: conceptual changes often require touching `@Simulation`, and the class
interface leaks many internal concerns. It is usable, but not yet a deep module.

Recommended fix: keep `Simulation.run()` as the orchestration API, but gradually
move specialized responsibilities behind smaller deep modules:

- MPC setup/building
- log storage and export
- hardware signal processing
- projection/feasibility analysis

### 1d. Hardware Boundary Needs Validation

`@BTBroker/msg_handle_process.m` parses free-form BLE text with a permissive
regular expression, checks only for `an6`, then reads `an5` and `an3`. It scales
measurements, computes control timing, creates a signal command, and writes back
to the ESP32.

Impact: malformed or partial messages can error or produce invalid control
commands. Sensor bounds, command sizes, and invalid parse reasons are not logged
systematically.

Recommended fix:

- Require all expected fields: `an3`, `an5`, `an6`.
- Decide whether signed and scientific-notation numbers are valid, then parse
  explicitly.
- Reject out-of-range voltage/current values before control computation.
- Log parse failures and outgoing command dimensions when verbose or diagnostic
  logging is enabled.

### 1e. Timing Safety Is Inconsistent

`@Simulation/step_actuation.m` asserts that all switching intervals are positive.
The hardware path in `@Simulation/signal_process.m` computes `time_us` directly
after applying `dtk`, without the same shared validation.

Impact: simulation can reject invalid timing while hardware may still send it.

Recommended fix: create one timing validation/formatting helper and use it from
both `step_actuation()` and `signal_process()`.

### 1f. Scaling and Performance Bounds Are Implicit

Hotspots:

- `+Mpc/dualmode_switching.m` rebuilds QP matrices/options and calls `quadprog`.
- `+Dynamics/propagate_switching.m` calls `expm` once per mode per simulated
  cycle.
- `+Dynamics/propagate_dense.m` can allocate large dense trajectories depending
  on `tstep`, period, and number of cycles.

Impact: fine for small research examples, but the expected maximum horizon
(`Np`), modes, and simulation cycle count are not declared.

Recommended fix: document expected maxima and add lightweight guards for
`nsim`, `Np`, `numel(Omega)`, and dense trajectory size. Cache static QP options
or matrices where possible.

### 1g. Observability Is Uneven

`@Simulation/run.m` has good preallocated run logs. The BLE path and parse/error
paths are much quieter.

Impact: offline simulation is inspectable, but live hardware behavior can be
hard to diagnose after missed messages, invalid measurements, or fallback
control.

Recommended fix: standardize outcome logging for boundary operations:

- BLE read parse success/failure
- Control compute success/fallback
- Outgoing command size and timing intervals
- Latency for QP/control computation

## Complexity Debt Score

- Scaling/Performance Risks: 2
- Architectural Leaks: 3
- Observability Gaps: 2
- Safety Violations: 2

Overall rating: C+

The project has a good modular direction and a workable package layout. The main
debt is not lack of structure; it is that old and new paths coexist in active
control behavior, especially between simulation and hardware.

## Priority Fix Order

1. `2a` fixes `1b`: Done. `set_mpc()` installs `Controllers.MpcController`,
   stores control state in `s.m_config.control`, and `run()` fails early if
   control is enabled without a controller or target.
2. `2b` fixes `1a`: Route `signal_process()` through the same controller
   abstraction as `run()`.
3. `2c` fixes `1e`: Share timing validation between simulation and hardware.
4. `2d` fixes `1d`: Harden BLE parsing and add measurement range checks.
5. `2e` fixes `1f`: Add bounded-size expectations for `nsim`, `Np`, `Omega`,
   and dense outputs.
6. `2f` fixes `1g`: Add hardware-boundary outcome logs for parse, control, and
   send operations.

## Notes for Future Updates

Update this document whenever:

- `3a`: `@Simulation/run.m`, `@Simulation/signal_process.m`, or controller setup
  changes.
- `3b`: `@BTBroker` message parsing or hardware command formatting changes.
- `3c`: MPC solve behavior changes between QP, proportional fallback, or cached
  lookup control.
- `3d`: New performance limits or test coverage are added.
