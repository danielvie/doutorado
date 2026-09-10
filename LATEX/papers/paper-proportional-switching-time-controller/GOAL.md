# Goal

Present solver-free dwell-time conditioning for fixed-period cycle-to-cycle switching-time feedback, with a common quadratic Lyapunov certificate for the conditioned linearized matrix family. The main stability result covers every conditioning factor in `[0, 1]`, including state-dependent sequences. The nonlinear controlled response is evaluated by simulation, without a separate local nonlinear stability result in the manuscript.

## Mental model

A switched-affine plant follows a fixed mode sequence and period. The exact one-cycle map is linearized in the `N - 1` independent interior switching-instant offsets. The difference matrix maps these offsets to zero-sum dwell changes. A static feedback law requests a Raw Switching-Instant Offset, and the conditioner applies its largest feasible scalar multiple. An `O(N)` scan enforces all minimum dwell durations without an online solver.

Uniform scaling puts the Conditioned Linearized Matrix Family on the segment joining the Nominal Cycle Matrix and Raw Closed-Loop Matrix. An offline SDP seeks one positive-definite matrix with strict Lyapunov decrease at both endpoints. An analytical endpoint-to-interval argument then proves uniform exponential stability of the linearized model for every sequence of Conditioning Factors. The certificate is sufficient, not necessary, and requires both endpoints to be Schur.

The three-cell multilevel DC–DC converter benchmark uses Patino et al.'s nominal nine-interval sequence and cycle anchor. Reconciliation of the rounded schedule preserves the `286 µs` period, reported anchor, and `22 µs` nominal-design dwell bound. This benchmark already converges in open loop. Feedback accelerates convergence while the conditioner enforces a separate assumed `3 µs` applied-schedule bound.

The supporting appendix should show how reducing a fixed conditioning factor enlarges the dwell-feasible region. Compare factors 0.25, 0.5, and 1 in one 3D view and three coordinate-plane projections. Distinguish feasibility from stability: the saved benchmark checks establish invariance for these fixed-factor regions under their respective linearized maps, while the common-P theorem supplies linearized convergence. This is not a growing nonlinear region of attraction. Raw-action invariance at factor one remains supporting evidence, not the appendix figure's main message or the paper's main stability result.

## Success criteria

- The manuscript proceeds through problem formulation and modeling, dwell-time conditioning, Lyapunov stability and convex optimization, and the converter application, followed by discussion and conclusion.
- Preserve the Introduction verbatim during this rewrite. Its contribution summary and section roadmap await the author's later revision.
- Distinguish Patino's mode-dependent switching sensitivity and Marcolino's fixed-period switched-actuator model/LQR as published foundations.
- Follow `research-material/working-notes/linearization/linearization_v2_augmented.tex` closely in Section 2: augmented dynamics, interval and cycle propagation, nominal transitions, exact terminal error, single-exponential expansion, product of expanded factors, explicit product expansion, nominal cancellation, explicit terminal-error sum, then sensitivity collection and the compact augmented model. Introduce physical projection and conversion through `δd = D δτ` only afterward. Use the reference's calligraphic state and barred nominal trajectory, not starred anchor notation. Use unadorned `e(t)`, `Phi`, and `Gamma` for augmented quantities, with their dimensions stated. After projection, use `Phi_x` for the physical nominal cycle matrix and `Gamma_tau` for the switching-instant sensitivity; `e_k`, or `e` without a cycle index in the later analysis, denotes the physical error. Define first order jointly in initial error and duration changes, and connect the reference's duration notation to the paper's dwell notation.
- Prove feasibility, maximality, period preservation, and direction preservation of the solver-free conditioner.
- Prove the common-P endpoint-to-interval theorem through the Schur complement and convexity of the negative-definite block form with diagonal blocks `-P` and `-P^{-1}`, retaining the positive decrease margin and applicability to state-dependent conditioning. Conclude uniform exponential stability from the common quadratic Lyapunov criterion and continuity on the compact conditioning interval. Keep the conclusion in prose, without a separate scalar decrease equation, margin-shifting argument, or eigenvalue-based contraction calculation.
- State the stability theorem and proof in physical error coordinates, with `A0 = Phi_x`, `A1 = Acl`, and `V(e) = e'Pe`. Introduce state normalization only in the converter application for LQR design, numerical conditioning, and error reporting. Distinguish the normalized numerical certificate from the physical-coordinate Lyapunov matrix and give the congruence relating them.
- Present the fixed-gain SDP used by `studies/lyapunov/analysis.jl`, including trace normalization, positive-definiteness floor, and post-solve eigenvalue checks. The implementation and saved certificate remain in normalized coordinates; changing the proof notation does not change the gain, solver inputs, or numerical evidence. Export publication values from full-precision evidence, never from rounded tutorial text.
- Distinguish the linearized stability theorem from the large-error nonlinear simulation evidence with a concise scope statement. Do not add a separate local nonlinear stability subsection or present that result as a contribution. Retain the exact fixed-schedule open-loop error relation in the application's long-horizon discussion.
- Validate the analytical one-cycle Jacobians and second-order residual decay against exact propagation.
- Compare conditioned aggressive LQR, conservative LQR, and open loop from `[7.5143, 20.8211, 0.0314]^T` without changing the established benchmark or gains.
- Overlay densely sampled continuous-time 3D physical-state trajectories for conditioned feedback and open loop on the same axes over the same horizon, together with the reference periodic trajectory.
- Show the three continuous-time physical states against time, comparing conditioned feedback, open loop, and the repeated reference periodic waveform over the same early window. Preserve switching ripple and the distinct sampling times of the two responses; do not replace the reference by its mean or anchor.
- Keep eventual open-loop convergence visible in the long-horizon cycle-start error panel beside the 3D comparison. Retain the saved long-horizon state data and older detailed plot as supporting evidence.
- Align the early closed-loop/open-loop error, conditioning factor, and requested/applied minimum dwell histories. Mark the cycles requiring scaling. Treat its eventual inactivity as an observation of this simulation, not a general guarantee. Keep the conservative tuning comparison in the table and text.
- Report error-threshold crossings, conditioning factors, and raw/applied dwell durations alongside the numerical Lyapunov certificate.
- Export figures at their final manuscript width, with approximately 9–10 pt labels/legends and at least 8 pt tick labels. Keep captions short and explain mechanisms in the body.
- Keep detailed feasible/invariant-region analysis in an appendix, retain its reproducible evidence, and give it no global nonlinear interpretation. Make the figure's main comparison the nested feasible regions for fixed factors 0.25, 0.5, and 1, rather than a region and its one-cycle image. Explain separately which fixed-factor regions have verified linear invariance.
- Include a paper-style explanatory figure showing the adjustable interior instants, the coupled effect on adjacent dwells, and a non-executable raw request. Use current benchmark data and distinguish an illustrative isolated offset from the simulated feedback action.
- Explain the common-P argument with a compact schematic showing both endpoint images and their interpolating segment inside one quadratic sublevel set. Clearly distinguish this illustration from converter data and a nonlinear region of attraction.
- Aim for 8–10 pages, with five main-text figures and two tables. The timing-mechanism figure groups three explanatory panels. Use it for the reference schedule and the trajectory comparisons for the reference periodic trajectory, leaving the standalone reference figure as supporting material and using its main-text slot for the common-P schematic.

## Boundaries

### Non-goals

- A new reference-trajectory optimization method or reconstruction of the earlier unpublished optimization procedure.
- A new LQR, robust-control, or model-predictive-control synthesis.
- A first or general direction-preserving command-scaling, switching-sensitivity, or one-cycle-model claim.
- Global stabilization of the nonlinear timing-feedback plant.
- Claiming that this benchmark needs feedback to converge in open loop.

### Constraints

- The nominal mode sequence and cycle period are fixed; only interior switching instants move.
- The cycle anchor is a fixed point of the nominal one-cycle map.
- Convex optimization is offline certificate computation for a fixed gain, not part of online controller execution.
- The `22 µs` nominal-design bound and `3 µs` assumed applied-schedule bound have different roles.
- Publication exports must check that the study's certificate corresponds to the current article model and aggressive gain.

### Accepted limitations

- Validation is simulation-based, with measured cycle-start state and known plant parameters assumed.
- The common-P result applies to the conditioned linearized family, not to the exact nonlinear feedback map over its whole state space.
- Failure of the SDP does not establish instability. Including the zero-feedback endpoint prevents this full-interval certificate from covering an unstable open-loop cycle matrix.
- The computed Lyapunov inequalities are floating-point checks, not interval-arithmetic certification.
- The invariant-region certificate describes the linearized raw closed loop, not nonlinear invariance of the complete polyhedron.
- The `3 µs` bound is not hardware-calibrated; timer quantization, delays, dead time, implementation margin, uncertainty, and experiments are absent.
