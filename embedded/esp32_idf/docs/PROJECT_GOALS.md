# ESP32 Signal Controller Goals and Requirements

This document uses the domain language defined in [CONTEXT.md](../CONTEXT.md).

## Goal

The ESP32 Signal Controller exists to support real-time control experiments by generating deterministic digital signals and collecting measurements under strict timing constraints.

## Requirements

### Dataset

Alpha is the normalized duty-cycle parameter (`rapport cyclique`) of the converter switching cells. Its valid mathematical range is 0 to 1. The project currently supports 0.1 to 0.9 as the selectable operating point range, with each selectable alpha value choosing a precomputed dataset.

In this project, alpha means duty cycle. The thesis may also use alpha for MPC weighting factors greater than zero, but that is not the meaning used by the ESP32 Signal Controller UI or dataset selection.

An operating point is the control condition identified by alpha, where each supported alpha value selects a dataset.

A dataset is a complete signal-control configuration for one operating point, containing the signal cycle definition, control target, and gain matrix needed to generate and correct the signal.

### Configured Signal Cycle

A signal cycle is configured by pairing each `duration_ticks_0p1us` entry with one switching mode. A switching mode is the binary LOW/HIGH command for output groups `U1`, `U2`, and `U3`; mode `0` commands all groups LOW and mode `7` commands all groups HIGH.

Switching mode bits map to output groups as follows: bit 2 controls `U1`, bit 1 controls `U2`, and bit 0 controls `U3`. Each output group has a `Low` terminal and a `High` terminal, matching the hardware labels `U1Low/U1High`, `U2Low/U2High`, and `U3Low/U3High`.

LOW and HIGH are output-group command states: LOW activates the group's `Low` terminal and deactivates its `High` terminal, while HIGH activates the group's `High` terminal and deactivates its `Low` terminal.

Dead time is inserted during output-group state transitions so both terminals of a changing output group are inactive before the target terminal is activated.

Edge compensation is a calibrated timing adjustment, expressed in CPU cycles, applied at a signal segment boundary so observed signal edges better match commanded durations.

Mixed transitions are allowed and use boundary-level edge compensation. A boundary is classified as rising if any changing output group transitions LOW→HIGH; otherwise, a boundary with changes is classified as falling. This preserves the current oscilloscope-validated firmware behavior.

GPIO and test-point mappings are hardware-interface details and are documented separately in hardware documentation.

BLE and web command names are interface/API details and are documented separately from domain terminology unless a command introduces a domain concept.

### Configured Duration Fidelity

The system must accept signal segment durations as integer `duration_ticks_0p1us`, where one tick represents 0.1 µs. A segment configured as `508` ticks has a commanded duration of 50.8 µs, and the observed oscilloscope duration should match that commanded duration subject to measured timing error and jitter.

Timing resolution, timing error, and jitter are separate concerns: resolution is the configured 0.1 µs tick size; timing error is the difference between observed duration and commanded duration; jitter is variation across repeated observed durations.

The signal timing contract requires configured segment durations, total cycle duration, dead time, and edge compensation to produce oscilloscope-observed signals matching the commanded signal cycle within measured timing error and jitter, without being disturbed by maintenance or control computation.

Numeric timing acceptance thresholds are deferred until lab timing characterization. Timing error and jitter must be measured on an oscilloscope before pass/fail thresholds are defined.

Maintenance and control computation must not disturb the generated signal timing. If maintenance cannot complete without changing the observed signal cycle duration or segment durations, the system must treat that as a timing fault rather than silently stretching the signal.

Timing faults include missed transition deadlines, forced segment-duration clamping, and maintenance/control work that would disturb the next signal cycle.

The controller must report timing faults through telemetry or debug status. Recoverable timing faults should be reported while signal generation continues without further disturbing commanded timing. Unrecoverable timing faults must move signal generation to a safe stopped state.

If control computation cannot finish before the next signal cycle without disturbing generated timing, the controller must skip that control update, keep the previous correction, and record a missed-control-update fault.

### Current-Cycle Measurement for Control

When computing a control action, the system must use a control measurement whose timestamp belongs to the current signal cycle. A control measurement contains the calibrated analog values and timestamp consumed at the control point. Current-cycle measurements are used to compute the control correction for the next signal cycle.

Control measurement channels use both physical names and ESP analog-port names. The current mapping is `AN3 -> VR`, `AN5 -> V_C1`, and `AN6 -> V_C2`.

The canonical control vector order is `[V_C1, V_C2, VR]`. Control targets, error vectors, and gain matrices must use this order.

Gain Matrix K is the dataset-specific control matrix that maps the control error vector `[V_C1, V_C2, VR]` to signal-duration corrections for the next cycle.

Signal-duration corrections are expressed in duration ticks and apply to controllable signal segments except the final cycle-closing segment. The cycle-closing segment must absorb the timing consequence of corrections so the total signal cycle duration remains consistent with the operating point.

I1: Firmware control-vector ordering is aligned with the canonical order by using `AN5, AN6, AN3`, corresponding to `[V_C1, V_C2, VR]`.

The control point occurs during the maintenance interval between repeated signal cycle playbacks. At that point, the system consumes the freshest available current-cycle measurement and computes the next-cycle control action.

The measurement age at the control point must be as small as practical, so the control correction represents the latest observable state of the current cycle.

Control-measurement timing is validated by comparing measurement timestamps and control-point timing against the signal cycle window, with oscilloscope correlation when needed.

Example: for a signal cycle with `duration_ticks_0p1us: 560, 373, 560, 373, 560, 373`, the total cycle window is 279.9 µs. The measurement used at the control point must be timestamped within that 279.9 µs cycle window so the resulting correction represents the current cycle and can be applied to the next cycle playback.
