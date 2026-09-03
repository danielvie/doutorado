# Goal

Present a solver-free dwell-time conditioning and certification layer for fixed-period cycle-to-cycle switching-time feedback. The central contribution is the closed-form specialization of direction-preserving command scaling to adjacent dwell inequalities, together with the maximal invariant subset of the Raw-Action Admissible Region for the linearized raw closed loop. The mode-dependent switched-affine one-cycle derivation and its direct validation remain enabling technical contributions.

## Mental model

The case study uses a three-cell multilevel DC–DC converter benchmark whose nominal nine-mode sequence, switching schedule, and cycle anchor were reported by Patino et al. Because the published values are rounded, the nominal dwell durations are minimally adjusted while preserving the `286 µs` period, reported cycle anchor, and `22 µs` nominal-design dwell bound so exact switched-affine propagation closes the cycle to machine precision.

The exact one-cycle map is linearized in the `N - 1` independent interior switching-instant offsets. The difference matrix maps these offsets to `N` zero-sum dwell changes. This model recovers Patino's established vector-field-jump sensitivity, generalizes Marcolino's common-matrix switched-actuator model to mode-dependent affine dynamics, and is validated directly against exact propagation.

A static controller first requests a Raw Switching-Instant Offset. The dwell-time conditioner multiplies the complete raw vector by the largest Conditioning Factor in `[0, 1]` that enforces every minimum dwell duration. The resulting Applied Switching-Instant Offset preserves the raw direction and fixed period and requires only an `O(N)` scan, not an online solver. Offline polyhedral preimage iteration finds the maximal subset of the Raw-Action Admissible Region that remains inside that region under the Raw Closed-Loop Matrix. Within this set, conditioning stays inactive and Schur stability gives convergence for the linearized raw closed loop.

## Success criteria

- The primary contribution is the maximal direction-preserving dwell-time conditioner and the invariant raw-action feasibility certificate, without first-ever or global claims.
- Patino's mode-dependent switching sensitivity and Marcolino's fixed-period switched-actuator model/LQR are distinguished explicitly as published prior foundations.
- Independent timing coordinates define the difference matrix `D` and state `δd = D δτ`.
- The one-cycle derivation explicitly shows the exact augmented product, single-interval exponential expansion, ordered-product expansion, nominal cancellation, discarded mixed terms, physical-state projection, and conversion from dwell changes to switching-instant offsets.
- The Raw-Action Admissible Region, maximal Conditioning Factor, Applied Switching-Instant Offset, feasibility/maximality proof, and solver-free `O(N)` implementation are explicit.
- The maximal invariant subset of the Raw-Action Admissible Region certifies repeated dwell feasibility and convergence under the Schur Raw Closed-Loop Matrix.
- Exact nonlinear local stability is stated only near the cycle anchor, where strict nominal dwell margin makes conditioning inactive.
- The analytical one-cycle model agrees with central finite differences, and residuals show second-order decay.
- The exact nonlinear `100`-cycle study starts from `[7.5143, 20.8211, 0.0314]^T` and compares conditioned aggressive LQR (`R = 0.001I`), unconditioned conservative LQR (`R = 0.1I`), and open loop.
- The study reports a 7-facet, 10-vertex invariant Raw-Action Admissible Region with physical-error volume `4.5410 V²·A`; the large-error trajectory starts outside it and first enters at cycle `3`.
- The study reports three conditioned cycles, minimum `β = 0.293978`, raw/applied minimum dwell `-43.045/3 µs`, raw/applied maximum offset `65.217/19.172 µs`, threshold cycles `6/20`, and all three spectral radii.
- The paper contains at most four figures and two tables and remains within 8–10 pages.

## Boundaries

### Non-goals

- A new reference-trajectory optimization method.
- A new LQR, robust-control, or model-predictive-control synthesis.
- A first or general direction-preserving command-scaling method.
- A first switching-sensitivity, one-cycle-model, or fixed-period timing-coordinate claim.
- Global stabilization of the nonlinear switched-affine plant.
- Reproducing the earlier unpublished offline trajectory-optimization procedure.

### Constraints

- The nominal mode sequence and cycle period are fixed.
- The cycle anchor is a fixed point of the nominal one-cycle map.
- Control inputs move only the independent interior switching instants.
- Patino's `22 µs` bound is a nominal benchmark-design constraint; controller-applied schedules use a separate assumed `3 µs` minimum dwell duration.
- The maximal invariant region is computed offline with MPT3 and does not change online execution.
- Claims about the exact nonlinear plant remain local to the reference periodic trajectory.

### Accepted limitations

- Validation is simulation-based rather than experimental.
- The approach assumes the cycle-start state and plant parameters are available.
- The invariant-region certificate applies to the linearized raw closed loop, not to conditioned trajectories outside the region or to the exact nonlinear map over the complete polyhedron.
- The `3 µs` bound is not hardware-calibrated; timer quantization, delays, dead time, and implementation margin are absent.
