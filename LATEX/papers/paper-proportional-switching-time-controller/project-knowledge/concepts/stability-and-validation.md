# Stability and validation

Status: explanatory summary
Source of truth: `article.tex`, Sections 3 and 4; `GOAL.md`; `results/metrics.csv`
Read when: distinguishing proof, numerical verification, and simulation evidence

## Analytical statements

The manuscript proves that the scalar dwell conditioner returns the largest feasible factor in the interval from zero to one for a given raw timing direction. It also proves that the applied action preserves the cycle period and raw direction.

A second proposition states that if the nominal cycle matrix and the full raw-feedback matrix contract in one common quadratic norm, then every conditioned matrix on their segment contracts in that norm for any factor sequence.

These are statements about the timing constraints and the linearized cycle model.

## Local nonlinear statement

Near the cycle anchor, the raw feedback action is zero at zero error. A strict nominal dwell margin therefore creates a neighborhood in which conditioning is inactive. If the exact cycle map is differentiable there and the raw closed-loop linearization is Schur, the anchor and associated phase-locked periodic trajectory are locally exponentially stable.

The common-quadratic segment result does not bound the nonlinear remainder outside that local neighborhood.

## Numerical verification

The paper checks the analytical state and timing Jacobians against central finite differences of exact cycle propagation. It also scales a combined state/timing perturbation and fits the residual slope. A slope near two is evidence that the first-order model's error is second order in the perturbation amplitude.

These checks validate the implementation around the nominal anchor. They are not a uniform error bound over every state or timing action.

## Simulation evidence

The large-error study propagates each interval with exact augmented matrix exponentials. It compares conditioned aggressive LQR, unconditioned conservative LQR, and open loop for the specified converter benchmark and initial state.

The study shows whether the selected raw action becomes infeasible, whether conditioning restores admissible dwells, and how the three selected responses behave. It does not establish global nonlinear stability, robustness to parameter uncertainty, or hardware feasibility.

## Missing evidence

The current paper does not establish:

- timer quantization tolerance;
- delay or dead-time tolerance;
- state-estimation behavior;
- plant-parameter uncertainty bounds;
- hardware execution time;
- hardware or hardware-in-the-loop validation;
- a global nonlinear region of attraction.
