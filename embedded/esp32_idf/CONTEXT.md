# ESP32 Signal Controller

The ESP32 Signal Controller context defines the domain language for an ESP32-based system used in real-time signal generation and measurement experiments.

For project goals, requirements, and behavioral constraints, see [ESP32 Signal Controller Goals and Requirements](docs/PROJECT_GOALS.md).

## Language

**ESP32 Signal Controller**:
An ESP32-based system used to generate real-time digital signals and collect measurements for real-time control experiments.
_Avoid_: ESP32 BLE Signal Controller, digital signal controller, signal generator

**Real-Time Control Experiment**:
An experiment where control signals and measurements must respect strict timing constraints for the result to be valid.
_Avoid_: signal test, GPIO test, demo

**Duration Tick**:
The integer unit used to configure a signal segment duration; one duration tick represents 0.1 µs.
_Avoid_: time, sample, precision

**Commanded Duration**:
The intended physical duration of a signal segment, calculated as `duration_ticks_0p1us × 0.1 µs`.
_Avoid_: requested time, delay, sleep time

**Observed Duration**:
The physical duration of a signal segment measured on an oscilloscope during lab validation.
_Avoid_: real time, measured period

**Lab Timing Characterization**:
The oscilloscope-based validation process used to measure timing error and jitter before defining numeric acceptance thresholds.
_Avoid_: simulation, visual check, assumed tolerance

**Timing Error**:
The difference between observed duration and commanded duration.
_Avoid_: jitter, resolution

**Signal Timing Contract**:
The requirement that configured segment durations, total cycle duration, dead time, and edge compensation produce oscilloscope-observed signals matching the commanded signal cycle within measured timing error and jitter, without being disturbed by maintenance or control computation.
_Avoid_: timing behavior, performance target, waveform quality

**Timing Fault**:
A condition where the controller cannot preserve the signal timing contract, including missed transition deadlines, forced segment-duration clamping, or maintenance/control work that would disturb the next signal cycle.
_Avoid_: jitter, measurement error, warning

**Recoverable Timing Fault**:
A timing fault that can be reported while signal generation continues without further disturbing the commanded signal timing.
_Avoid_: warning, soft error

**Unrecoverable Timing Fault**:
A timing fault after which the controller cannot safely preserve commanded signal timing and must enter a safe stopped state.
_Avoid_: crash, hard error

**Dead Time**:
The intentionally inserted interval during an output-group state transition where both terminals of the changing output group are inactive before the target terminal is activated.
_Avoid_: delay, edge overhead, idle segment

**Edge Compensation**:
A calibrated timing adjustment, expressed in CPU cycles, applied at a signal segment boundary so observed signal edges better match commanded durations.
_Avoid_: edge overhead, edge cycles, dead time

**Boundary-Level Edge Compensation**:
Edge compensation chosen once for an entire signal segment boundary, even when multiple output groups change at that boundary.
_Avoid_: per-output compensation, per-pin compensation

**Rising Boundary**:
A signal segment boundary where at least one changing output group transitions from LOW command state to HIGH command state.
_Avoid_: up edge, rising pin

**Falling Boundary**:
A signal segment boundary where output groups change and no changing output group transitions from LOW command state to HIGH command state.
_Avoid_: down edge, falling pin

**Jitter**:
The variation between repeated observed durations for the same configured signal segment.
_Avoid_: timing error, resolution

**Alpha**:
The normalized duty-cycle parameter (`rapport cyclique`) of the converter switching cells; its valid mathematical range is 0 to 1, and the project currently supports 0.1 to 0.9 as selectable dataset operating points.
_Avoid_: MPC weighting factor, generic weight, preset

**Operating Point**:
The control condition identified by alpha, where each supported alpha value selects a dataset.
_Avoid_: preset, duty setting, case

**Dataset**:
A complete signal-control configuration for one operating point, containing the signal cycle definition, control target, and gain matrix needed to generate and correct the signal.
_Avoid_: lookup table, signal only, matrix only

**Signal Cycle**:
One complete signal sent by the controller, defined by playing the configured `duration_ticks_0p1us` and `mode` vectors exactly once.
_Avoid_: loop, period, iteration

**Signal Cycle Window**:
The time interval covered by one complete signal cycle.
_Avoid_: period, loop time, read slot

**Output Group**:
One controlled digital output pair named `U1`, `U2`, or `U3`, where each group has a `Low` terminal and a `High` terminal.
_Avoid_: D4, D5, D6, channel

**Output Group Command State**:
The commanded state of an output group; LOW activates the group's `Low` terminal and deactivates its `High` terminal, while HIGH activates the group's `High` terminal and deactivates its `Low` terminal.
_Avoid_: raw GPIO level, voltage level

**Switching Mode**:
The integer binary encoding of the commanded LOW/HIGH state for output groups `U1`, `U2`, and `U3` during one signal segment; mode `0` commands all groups LOW and mode `7` commands all groups HIGH.
_Avoid_: mode, binary mode, state number

**Switching Mode Bit Mapping**:
The mapping from switching mode bits to output groups: bit 2 controls `U1`, bit 1 controls `U2`, and bit 0 controls `U3`.
_Avoid_: D4/D5/D6 mapping, UI binary mapping

**Control Measurement**:
The calibrated analog values and timestamp consumed at the control point to compute a control action; currently composed of `VR`, `V_C1`, and `V_C2`.
_Avoid_: ADC sample, analog reading, control snapshot

**Control Measurement Channel Mapping**:
The mapping from ESP analog ports to physical control variables: `AN3` maps to `VR`, `AN5` maps to `V_C1`, and `AN6` maps to `V_C2`.
_Avoid_: unlabeled an3/an5/an6 values

**Control Vector**:
The ordered control measurement vector used by the control law: `[V_C1, V_C2, VR]`.
_Avoid_: `[VR, V_C1, V_C2]`, unlabeled target vector

**Gain Matrix K**:
The dataset-specific control matrix that maps the control error vector `[V_C1, V_C2, VR]` to signal-duration corrections for the next cycle.
_Avoid_: generic matrix, gain table, coefficient list

**Signal-Duration Correction**:
A control-computed adjustment, expressed in duration ticks, applied to controllable signal segments for the next signal cycle while preserving the signal timing contract.
_Avoid_: delta time, control output, correction value

**Cycle-Closing Segment**:
The final signal segment, whose correction is derived from prior signal-duration corrections so the total signal cycle duration remains consistent with the operating point.
_Avoid_: compensation segment, last point, unused segment, tail

**Current-Cycle Measurement**:
A control measurement whose timestamp belongs to the signal cycle currently being used to compute the next control action.
_Avoid_: latest reading, current value

**Control-Measurement Timing Validation**:
The validation method that compares control-measurement timestamps and control-point timing against the signal cycle window, with oscilloscope correlation when needed.
_Avoid_: ADC performance test, telemetry check

**Measurement Age**:
The elapsed time between an analog measurement timestamp and the control point that consumes it.
_Avoid_: freshness, latency, delay

**Control Point**:
The maintenance interval between repeated signal cycle playbacks where the system consumes the current-cycle measurement and computes the next-cycle control action.
_Avoid_: read point, update point, control window

**Next-Cycle Control Action**:
A control correction computed from current-cycle measurements and applied to the following signal cycle.
_Avoid_: immediate control, same-cycle correction

**Missed Control Update**:
A control update that is skipped because it cannot complete before the next signal cycle without disturbing generated signal timing.
_Avoid_: failed control, delayed cycle, stale update
