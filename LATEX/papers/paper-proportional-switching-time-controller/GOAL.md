# Goal

Present solver-free dwell-time conditioning for fixed-period cycle-to-cycle switching-time feedback, with a common quadratic Lyapunov certificate for the conditioned linearized matrix family. The main stability result covers every conditioning factor in `[0, 1]`, including state-dependent sequences. The exact nonlinear stability claim remains local.

## Mental model

A switched-affine plant follows a fixed mode sequence and period. The exact one-cycle map is linearized in the `N - 1` independent interior switching-instant offsets. The difference matrix maps these offsets to zero-sum dwell changes. A static feedback law requests a Raw Switching-Instant Offset, and the conditioner applies its largest feasible scalar multiple. An `O(N)` scan enforces all minimum dwell durations without an online solver.

Uniform scaling puts the Conditioned Linearized Matrix Family on the segment joining the Nominal Cycle Matrix and Raw Closed-Loop Matrix. An offline SDP seeks one positive-definite matrix with strict Lyapunov decrease at both endpoints. An analytical endpoint-to-interval argument then proves uniform exponential stability of the linearized model for every sequence of Conditioning Factors. The certificate is sufficient, not necessary, and requires both endpoints to be Schur.

The three-cell multilevel DC–DC converter benchmark uses Patino et al.'s nominal nine-interval sequence and cycle anchor. Reconciliation of the rounded schedule preserves the `286 µs` period, reported anchor, and `22 µs` nominal-design dwell bound. This benchmark already converges in open loop. Feedback accelerates convergence while the conditioner enforces a separate assumed `3 µs` applied-schedule bound.

The Maximal Invariant Raw-Action Admissible Region is supporting evidence about where conditioning stays inactive in the linearized model, not the main stability result.

## Success criteria

- The manuscript proceeds through problem formulation and modeling, dwell-time conditioning, Lyapunov stability and convex optimization, and the converter application, followed by discussion and conclusion.
- Preserve the Introduction verbatim during this rewrite. Its contribution summary and section roadmap await the author's later revision.
- Distinguish Patino's mode-dependent switching sensitivity and Marcolino's fixed-period switched-actuator model/LQR as published foundations.
- Derive the exact augmented cycle product, its first-order dwell expansion, nominal cancellation, physical projection, and conversion through `δd = D δτ`, using consistent notation.
- Prove feasibility, maximality, period preservation, and direction preservation of the solver-free conditioner.
- Prove the common-P endpoint-to-interval theorem through the Schur complement and convexity of an inverse-free block matrix, retaining the positive decrease margin, uniform exponential bound, and applicability to state-dependent conditioning.
- Present the fixed-gain SDP used by `studies/lyapunov/analysis.jl`, including trace normalization, positive-definiteness floor, and post-solve eigenvalue checks. Export publication values from full-precision evidence, never from rounded tutorial text.
- Separate the linearized theorem, local exact nonlinear stability, and large-error simulation evidence.
- Validate the analytical one-cycle Jacobians and second-order residual decay against exact propagation.
- Compare conditioned aggressive LQR, conservative LQR, and open loop from `[7.5143, 20.8211, 0.0314]^T` without changing the established benchmark or gains.
- Overlay densely sampled continuous-time 3D physical-state trajectories for conditioned feedback and open loop on the same axes over the same horizon, together with the reference periodic trajectory.
- Show long-run open-loop physical states at cycle starts against logarithmic time. In the long-horizon 3D view, retain the dense early transient and represent later cycles by selected actual cycle-start states, with the reference trajectory drawn once and the final cycle overlaid. Clearly distinguish these phase-aligned samples from continuous-time waveforms, averages, and the reference anchor.
- Report error-threshold crossings, conditioning factors, and raw/applied dwell durations alongside the numerical Lyapunov certificate.
- Keep detailed invariant-region analysis in an appendix, retain its reproducible evidence, and give it no global nonlinear interpretation.
- Aim for 8–10 pages, with at most four main-text figures and two tables.

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
