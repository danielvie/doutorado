# Manuscript description

Status: descriptive summary
Source of truth: `latex/main.tex`, `CONTEXT.md`, `GOAL.md`
Read when: understanding what the article currently contains

## Topic and scope

The paper studies cycle-to-cycle switching-time feedback for a switched-affine plant with a prescribed mode sequence and period. The controller moves only interior switching instants. A scalar conditioner applies the largest feasible multiple of the raw action while respecting every minimum dwell duration.

The main stability result is a common quadratic Lyapunov certificate for the conditioned linearized matrix segment. The invariant raw-action region is supporting appendix material. Large-error nonlinear trajectories are simulation evidence. The manuscript no longer presents a separate local nonlinear stability result.

## Current organization

1. **Introduction.** Preserved verbatim at the author's request. Its old contribution summary and roadmap still describe invariant-region-centered stability and await revision. Do not use them to override the rewritten theorem or `GOAL.md`.
2. **Problem formulation and one-cycle model.** Defines the reference periodic trajectory, cycle anchor `bar x(0)`, error, and independent timing coordinates. Follows `linearization_v2_augmented.tex`: exact augmented propagation and terminal error, single-exponential expansion, product of expanded factors, explicit product expansion, nominal cancellation, explicit terminal-error sum, then sensitivity collection and compact augmented matrices. A separate subsection extracts the physical model and converts dwell changes to independent switching-instant offsets. Introduces the fixed raw feedback gain. The derivation uses calligraphic `X`, barred nominal states, and unadorned augmented quantities `e(t)`, `Phi`, and `Gamma`, with dimensions stated. After projection, `Phi_x` is the physical transition, `Gamma_tau` is the physical switching-instant sensitivity, and `e_k` is the physical cycle-start error. No starred anchor notation remains in the manuscript.
3. **Solver-free dwell-time conditioning.** Defines the Raw-Action Admissible Region and maximal factor. Proves feasibility, maximality, direction and period preservation, and linear scan cost. Gives the cycle-start execution sequence.
4. **Lyapunov stability and convex optimization.** Defines physical-coordinate endpoints `A0 = Phi_x`, `A1 = Acl`, and the matrix segment acting on the cycle-start error `e`. Uses the Schur complement and convex interpolation of negative-definite block matrices with diagonal blocks `-P` and `-P^{-1}` to prove the endpoint-to-interval result and uniform exponential stability for arbitrary conditioning sequences. Concludes with a prose explanation of uniform Lyapunov decrease on the compact conditioning interval, without a separate scalar decrease equation or eigenvalue-based contraction calculation. Separates this fixed-`P` proof from the inverse-free fixed-gain SDP. Presents direct numerical checks and conservatism, then closes with a brief statement separating the linearized guarantee from nonlinear simulation evidence. The former subsection “What follows for the exact plant” has been removed.
5. **Application to a three-cell converter.** Describes the benchmark and introduces state normalization for LQR design, numerical certification, and error reporting. Hatted endpoint matrices and `P_n` distinguish the saved normalized certificate from the physical matrices in the theorem; an explicit congruence connects the certificates without changing the numerical study. Verifies the linearization and overlays dense controlled/open-loop paths in one 3D plot, beside a long-horizon cycle-start error history. Error and dwell histories quantify the early transient. A separate figure compares continuous-time voltages and current with the reference periodic waveforms. The long-horizon discussion derives the exact fixed-schedule open-loop error relation and uses it to establish eventual open-loop convergence.
6. **Discussion and conclusion.** Distinguish prior foundations from the conditioner/certificate contribution, and state numerical and implementation limitations.
7. **Appendix A.** Explains how lowering a fixed factor expands the dwell-feasible region by `1/beta`, with a four-panel comparison for beta 0.25, 0.5, and 1. One 3D view and three projections overlay the state-dependent simulation. A short supporting subsection checks that each feasible region maps into itself under its corresponding fixed-factor linearized dynamics, then invokes the common-P result for convergence. The raw-only maximal-invariant-set construction and proposition are no longer presented. These checks have no global nonlinear interpretation. Entry classification uses the full three-dimensional inequalities.

## Evidence categories

- Analytical derivations and conditional stability theorem.
- Floating-point model and certificate checks, not interval-arithmetic certification.
- Exact switched-affine simulations with state-dependent timing feedback.
- Exact open-loop convergence under the fixed nominal schedule because its cycle error map is linear.

The benchmark is already open-loop stable. Feedback accelerates convergence while maintaining feasible dwell durations; it does not rescue an unstable open-loop benchmark.
