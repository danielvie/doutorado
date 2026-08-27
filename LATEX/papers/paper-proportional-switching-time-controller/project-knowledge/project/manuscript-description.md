# Manuscript description

Status: descriptive summary
Source of truth: `article.tex`, `CONTEXT.md`, `GOAL.md`
Read when: understanding what the article currently contains

## Topic

The manuscript studies cycle-to-cycle switching-time feedback for a switched-affine plant that follows a prescribed, fixed-period sequence of modes. The controller moves only the interior switching instants. The mode order, number of intervals, cycle boundaries, and period remain fixed.

The target is a reference periodic trajectory and its selected cycle anchor, not a static equilibrium.

## Current article organization

### Introduction

The Introduction moves from converter timing and computation constraints to the fixed-period control setting, then discusses Patiño and Marcolino as the closest foundations. It presents dwell conditioning and the associated common-quadratic certificate as the central results. The one-cycle derivation, LQR design, numerical checks, and converter simulation support those results.

### Fixed-period one-cycle model

This section defines the switched-affine plant, fixed mode sequence, nominal schedule, cycle anchor, cycle-start error, and independent interior switching-instant offsets. It maps offsets to dwell changes with a difference matrix. It then derives exact affine propagation with an augmented constant state, expands the ordered product to first order, projects back to physical state, and obtains the one-cycle state and timing Jacobians.

The final timing Jacobian contains the propagated jump between adjacent affine vector fields. The section also shows the common-state-matrix switched-actuator model as a special case.

### Solver-free dwell-time conditioning

A static feedback law produces a raw switching-instant offset. The conditioner scales the complete vector by the largest scalar in the interval from zero to one that satisfies every minimum dwell constraint. The section proves feasibility, maximality, fixed-period preservation, direction preservation, and the linear scan cost.

For the linearized model, the conditioned matrix lies on the segment between the nominal cycle matrix and the raw closed-loop matrix. A common quadratic Lyapunov function for the endpoints gives a contraction bound for every conditioning-factor sequence. The nonlinear statement is limited to a local neighborhood where conditioning is inactive.

### Converter case study

The case study uses a three-cell multilevel DC-DC converter benchmark associated with Patiño et al. It gives the mode-dependent affine equations, schedule, cycle anchor, normalization, and LQR parameters. Rounded published schedule data are reconciled once so exact propagation closes at the reported anchor.

The study checks the analytical Jacobians against central finite differences, checks second-order residual scaling, computes the common-P certificate, and simulates conditioned aggressive LQR, unconditioned conservative LQR, and open loop with exact interval propagation.

### Discussion and conclusion

The final sections state what the conditioner can and cannot do, distinguish the present result from the prior cycle model and LQR, and list the simulation, hardware, timing, uncertainty, and nonlinear-stability limitations.

## Main mathematical objects

- `Phi`: nominal cycle state matrix.
- `Gamma_tau`: sensitivity of the next cycle-start state to the independent switching-instant offsets.
- `K`: static feedback gain.
- `Acl`: full raw-feedback one-cycle matrix.
- `beta`: dwell-conditioning factor.
- `A(beta)`: conditioned linearized one-cycle matrix.
- `P`: common quadratic Lyapunov matrix obtained offline for the case study.

## Evidence categories

The manuscript contains four kinds of statements:

1. analytical derivations and propositions;
2. numerical verification against exact propagation and finite differences;
3. exact switched-affine simulations with state-dependent timing feedback;
4. explicit limitations and unverified implementation questions.

These categories should remain distinct during rewriting.
