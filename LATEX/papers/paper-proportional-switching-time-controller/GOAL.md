# Goal

Present solver-free dwell-time conditioning for fixed-period cycle-to-cycle switching-time feedback, with offline joint gain and common quadratic Lyapunov synthesis for the conditioned linearized matrix family. The main stability result covers every conditioning factor in `[0, 1]`, including state-dependent sequences. The nonlinear controlled response is evaluated by simulation, without a separate local nonlinear stability result in the manuscript.

## Mental model

A switched-affine plant follows a fixed mode sequence and period. The exact one-cycle map is linearized in the `N - 1` independent interior switching-instant offsets. The difference matrix maps these offsets to zero-sum dwell changes. A static feedback law requests a Raw Switching-Instant Offset, and the conditioner applies its largest feasible scalar multiple. An `O(N)` scan enforces all minimum dwell durations without an online solver.

Uniform scaling puts the Conditioned Linearized Matrix Family on the segment joining the Nominal Cycle Matrix and Raw Closed-Loop Matrix. Offline bisection over a fixed-rate SDP computes a feedback gain and one positive-definite matrix that certifies contraction at both endpoints. An analytical endpoint-to-interval argument then proves uniform exponential stability of the linearized model for every sequence of Conditioning Factors. The certificate is sufficient, not necessary, and requires both endpoints to be Schur.

The three-cell multilevel DC–DC converter benchmark uses Patino et al.'s nominal nine-interval sequence and cycle anchor. Reconciliation of the rounded schedule preserves the `286 µs` period, reported anchor, and `22 µs` nominal-design dwell bound. This benchmark already converges in open loop. Feedback accelerates convergence while the conditioner enforces a separate assumed `3 µs` applied-schedule bound.

The supporting appendix should show how reducing a fixed conditioning factor enlarges the dwell-feasible region. Compare factors 0.25, 0.5, and 1 in one 3D view and three coordinate-plane projections. Distinguish feasibility from stability: the appendix uses the original LQR baseline gain, whose saved checks establish invariance for these fixed-factor regions under their respective linearized maps. The main Common-P result is independent of this example. This is not a growing nonlinear region of attraction. Raw-action invariance at factor one remains supporting evidence, not the appendix figure's main message or the paper's main stability result.

## Success criteria

- The manuscript proceeds through problem formulation and modeling, dwell-time conditioning, Lyapunov stability and convex optimization, and the converter application, followed by discussion and conclusion.
- Preserve the Introduction verbatim during this rewrite. Its contribution summary and section roadmap await the author's later revision.
- Distinguish Patino's mode-dependent switching sensitivity and Marcolino's fixed-period switched-actuator model/LQR as published foundations.
- Follow `research-material/working-notes/linearization/linearization_v2_augmented.tex` closely in Section 2: augmented dynamics, interval and cycle propagation, nominal transitions, exact terminal error, single-exponential expansion, product of expanded factors, explicit product expansion, nominal cancellation, explicit terminal-error sum, then sensitivity collection and the compact augmented model. Introduce physical projection and conversion through `δd = D δτ` only afterward. Use the reference's calligraphic state and barred nominal trajectory, not starred anchor notation. Use unadorned `e(t)`, `Phi`, and `Gamma` for augmented quantities, with their dimensions stated. After projection, use `Phi_x` for the physical nominal cycle matrix and `Gamma_tau` for the switching-instant sensitivity; `e_k`, or `e` without a cycle index in the later analysis, denotes the physical error. Define first order jointly in initial error and duration changes, and connect the reference's duration notation to the paper's dwell notation.
- Prove feasibility, maximality, period preservation, and direction preservation of the solver-free conditioner.
- Prove the common-P endpoint-to-interval theorem through the Schur complement and convexity of the negative-definite block form with diagonal blocks `-P` and `-P^{-1}`, retaining the positive decrease margin and applicability to state-dependent conditioning. Conclude uniform exponential stability from the common quadratic Lyapunov criterion and continuity on the compact conditioning interval. Keep the conclusion in prose, without a separate scalar decrease equation, margin-shifting argument, or eigenvalue-based contraction calculation.
- State the stability theorem and proof in physical error coordinates, with `A0 = Phi_x`, `A1 = Acl`, and `V(e) = e'Pe`. Introduce state normalization only in the converter application for gain design, numerical conditioning, and error reporting. Distinguish the normalized numerical certificate from the physical-coordinate Lyapunov matrix and give the congruence relating them.
- Present the joint gain and certificate SDP used by `studies/s2-kawa-synthesis`, including the substitutions `X=P^{-1}`, `Y=KX`, trace normalization, positive-definiteness floor, and post-solve checks. Explain why the open-loop endpoint limits the common rate and the objective does not select a unique gain. Export values from saved full-precision evidence, and use the same gain for the certificate and the simulated comparison.
- Distinguish the linearized stability theorem from the large-error nonlinear simulation evidence with a concise scope statement. Do not add a separate local nonlinear stability subsection or present that result as a contribution. Retain the exact fixed-schedule open-loop error relation in the application's long-horizon discussion.
- Validate the analytical one-cycle Jacobians and second-order residual decay against exact propagation.
- Compare Common-P, conditioned LQR, and MPC-5 over 100 exact cycles at 1x, 2x, and 3x the original displacement from the cycle anchor. Report sustained threshold cycles, applied cost, and matched full-controller MATLAB timings. Keep the benchmark and both baseline controllers unchanged.
- Show the 1x continuous-time trajectories and physical-state histories with the periodic reference. Preserve switching ripple and each response's own interval sample times. Retain the open-loop relation and saved long-horizon evidence separately.
- Report when scaling is needed in the 1x case and distinguish that observation from a general guarantee. Note the negative initial current in the 2x and 3x cases; they do not validate hardware operation or state safety.
- Report error-threshold crossings, conditioning factors, and raw/applied dwell durations alongside the numerical Lyapunov certificate.
- Export figures at their final manuscript width, with approximately 9–10 pt labels/legends and at least 8 pt tick labels. Keep captions short and explain mechanisms in the body.
- Keep detailed feasible/invariant-region analysis in an appendix, retain its reproducible evidence, and give it no global nonlinear interpretation. Make the figure's main comparison the nested feasible regions for fixed factors 0.25, 0.5, and 1, rather than a region and its one-cycle image. Explain separately which fixed-factor regions have verified linear invariance.
- Include a paper-style explanatory figure showing the adjustable interior instants, the coupled effect on adjacent dwells, and a non-executable raw request. Use current benchmark data and distinguish an illustrative isolated offset from the simulated feedback action.
- Explain the common-P argument with a compact schematic showing both endpoint images and their interpolating segment inside one quadratic sublevel set. Clearly distinguish this illustration from converter data and a nonlinear region of attraction.
- Aim for 15 total PDF pages including appendix and references, with five main-text figures and compact comparison tables. The timing-mechanism figure groups three explanatory panels. Use it for the reference schedule and the trajectory comparisons for the reference periodic trajectory, leaving the standalone reference figure as supporting material and using its main-text slot for the common-P schematic.

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
- Convex optimization designs the gain and certificate offline. Online controller execution uses the fixed gain and closed-form scaling.
- The `22 µs` nominal-design bound and `3 µs` assumed applied-schedule bound have different roles.
- Publication evidence must pair the saved Common-P gain with its own certificate and trajectories. The separately verified Julia port may return a different gain.

### Accepted limitations

- Validation is simulation-based, with measured cycle-start state and known plant parameters assumed.
- The common-P result applies to the conditioned linearized family, not to the exact nonlinear feedback map over its whole state space.
- Failure of the SDP does not establish instability. Including the zero-feedback endpoint prevents this full-interval certificate from covering an unstable open-loop cycle matrix.
- The computed Lyapunov inequalities are floating-point checks, not interval-arithmetic certification.
- The invariant-region certificate describes the linearized raw closed loop, not nonlinear invariance of the complete polyhedron.
- The `3 µs` bound is not hardware-calibrated; timer quantization, delays, dead time, implementation margin, uncertainty, and experiments are absent.



Conclusao

MPC sao melhores mas teem um custo computacional inerente da sua arquitetura
MPC's tend to perform better and can incorporate the constraint of the problem in the modelling 
Esse custo computacional pode inviabilizar o controlador em aplicacoes criticas com tempos de dinamica muito rapidas
Podemos usar um ganho calculado por síntese Common-P e condicionamento de sinal com garantia de estabilidade para o modelo linearizado. Na comparação, o MPC-5 tem menor custo acumulado, mas leva mais tempo por atualização no mesmo computador.