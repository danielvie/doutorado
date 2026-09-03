# Manuscript description

Status: descriptive summary
Source of truth: `latex/article.tex`, `CONTEXT.md`, `GOAL.md`
Read when: understanding what the article currently contains

## Topic

The manuscript studies cycle-to-cycle switching-time feedback for a switched-affine plant that follows a prescribed, fixed-period sequence of modes. The controller moves only the interior switching instants. The mode order, number of intervals, cycle boundaries, and period remain fixed.

The target is a reference periodic trajectory and its selected cycle anchor, not a static equilibrium.

## Current article organization

### Introduction

The Introduction uses four paragraphs to narrow from power-converter constraints and switched-affine periodic operation to fixed-period switching-time control and minimum-dwell feasibility. It distinguishes state-dependent mode selection, online timing optimization, and static cycle-to-cycle timing feedback before presenting Patino and Marcolino as the closest foundations. The closed-form specialization of direction-preserving scaling to the adjacent dwell inequalities and the maximal invariant Raw-Action Admissible Region are the central results. The one-cycle derivation, numerical checks, and converter simulation support those results; the LQR laws are comparison controllers rather than a new synthesis contribution.

### Fixed-period one-cycle model

This section defines the switched-affine plant, fixed mode sequence, nominal schedule, cycle anchor, cycle-start error, and independent interior switching-instant offsets. It maps offsets to dwell changes with a difference matrix. It then derives exact affine propagation with an augmented constant state, expands the ordered product to first order, projects back to physical state, and obtains the one-cycle state and timing Jacobians.

The final timing Jacobian contains the propagated jump between adjacent affine vector fields. The section also shows the common-state-matrix switched-actuator model as a special case.

### Solver-free dwell-time conditioning

A static feedback law produces a raw switching-instant offset. The conditioner scales the complete vector by the largest scalar in the interval from zero to one that satisfies every minimum dwell constraint. The section proves feasibility, maximality, fixed-period preservation, direction preservation, and the linear scan cost.

For the linearized model, offline preimage iteration constructs the maximal subset of the Raw-Action Admissible Region that is positively invariant under the raw closed-loop matrix. If that matrix is Schur, trajectories starting in the set remain raw-action feasible and converge. The nonlinear statement is limited to a local neighborhood where conditioning is inactive.

### Converter case study

The case study uses a three-cell multilevel DC-DC converter benchmark associated with Patino et al. It gives the mode-dependent affine equations, schedule, cycle anchor, normalization, and LQR parameters. Rounded published schedule data are reconciled once so exact propagation closes at the reported anchor.

The study checks the analytical Jacobians against central finite differences, checks second-order residual scaling, computes and validates the invariant raw-action region, and simulates conditioned aggressive LQR, unconditioned conservative LQR, and open loop with exact interval propagation.

### Discussion and conclusion

The final sections state what the conditioner can and cannot do, distinguish the present result from the prior cycle model and LQR, and list the simulation, hardware, timing, uncertainty, and nonlinear-stability limitations.

## Main mathematical objects

- `Phi`: nominal cycle state matrix.
- `Gamma_tau`: sensitivity of the next cycle-start state to the independent switching-instant offsets.
- `K`: static feedback gain.
- `Acl`: full raw-feedback one-cycle matrix.
- `beta`: dwell-conditioning factor.
- `C`: Raw-Action Admissible Region.
- `C_infinity`: maximal positively invariant subset of `C` under `Acl`.

## Evidence categories

The manuscript contains four kinds of statements:

1. analytical derivations and propositions;
2. numerical verification against exact propagation and finite differences;
3. exact switched-affine simulations with state-dependent timing feedback;
4. explicit limitations and unverified implementation questions.

These categories should remain distinct during rewriting.
