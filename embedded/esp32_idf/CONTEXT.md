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
The integer unit used to configure a dwell duration; one duration tick represents 0.1 µs.
_Avoid_: time, sample, precision

**Commanded Duration**:
The intended physical dwell duration of a mode interval, calculated as `duration_ticks_0p1us × 0.1 µs`.
_Avoid_: requested time, delay, sleep time

**Observed Duration**:
The physical dwell duration of a mode interval measured on an oscilloscope during lab validation.
_Avoid_: real time, measured period

**Lab Timing Characterization**:
The oscilloscope-based validation process used to measure timing error and jitter before defining numeric acceptance thresholds.
_Avoid_: simulation, visual check, assumed tolerance

**Timing Error**:
The difference between observed duration and commanded duration.
_Avoid_: jitter, resolution

**Signal Timing Contract**:
The requirement that configured dwell durations, cycle period, dead time, and edge compensation produce oscilloscope-observed signals matching the commanded switching cycle within measured timing error and jitter, without being disturbed by maintenance or control computation.
_Avoid_: timing behavior, performance target, waveform quality

**Timing Fault**:
A condition where the controller cannot preserve the signal timing contract, including missed transition deadlines, forced dwell-duration clamping, or maintenance/control work that would disturb the next switching cycle.
_Avoid_: jitter, measurement error, warning

**Recoverable Timing Fault**:
A timing fault that can be reported while signal generation continues without further disturbing the commanded signal timing.
_Avoid_: warning, soft error

**Unrecoverable Timing Fault**:
A timing fault after which the controller cannot safely preserve commanded signal timing and must enter a safe stopped state.
_Avoid_: crash, hard error

**Dead Time**:
The intentionally inserted interval during an output-group state transition where both terminals of the changing output group are inactive before the target terminal is activated. Dead time is carved out of the surrounding commanded dwell duration and must not extend the switching cycle period.
_Avoid_: delay, edge overhead, idle segment

**Edge Compensation**:
A calibrated timing adjustment, expressed in CPU cycles, applied at a cycle boundary so observed signal edges better match commanded durations.
_Avoid_: edge overhead, edge cycles, dead time

**Boundary-Level Edge Compensation**:
Edge compensation chosen once for an entire cycle boundary, even when multiple output groups change at that boundary.
_Avoid_: per-output compensation, per-pin compensation

**Rising Boundary**:
A cycle boundary where at least one changing output group transitions from LOW command state to HIGH command state.
_Avoid_: up edge, rising pin

**Falling Boundary**:
A cycle boundary where output groups change and no changing output group transitions from LOW command state to HIGH command state.
_Avoid_: down edge, falling pin

**Jitter**:
The variation between repeated observed durations for the same configured mode interval.
_Avoid_: timing error, resolution

**Nominal Duty Ratio**:
The per-cell on-time fraction used to select a nominal switching schedule; the ESP32 interface denotes it by $\alpha$.
_Avoid_: Alpha without qualification, operating point, control input, MPC weight

**Dataset**:
A complete signal-control configuration for one nominal duty ratio, containing the nominal switching schedule, active state setpoint, and gain matrix.
_Avoid_: Operating point, lookup table, signal only, matrix only

**Switching Cycle**:
One complete traversal of a switching schedule, after which the schedule repeats.
_Avoid_: Signal cycle, loop, iteration

**Nominal Switching Schedule**:
The ordered mode intervals and cycle-relative boundary times that define one uncorrected switching cycle.
_Avoid_: Signal definition, mode sequence, duty cycle

**Mode Interval**:
A contiguous portion of a switching cycle during which the switch state is constant.
_Avoid_: Signal segment, mode, time step

**Cycle Boundary**:
A scheduled time separating adjacent mode intervals, including the cycle start and end.
_Avoid_: Switching instant

**Switching Instant**:
An interior cycle boundary at which the switch state changes.
_Avoid_: Switching time when it could mean a duration, dwell duration

**Dwell Duration**:
The elapsed time between two consecutive cycle boundaries.
_Avoid_: Signal-segment duration, dwell interval, switching time, gap

**Minimum Dwell Duration**:
The lower bound imposed on every dwell duration.
_Avoid_: Minimum dwell time, minimum switching time, time constraint

**Cycle Period**:
The elapsed time from the cycle-start boundary to the cycle-end boundary.
_Avoid_: Switching cycle window, horizon, maximum period

**Switching Cycle Window**:
The time interval occupied by one particular switching cycle.
_Avoid_: Signal cycle window, cycle period, loop time, read slot

**Output Group**:
One controlled digital output pair named `U1`, `U2`, or `U3`, where each group has a `Low` terminal and a `High` terminal.
_Avoid_: D4, D5, D6, channel

**Output Group Command State**:
The commanded state of an output group; LOW activates the group's `Low` terminal and deactivates its `High` terminal, while HIGH activates the group's `High` terminal and deactivates its `Low` terminal.
_Avoid_: raw GPIO level, voltage level

**Switch State**:
The simultaneous commanded LOW/HIGH state of output groups `U1`, `U2`, and `U3` during one mode interval.
_Avoid_: Switching mode, mode, state

**Physical Mode ID**:
The zero-based integer encoding of a switch state; ID `0` commands all groups LOW and ID `7` commands all groups HIGH.
_Avoid_: Switching mode, mode index, dynamics index

**Physical Mode ID Bit Mapping**:
The mapping from physical-mode-ID bits to output groups: bit 2 controls `U1`, bit 1 controls `U2`, and bit 0 controls `U3`.
_Avoid_: Switching mode bit mapping, D4/D5/D6 mapping, UI binary mapping

**Control Measurement**:
The calibrated analog values and timestamp consumed at the control point to compute a control action; currently composed of `VR`, `V_C1`, and `V_C2`.
_Avoid_: ADC sample, analog reading, control snapshot

**Control Measurement Channel Mapping**:
The mapping from ESP analog ports to physical control variables: `AN3` maps to `VR`, `AN5` maps to `V_C1`, and `AN6` maps to `V_C2`.
_Avoid_: unlabeled an3/an5/an6 values

**Control Vector**:
The ordered control measurement vector used by the control law: `[V_C1, V_C2, VR]`.
_Avoid_: `[VR, V_C1, V_C2]`, unlabeled target vector

**Active State Setpoint**:
The nominal-periodic-orbit state corresponding to the controlled cycle phase.
_Avoid_: Desired operating point, unqualified target, reference state

**Control Error**:
The difference between the control vector and active state setpoint. It is an orbit deviation only when both correspond to the same switching-cycle phase.
_Avoid_: Desired-operating-point error, unqualified error

**Gain Matrix K**:
The dataset-specific feedback gain that maps the control error to switching-instant offsets.
_Avoid_: Generic matrix, gain table, coefficient list

**Switching-Instant Offset**:
A controller-selected signed displacement of an interior nominal switching instant, calculated for the next switching cycle.
_Avoid_: Signal-duration correction, switching-time perturbation, dwell-duration change, control signal

**Signal-Duration Correction**:
A duration-tick adjustment derived from adjacent switching-instant offsets and applied to a mode interval when rendering the next switching cycle.
_Avoid_: Switching-instant offset, control action, correction value

**Cycle-Closing Mode Interval**:
The final mode interval, whose signal-duration correction closes the fixed switching cycle period after prior interval corrections.
_Avoid_: Cycle-closing segment, compensation segment, unused segment, tail

**Current-Cycle Measurement**:
A control measurement whose timestamp belongs to the switching cycle currently being used to compute the next control action.
_Avoid_: latest reading, current value

**Control-Measurement Timing Validation**:
The validation method that compares control-measurement timestamps and control-point timing against the switching cycle window, with oscilloscope correlation when needed.
_Avoid_: ADC performance test, telemetry check

**Measurement Age**:
The elapsed time between an analog measurement timestamp and the control point that consumes it.
_Avoid_: freshness, latency, delay

**Control Point**:
The maintenance interval between repeated switching cycle playbacks where the system consumes the current-cycle measurement and computes the next-cycle control action.
_Avoid_: read point, update point, control window

**Next-Cycle Control Action**:
A vector of switching-instant offsets computed from a current-cycle measurement and applied to the following switching cycle.
_Avoid_: immediate control, same-cycle correction

**Missed Control Update**:
A control update that is skipped because it cannot complete before the next switching cycle without disturbing generated signal timing.
_Avoid_: failed control, delayed cycle, stale update

**Signal Engine**:
The runtime-selectable mechanism that plays switching cycles on the output groups; the CPU engine times transitions with the processor, while the DMA engine plays back a rendered bitstream.
_Avoid_: mode, driver, backend

**Rendered Bitstream**:
The expansion of one switching cycle into a sequence of equal-duration samples of output-group terminal states, played back by the DMA engine without processor involvement.
_Avoid_: buffer, waveform table, sample array

**Sample Clock**:
The fixed rate at which rendered bitstream samples are emitted, defining the timing granularity of the DMA engine.
_Avoid_: bitrate, resolution, tick

**Correction Commit Deadline**:
The moment by which a next-cycle control action must be committed to the signal engine, before the next switching cycle begins; an action that misses it becomes a missed control update while signal timing continues undisturbed.
_Avoid_: relink deadline, EOF deadline, control window
