# Manuscript description

Status: descriptive summary
Source of truth: `latex/main.tex`, `CONTEXT.md`, `GOAL.md`
Read when: understanding what the article currently contains

## Topic and scope

The paper studies cycle-to-cycle switching-time feedback for a switched-affine plant with a prescribed mode sequence and period. The controller moves only interior switching instants. A scalar conditioner applies the largest feasible multiple of the raw action while respecting every minimum dwell duration.

The main stability result is a common quadratic Lyapunov certificate for the conditioned linearized matrix segment. The invariant raw-action region is supporting appendix material. Exact nonlinear stability remains local; large-error nonlinear trajectories are simulation evidence.

## Current organization

1. **Introduction.** Preserved verbatim at the author's request. Its old contribution summary and roadmap still describe invariant-region-centered stability and await revision. Do not use them to override the rewritten theorem or `GOAL.md`.
2. **Problem formulation and one-cycle model.** Defines the reference periodic trajectory, cycle anchor, error, and independent timing coordinates. Derives exact augmented propagation, first-order dwell sensitivities, physical projection, and the switching-instant Jacobian. Introduces the fixed raw feedback gain.
3. **Solver-free dwell-time conditioning.** Defines the Raw-Action Admissible Region and maximal factor. Proves feasibility, maximality, direction and period preservation, and linear scan cost. Gives the cycle-start execution sequence.
4. **Lyapunov stability and convex optimization.** Defines normalized endpoints `A0`, `A1`, and the matrix segment. Uses the Schur complement and convex interpolation of inverse-free block matrices to prove the endpoint-to-interval result and uniform exponential bound for arbitrary conditioning sequences. Presents the fixed-gain SDP, direct numerical checks, conservatism, and the local nonlinear boundary. Separately explains why the fixed-schedule open-loop error map is exact.
5. **Application to a three-cell converter.** Describes the benchmark and LQR parameters, verifies the linearization, reports the Julia certificate, and overlays dense controlled/open-loop paths in one 3D plot. Error and dwell histories quantify the transient. The long-horizon figure shows physical states at cycle starts against logarithmic time. Its 3D view retains the dense early transient but uses faded cycle-start points for later cycles, with the reference and final within-cycle trajectory drawn once.
6. **Discussion and conclusion.** Distinguish prior foundations from the conditioner/certificate contribution, and state numerical and implementation limitations.
7. **Appendix A.** Explains how lowering a fixed factor expands the dwell-feasible region by `1/beta`, with a four-panel comparison for beta 0.25, 0.5, and 1. One 3D view and three projections overlay the state-dependent simulation. A short supporting subsection checks that each feasible region maps into itself under its corresponding fixed-factor linearized dynamics, then invokes the common-P result for convergence. The raw-only maximal-invariant-set construction and proposition are no longer presented. These checks have no global nonlinear interpretation. Entry classification uses the full three-dimensional inequalities.

## Evidence categories

- Analytical derivations and conditional stability theorem.
- Floating-point model and certificate checks, not interval-arithmetic certification.
- Exact switched-affine simulations with state-dependent timing feedback.
- Local nonlinear stability near the anchor, where conditioning is inactive.
- Exact open-loop convergence under the fixed nominal schedule because its cycle error map is linear.

The benchmark is already open-loop stable. Feedback accelerates convergence while maintaining feasible dwell durations; it does not rescue an unstable open-loop benchmark.
