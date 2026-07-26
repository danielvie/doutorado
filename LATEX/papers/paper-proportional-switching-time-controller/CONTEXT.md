# Proportional Switching-Time Control

This context defines the language for cycle-to-cycle stabilization of a switched-affine plant by shifting its nominal switching instants.

## Plant and Orbit

**Switched-Affine Plant**:
A continuous-time plant whose state dynamics are affine and selected from a finite set during each mode interval.
_Avoid_: Switching plant, hybrid plant

**Switch State**:
The simultaneous binary state of the converter switches.
_Avoid_: Mode, state

**Physical Mode ID**:
The zero-based integer encoding of a converter switch state.
_Avoid_: Mode index, dynamics index

**Dynamics Index**:
The one-based identifier of the dynamics governing a mode interval; it is not necessarily a physical mode ID.
_Avoid_: Physical mode ID, current mode

**Mode Interval**:
A contiguous portion of a switching cycle governed by one set of affine dynamics.
_Avoid_: Mode, time step, dwell interval

**Nominal Periodic Orbit**:
The periodic state evolution induced by repeatedly applying a nominal switching schedule.
_Avoid_: Target periodic orbit, trajectory, equilibrium

**Desired Operating Point**:
The average physical-state objective used to select a nominal periodic orbit; it is not generally a point on that orbit.
_Avoid_: Desired average operating point, orbit anchor, controller target

**Orbit Anchor**:
The point on a nominal periodic orbit at the selected cycle-start boundary; equivalently, a fixed point of the one-cycle map.
_Avoid_: Cycle-boundary state, equilibrium, initial state

**Cycle Input State**:
The plant state at the cycle-start boundary for a particular switching cycle.
_Avoid_: Cycle-boundary state, initial state, orbit anchor

**Orbit Deviation**:
The difference between the actual state and the corresponding state on the nominal periodic orbit; at the cycle-start boundary, it is the cycle input state minus the orbit anchor.
_Avoid_: Cycle-to-cycle error, tracking error, desired-operating-point error

## Switching Schedule

**Switching Cycle**:
One complete traversal of a switching schedule, after which the schedule repeats.
_Avoid_: Simulation step, iteration, signal cycle

**Cycle Boundary**:
A scheduled time separating adjacent mode intervals, including the cycle start and end.
_Avoid_: Switching instant

**Switching Instant**:
An interior cycle boundary at which the physical switch state changes.
_Avoid_: Switching time when it could mean a duration, dwell duration

**Nominal Switching Schedule**:
The ordered mode intervals and cycle-relative boundary times that define one uncorrected switching cycle.
_Avoid_: Reference signal, duty cycle, mode sequence

**Switching-Instant Offset**:
A controller-selected signed displacement of an interior nominal switching instant; a positive value moves that instant later without changing the cycle period.
_Avoid_: Switching-time perturbation, dwell-duration change, time step

**Dwell Duration**:
The elapsed time between two consecutive cycle boundaries.
_Avoid_: Dwell interval, switching time, gap

**Minimum Dwell Duration**:
The lower bound imposed on every dwell duration.
_Avoid_: Minimum dwell time, minimum switching time, time constraint

**Cycle Period**:
The elapsed time from the cycle-start boundary to the cycle-end boundary.
_Avoid_: Horizon, maximum period

## Controller

**One-Cycle Linear Model**:
A local discrete model relating one cycle-start orbit deviation to the next through switching-instant offsets.
_Avoid_: Plant model, prediction model

**Proportional Switching-Time Controller**:
A static state-feedback law that maps the cycle-start orbit deviation linearly to switching-instant offsets.
_Avoid_: P controller, PID, proportional gain

**Dwell-Time Conditioning**:
Uniform contraction of a switching-instant-offset vector until all resulting dwell durations satisfy the minimum dwell duration.
_Avoid_: Saturation, clipping, dwell-time control
