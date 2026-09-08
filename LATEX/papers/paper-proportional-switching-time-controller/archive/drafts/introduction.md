# Introduction

<!--
Conceptual funnel (working guide, not headings):

  1  Power converters as periodic switched systems ........... P1
  2  Constrained switched control ........................... P2
  3  Cycle-to-cycle switching-time feedback ................. P2
  4  Minimum dwell-time constraints ......................... P3
  5  Contribution ........................................... P4
-->


<!--
OK
-->
Power convertes set the voltage and current by switching ON and OFF in a repeating pattern. In this study this pattern is understood as a fixed sequence of affine modes repeated with a fixed period. This produces a periodic trajectory rather than a equilibrium point, so the control objective in this work is to direct a selected point of that trajectory, the cycle anchor, so the system enters the desired limit cycle start. The only actuator is timing. The controller shifts the interior switching instants by adding delays or antecipating the switching instant, and the hardware that executes the schedule imposes a minimum duration of every dwell it creates.


<!--
NOK
-->
Timing actions of this kind have been computed by online optimization. Patiño, Riedinger, and Ruiz derived the sensitivity of a cyclic switched system to its switching instants, where the sensitivity carries the jump between the affine vector fields at the displaced instant, and used it inside a predictive controller [[patino2010]]. Marcolino, Galvão, and Kienitz fixed the period, wrote the dwell limits as coupled linear inequalities in the switching instants, and enforced them in a dwell-constrained predictive controller for an LTI plant driven by switched actuator levels [[marcolino2021]]. Both enforce the constraints directly and both pay for a solver in the switching interval. That cost is a standing concern in converter control, and a large literature works to reduce it: Saeed et al. shrink the decision space with a Laguerre parameterization [[saeed2022laguerre]], Yang et al. build a solver specialized to fixed-frequency operation [[yang2022fixed]], others prune or approximate the candidate set [[augustine2023mpc]], [[switchedOptimalDwell2025]], and Stellato et al. combine a horizon of one or two with an offline approximate tail cost and fixed-point exhaustive evaluation to obtain deterministic FPGA execution times [[stellato2017fcsMpc]]. Static feedback takes the other route. At the start of each cycle it maps the measured error to a correction applied to the interior switching instants of that same cycle, and the next cycle-start state follows. Synthesis and any stability analysis move offline, leaving a gain multiplication online. The actuator is what separates this from neighboring work: the controller does not decide which mode is active, as in state-dependent mode selection [[egidio2022rank]], [[russo2026dwell]], does not regulate a measured switching period through a hysteresis band [[repecho2017switchingFrequency]], and does not rebuild the cycle with a solver at every step.

<!--
NOK
-->
Removing the solver does not remove the limits. Each interior switching instant is the boundary between two intervals, so displacing it lengthens one dwell and shortens its neighbor, and the dwell constraints are coupled across the offset vector rather than separable in it. A static law knows nothing of this and can request a schedule the converter cannot execute. Handling the request one coordinate at a time is the obvious repair and the wrong one: saturating offsets individually changes the direction the law asked for, and in the standalone LQR comparison reported by Marcolino et al. it also moves the final switching instant, with a response that diverges [[marcolino2021]]. Projecting the request onto the feasible set keeps it feasible and closest in norm, but it is a quadratic program, which returns the solver, and its solution leaves the ray the law selected. The question is therefore how to make a raw offset admissible without online optimization, while preserving both the direction the feedback law requested and the fixed period.

<!--
NOK
-->
We answer it without touching the feedback law. Given the raw offset vector, we apply the largest scalar multiple of it that keeps every dwell at or above the minimum. Scaling the complete vector by one number leaves it on the same ray, keeps the dwell changes zero-sum so both cycle boundaries hold, preserves the mode order, and is found by a single pass over the $N$ dwell changes, so the online cost is $O(N)$ and no solver runs. In the linearized cycle model the conditioned closed loop is $A(\beta)=(1-\beta)\Phi+\beta A_{\mathrm{cl}}$, a segment between the nominal cycle matrix and the raw closed-loop matrix, so one quadratic Lyapunov function that contracts both endpoints certifies every conditioning sequence the plant can generate. These two results are the contribution. The rest supports them: a fixed-period one-cycle model for mode-dependent affine dynamics, which recovers the published sensitivity structure and contains the common-state-matrix case as a specialization, Jacobians checked against central finite differences, and an exact nonlinear simulation of a nine-interval converter benchmark. The LQR laws are comparison controllers, not a new synthesis method. The certificate covers the linearized family; the nonlinear guarantee is local to the anchor, where the nominal dwell margin leaves conditioning inactive; and the converter study is simulation rather than hardware validation. Section 2 derives the cycle model, Section 3 builds the conditioner and its certificate, and Section 4 reports the converter study.
