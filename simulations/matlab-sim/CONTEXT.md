# Variable-Switching-Instant Control

This context models periodic switched systems whose controller regulates cycle-boundary state by shifting nominal switching instants while preserving the switching cycle and its period.

The authoritative domain source is the thesis at [`../../LATEX/thesis/tese.tex`](../../LATEX/thesis/tese.tex), including its active `\input` files. When this glossary, documentation, or code terminology conflicts with the thesis, resolve the conflict from the thesis first. Cited interpretation notes are recorded in [`design/domain-language-thesis-findings.md`](design/domain-language-thesis-findings.md).

## Switching Schedule

**Switching Cycle**:
One complete traversal of a switching schedule, after which the schedule repeats.
_Avoid_: Simulation step, iteration

**Nominal Switching Schedule**:
The ordered mode intervals and cycle-relative boundary times that define one uncorrected switching cycle.
_Avoid_: Trajectory, mode sequence

**Switch State**:
The simultaneous binary state of the converter switches.
_Avoid_: Mode, state

**Physical Mode ID**:
The zero-based integer encoding of a converter switch state.
_Avoid_: Mode index, dynamics index

**Dynamics Index**:
The one-based identifier of the dynamics governing a mode interval. A dynamics index is not necessarily a physical converter mode.
_Avoid_: Physical mode ID, current mode

**Mode Interval**:
A contiguous portion of a switching cycle governed by one set of dynamics.
_Avoid_: Mode, time step

**Cycle Boundary**:
A scheduled time separating adjacent mode intervals, including the cycle start and end.
_Avoid_: Switching instant

**Switching Instant**:
An interior cycle boundary at which the physical switch state changes.
_Avoid_: Boundary time, dwell time

**Nominal Boundary Time**:
The cycle-relative time assigned to a cycle boundary before control correction.
_Avoid_: Switching duration, time step

**Dwell Duration**:
The elapsed time between two consecutive cycle boundaries.
_Avoid_: Switching instant, timing deviation

**Cycle Period**:
The elapsed time from the cycle-start boundary to the cycle-end boundary.
_Avoid_: Horizon, maximum period

**Switching-Instant Offset**:
A controller-selected signed displacement $\delta t$ of an interior nominal switching time. Positive values move that switching time later without changing the cycle period.
_Avoid_: Dwell-time change, time step, timing deviation

## State and Orbit

**Nominal Periodic Orbit**:
The periodic state evolution induced by repeatedly applying a nominal switching schedule.
_Avoid_: Trajectory, equilibrium

**Orbit Anchor**:
The point on a nominal periodic orbit at the selected cycle-start boundary; equivalently, a fixed point of the one-cycle map.
_Avoid_: Equilibrium, initial state, target state

**Desired Operating Point**:
The average physical-state objective used to select a nominal periodic orbit. It is not generally a point on that orbit.
_Avoid_: Orbit anchor, reference state, controller target

**Active State Setpoint**:
The nominal-orbit state corresponding to the controlled cycle phase. At the cycle-start boundary, it is the orbit anchor.
_Avoid_: Desired operating point, unqualified target

**Simulation Initial State**:
The state from which a simulation run begins.
_Avoid_: Orbit anchor, equilibrium, x0

**Cycle Input State**:
The state at the cycle-start boundary for a particular switching cycle.
_Avoid_: Initial state, cycle-end state, x0

**Initial-State Disturbance**:
An additive perturbation applied to the simulation initial state.
_Avoid_: Offset, equilibrium offset

**Orbit Deviation**:
The error $e(t)=x(t)-\bar{x}(\bar{t})$ between the actual state and corresponding nominal-orbit state. At the cycle-start boundary, it is the cycle input state minus the orbit anchor.
_Avoid_: Desired-operating-point error, tracking error

**One-Cycle Linear Model**:
The thesis equation $e(t_{j,N})=\Phi e(t_{j,0})+\Gamma\delta t[j]$ relating cycle-start orbit deviation and switching-time perturbations to cycle-end orbit deviation.
_Avoid_: State-space model, blocked prediction model

**Homogeneous State Augmentation**:
The representation $\mathcal{X}=[x;1]$ that converts affine mode dynamics into homogeneous linear dynamics. It is a derivation technique, not an actuation-delay model.
_Avoid_: Augmented prediction model, delay augmentation

**Simulated State History**:
The time-ordered states produced during a simulation run.
_Avoid_: Trajectory, nominal periodic orbit

## Control and Prediction

**Control Action**:
The controller output selected for actuation; in this context it is a vector of switching-instant offsets.
_Avoid_: Duty ratio, dwell-time change

**Nominal Duty Ratio**:
The per-cell on-time fraction used to construct a nominal switching schedule. It is a schedule parameter, not the cycle-by-cycle control action.
_Avoid_: Control input, alpha without qualification

**Held Action**:
A previously selected control action reapplied until the next controller update.
_Avoid_: Previous action, delayed action

**Control Update Period**:
The number $N_d$ of switching cycles between controller computations. A newly computed action applies immediately and is held until the next update.
_Avoid_: Prediction horizon, actuation delay

**Prediction Block**:
A group of consecutive switching cycles over which one control action is held constant.
_Avoid_: Prediction horizon, actuation delay

**Block Length**:
The number of switching cycles represented by one prediction-block transition. In the baseline model it equals the control update period.
_Avoid_: Number of delays, prediction horizon

**Actuation Delay**:
The elapsed number of cycles or prediction blocks between selecting an action and applying it. The baseline simulation has no actuation delay.
_Avoid_: Control update period, block length

**Prediction Horizon**:
The number $N_p$ of transitions in the configured prediction model over which control actions are planned.
_Avoid_: Number of physical cycles

**Finite-Horizon Feasible Set**:
The predictor states for which an admissible action plan exists over the prediction horizon and satisfies the terminal constraint.
_Avoid_: Recursive-feasibility region, recoverable states
