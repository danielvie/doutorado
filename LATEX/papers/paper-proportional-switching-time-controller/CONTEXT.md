# Proportional Switching-Time Control

This context defines the language used to describe cycle-to-cycle stabilization of a switched-affine converter by perturbing its switching instants.

## Plant and trajectory

**Switched-affine plant**:
A continuous-time plant whose state dynamics are affine and selected from a finite set by an operating mode.
_Avoid_: Switching plant, hybrid plant

**Operating mode**:
One member of the finite set of affine plant dynamics active during a dwell interval.
_Avoid_: State, command state

**Mode sequence**:
The ordered operating modes traversed during one switching cycle.
_Avoid_: Control sequence, switching signal

**Target periodic orbit**:
The desired closed state trajectory associated with one repetition of the nominal switching schedule.
_Avoid_: Equilibrium, target point, limit-cycle point

**Desired average operating point**:
The state value about which the target periodic orbit is designed to oscillate; it is not the cycle-boundary target.
_Avoid_: Target state, equilibrium

**Cycle-boundary state**:
The plant state sampled at the fixed phase marking the beginning of each switching cycle.
_Avoid_: Initial state, equilibrium state

**Cycle-to-cycle error**:
The difference between the cycle-boundary state and the corresponding state on the target periodic orbit.
_Avoid_: Tracking error, instantaneous error

## Switching timing

**Switching instant**:
A time within a switching cycle at which the operating mode changes.
_Avoid_: Switching time when it could mean a duration

**Nominal switching schedule**:
The ordered switching instants that generate the target periodic orbit.
_Avoid_: Reference signal, duty cycle

**Switching-time perturbation**:
A signed displacement applied to an internal nominal switching instant and used as the manipulated variable.
_Avoid_: Time step, duty-cycle correction, control signal

**Dwell interval**:
The elapsed time between consecutive switching instants.
_Avoid_: Switching time, gap

**Minimum dwell time**:
The lower bound imposed on every dwell interval.
_Avoid_: Minimum switching time, time constraint

## Controller

**One-cycle linear model**:
A local discrete model relating one cycle-to-cycle error to the next through switching-time perturbations.
_Avoid_: Plant model, prediction model

**Proportional switching-time controller**:
A static state-feedback law that maps the cycle-to-cycle error linearly to switching-time perturbations.
_Avoid_: P controller, PID, proportional gain

**Dwell-time conditioning**:
Uniform contraction of a switching-time perturbation vector until all resulting dwell intervals satisfy the minimum dwell time.
_Avoid_: Saturation, clipping, dwell-time control
