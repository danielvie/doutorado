# Reference-usage review

## Scope and method

This review compares the current manuscript source, `article.tex`, with the records in `references.bib`. A reference is counted as **used** when its BibTeX key appears in a citation command in `article.tex`. A record that appears only in `references.bib`, the research notes, or an earlier handoff is counted as **unused in the current article**.

The review also considers the five numbered handoff files and the project scope in `GOAL.md`, `CONTEXT.md`, and `research/novelty-review.md`.

## Results

- Bibliography records in `references.bib`: **30**
- Distinct records cited in `article.tex`: **14**
- Individual cited-key occurrences: **20**
- Records currently uncited: **16**

The current source does not contain a `\\nocite{...}` command. Therefore, a normal BibTeX build should include only the cited records in the article's reference list, subject to the bibliography style.

## References used in the article

| BibTeX key | Short title | Citation occurrences | Role in the current text |
|---|---|---:|---|
| `patino2010` | A Predictive Control Approach for DC--DC Power Converters and Cyclic Switched Systems | 4 | Establishes the earlier mode-dependent switching-instant sensitivity and provides the three-cell converter benchmark used in the case study. |
| `marcolino2021` | Predictive Control of Linear Systems with Switched Actuators Subject to Dwell-Time Constraints | 4 | Supplies the closest prior fixed-period timing model, switched-actuator specialization, LQR comparison, dwell constraints, and the sequential-saturation problem that motivates the conditioner. |
| `flieller2006limitCycles` | Computation and Stability of Limit Cycles in Hybrid Systems | 1 | Establishes earlier use of switching-time sensitivities for hybrid limit-cycle computation and sampled-time local-stability tests. |
| `repecho2017switchingFrequency` | Switching Frequency Regulation in Sliding Mode Control by a Hysteresis Band Controller | 1 | Provides an adjacent timing-feedback example that changes hysteresis-band amplitude rather than prescribed interior switching instants. |
| `stellato2017fcsMpc` | High-Speed Finite Control Set Model Predictive Control for Power Electronics | 1 | Supports the implementation-pressure discussion with a fixed-point FPGA implementation using short horizons and an offline approximate tail cost. |
| `albea2021hybridAffinePwm` | Control of Power Converters With Hybrid Affine Models and Pulse-Width Modulated Inputs | 1 | Provides converter-modeling context for hybrid-affine PWM and sample-and-hold dynamics with Lyapunov analysis. |
| `briat2013dwellTimes` | Affine Characterizations of Minimal and Mode-Dependent Dwell-Times for Uncertain Linear Switched Systems | 1 | Supplies broad switched-system stability context for minimum and mode-dependent dwell-time conditions without supporting the present conditioner. |
| `saeed2022laguerre` | Model Predictive Control of Phase Shift Full-Bridge DC--DC Converter Using Laguerre Functions | 1 | Represents reduced-dimension predictive control in the introduction's discussion of online computation. |
| `yang2022fixed` | Computationally Efficient Fixed Switching Frequency Direct Model Predictive Control | 1 | Represents a fast fixed-frequency predictive solver and the computational pressure in converter control. |
| `egidio2022rank` | Stabilization of Rank-Deficient Continuous-Time Switched Affine Systems | 1 | Distinguishes state-dependent active-mode selection from the paper's fixed mode order and timing-offset actuator. |
| `augustine2023mpc` | A Practically Stabilizing Model Predictive Control Scheme for Switched Affine Systems | 1 | Represents candidate pruning and approximation as ways to reduce online MPC cost. |
| `switchedOptimalDwell2025` | Switched Optimal Control with Dwell Time Constraints | 1 | Represents recent switching-time optimization with dwell constraints and contrasts with the solver-free scalar scan. |
| `russo2026dwell` | Stabilization of Switched Affine Systems With Dwell-Time Constraint | 1 | Provides a recent state-dependent dwell-time stabilization reference for comparison with fixed-sequence timing conditioning. |
| `boyd1994lmi` | Linear Matrix Inequalities in System and Control Theory | 1 | Provides standard background for the offline semidefinite/LMI certificate. |

### What the used set accomplishes

The cited set follows the four-layer introduction described in `handoff-3-specialization-funnel-and-citation-integration.md`:

1. **Implementation pressure:** Saeed, Yang, Augustine, Sakha/Kamalapurkar, and Stellato show representative ways that predictive or optimal control handles computation and dwell constraints.
2. **Exact control setting:** Egidio and Russo distinguish state-dependent mode selection from a prescribed sequence whose interior switching instants move. Repecho supplies a separate timing-feedback contrast based on hysteresis-band adaptation.
3. **Closest prior work:** Patiño and Marcolino receive the detailed treatment because they establish the switching-sensitivity and fixed-period cycle-model foundations. Flieller supplies the earlier hybrid limit-cycle and sampled-time stability context.
4. **Contribution and evidence:** the paper's conditioner and certificate are not cited as prior work. Briat supplies broader dwell-time stability context, Albea supplies converter-modeling context, and Boyd is cited only for standard LMI machinery.

## References not currently used

These records remain in `references.bib`, but their keys do not appear in the current `article.tex`.

| BibTeX key | Short title | Why it is not used in the focused manuscript |
|---|---|---|
| `benmiloud2019` | On the Local Stabilization of Hybrid Limit Cycles in Switched Affine Systems | It concerns local limit-cycle stabilization through state-dependent switching hypersurfaces and a hybrid Poincaré map. The current paper does not claim general limit-cycle stabilization or design switching surfaces. Adding it would broaden the introduction toward a different actuator mechanism. |
| `dellarossa2022frequency` | Continuous-Time Switched Systems with Switching Frequency Constraints: Path-Complete Stability Criteria | It certifies stability for classes of switching signals subject to frequency restrictions. The current paper preserves one mode order and one period, then corrects switching instants. No sentence in the current text makes a claim about path-complete switching languages. |
| `dellarossa2023stability` | Stability of Switched Affine Systems: Arbitrary and Dwell-Time Switching | It studies set stability and boundedness under arbitrary or dwell-time switching. The current paper studies regulation of one reference periodic trajectory under a fixed schedule, so this broader stability framework is outside the stated problem. |
| `wu2023datadriven` | Data-Driven Finite Control-Set Model Predictive Control for Modular Multilevel Converter | It addresses model uncertainty and data-driven finite-control-set MPC for an MMC. The present study assumes a known switched-affine model and focuses on timing feasibility, not model-free or data-driven control. |
| `li2024stability` | Stability-Oriented Design of Model Predictive Control for DC/DC Boost Converter | It develops stability-oriented tuning for a boost-converter MPC controller. The current paper does not introduce an MPC design or compare MPC weighting rules. Its stability result concerns an offline certificate for the conditioned cycle-map family instead. |
| `abbasiEsfeden2025dwell` | An Efficient Mixed-Integer Formulation and an Iterative Method for Optimal Control of Switched Systems Under Dwell Time Constraints | It is a useful neighboring method for complete schedule optimization, but the current paper fixes the mode sequence and deliberately avoids online mixed-integer optimization. Its comparison would repeat the optimization-versus-static-feedback point already represented by Yang, Augustine, and Sakha/Kamalapurkar. |
| `xu2024fcsLimitCycle` | Finite Control Set Model Predictive Control with Limit Cycle Stability Guarantees | It studies limit-cycle guarantees for finite-control-set MPC. The current paper uses static cycle-to-cycle timing feedback and does not need a broader FCS-MPC survey to define its fixed-sequence setting. It was omitted for focus, not because it is unrelated. |
| `seuret2023dataDrivenAffine` | LMI Relaxations and Its Application to Data-Driven Control Design for Switched Affine Systems | It focuses on data-driven control and uncertainty. Neither is part of the current problem statement. The paper's one LMI citation is limited to standard common-quadratic background, for which Boyd is sufficient. |
| `hanke2023planarLimitCycles` | On the Design of Limit Cycles of Planar Switching Affine Systems | It designs the switching-affine phase portrait to obtain a desired limit cycle. The current paper starts from a prescribed trajectory and schedule, so phase-portrait design is a non-goal. |
| `feng2024variableInertia` | Stability-Constrained Learning for Frequency Regulation in Power Grids with Variable Inertia | It studies a learning controller for frequency regulation in a converter-rich power-grid model. The current article has no learning component, grid-frequency application, or variable-inertia model. |
| `katz2026sampledDwell` | Observer-Based Sampled-Data Stabilisation of Switched Systems with Lipschitz Nonlinearities and Dwell-Time | It uses observer-based state-dependent switching for sampled-data systems. The current controller assumes the cycle-start state and parameters are available, preserves the mode order, and does not design an observer. |
| `singh2026mmcExponentialMpc` | Exponential Weighting Model Predictive Control with Observer for Modular Multilevel Converters | It is an online long-horizon MPC and observer method for MMCs. The current paper's converter example is a three-cell DC--DC benchmark and its central contrast is with a solver-free timing conditioner, so this reference is both technically different and redundant for the short introduction. |
| `sheng2026neuralFcsMpc` | Robust Neural Policy Distillation of Long-Horizon FCS-MPC for Flying-Capacitor Three-Level Boost Converters | It replaces online FCS-MPC search with a learned policy. The current article does not use neural policies, FCS-MPC, or policy distillation. Its general computation motivation is already covered by the smaller representative set of cited MPC papers. |
| `monir2025scenarioSwitchedAffine` | Robust Control of Uncertain Switched Affine Systems via Scenario Optimization | It solves a robust scenario-optimization problem under model uncertainty. Robust control and uncertainty are explicit non-goals in `GOAL.md`; retaining it would suggest a robustness claim the article does not support. |
| `egidio2020` | Global Asymptotic Stability of Limit Cycle and H2/H-infinity Performance of Discrete-Time Switched Affine Systems | It addresses global limit-cycle stability and performance through switched-system control laws. The current article makes a local nonlinear stability claim and preserves a prescribed mode sequence, so citing this record would invite a broader comparison than the text provides. The 2022 Egidio paper is enough for the narrower contrast with state-dependent mode selection. |
| `zhou1996robust` | Robust and Optimal Control | The earlier robust-control material was removed from the manuscript. The current article does not develop robust or H-infinity synthesis, and Boyd is sufficient for the single standard LMI background claim. |

## Why the earlier handoff listed more papers

`handoff-2-replace-literature-links-with-pdfs.md` describes an earlier state in which the article cited 20 recent papers and the introduction followed a broader literature funnel. The later handoffs record a deliberate change:

- the introduction was reduced from seven layers to four;
- distant literature was not to receive the same attention as Patiño and Marcolino;
- references were to support specific factual claims, not to meet a coverage target;
- robust control, uncertainty, trajectory optimization, and broad invariant-region material were removed or deferred;
- the article was narrowed to a fixed-period, fixed-mode-order timing controller with a scalar dwell conditioner and a common-quadratic certificate.

The earlier nine-reference set was therefore not an accidental loss of the 20-paper review. It resulted from narrowing the manuscript after the literature review. The five references added in the present pass each support a claim that survived that narrower scope.

## Primary-source verification for the added references

The six proposed sources were checked against lawful full text and DOI metadata before integration. Five were cited. Fiore et al. was verified but omitted because its Filippov regularization and matrix-measure framework does not support a necessary claim in the common-Lyapunov paragraph. The two reserve candidates in `handoff-5-reference-verification-and-integration.md` were not added.

| Key | Status and source type | Full-text evidence used |
|---|---|---|
| `flieller2006limitCycles` | Cited. HAL author manuscript of the published article. | Section III, Proposition 3 and equations (12), (15)--(18) give switching-instant sensitivities for periodic-orbit computation; Remark 5 links the Jacobian eigenvalues to sampled-time local stability. |
| `repecho2017switchingFrequency` | Cited. UPC author postprint of the published article. | Sections II-B and III-A, equations (14)--(20), define measured switching-period error and update hysteresis-band amplitude by integral feedback. |
| `stellato2017fcsMpc` | Cited. arXiv author preprint of the published article. | Sections III-F, VI-C, and VII-C describe the offline approximate tail cost, horizons one and two, fixed-point exhaustive FPGA implementation, and deterministic measured execution. |
| `albea2021hybridAffinePwm` | Cited. HAL author manuscript of the published article. | Equations (4)--(11) use exact two-subinterval propagation and embed PWM and sample-and-hold variables in a hybrid-affine model; Theorem 1 gives the Lyapunov result. |
| `briat2013dwellTimes` | Cited. arXiv author preprint of the published article. | Theorems 1, 2, 4, 11, and 13 give stability conditions for minimum and mode-dependent dwell times, including uncertain linear switched systems. |
| `fiore2016contraction` | Verified, not cited, and not added to `references.bib`. arXiv author preprint of the published article. | Theorems 5 and 6 concern contraction of bimodal Filippov systems through regularization. This is too remote from the article's discrete-time endpoint-norm argument. |

The claim boundaries recorded during review are:

- This paper supports prior use of switching-time sensitivities in periodic-orbit computation and Jacobian-eigenvalue tests for sampled-time local stability. It does not establish once-per-cycle feedback that shifts only prescribed interior switching instants while enforcing dwell limits through direction-preserving scalar conditioning. [`flieller2006limitCycles`]
- This paper supports feedback regulation of measured switching periods by adjusting hysteresis-band amplitude, using integral action and tracking feedforward compensation. It does not establish feedback that directly displaces a fixed schedule's interior switching instants while preserving cycle boundaries, mode order, and offset-vector direction under dwell constraints. [`repecho2017switchingFrequency`]
- This paper supports implementation-specific deterministic online execution, obtained with fixed-point exhaustive FPGA evaluation at horizons one and two after offline approximate tail-cost construction. It does not establish a hardware-independent bound on MPC computation, an offline explicit MPC solution, or the same timing for longer horizons or other converters. [`stellato2017fcsMpc`]
- This paper supports a non-averaged hybrid-affine converter model that embeds PWM and sample-and-hold variables and admits Lyapunov analysis. It does not establish exact augmented propagation for a prescribed nine-interval switching sequence. [`albea2021hybridAffinePwm`]
- This paper supports the broader stability context for uncertain linear switched systems under minimum and mode-dependent dwell-time constraints. It does not establish the article's scalar radial dwell conditioner, its maximality, or its endpoint-norm common-Lyapunov certificate. [`briat2013dwellTimes`]
- This paper supports general contraction context for bimodal Filippov systems through regularization and matrix-measure conditions. It does not establish the article's discrete-time endpoint-norm bound for the convex cycle-map family or its scalar radial dwell conditioner. [`fiore2016contraction`, omitted]

## Conclusion

The current article uses a focused set of **14 references out of 30 bibliography records**. Patiño and Marcolino remain the two closest foundations for the paper's model and benchmark. The five verified additions support narrow claims about implementation pressure, adjacent timing feedback, earlier switching-time sensitivity, dwell-time stability analysis, and hybrid-affine converter modeling. Boyd supports the standard LMI step.

The 16 uncited records were not discarded because their results are invalid or unimportant. They were left uncited for one of three reasons:

1. **Problem mismatch:** several study state-dependent mode selection, data-driven or robust control, learning, observers, finite-control-set MPC, or phase-portrait design rather than the fixed-period timing action used here.
2. **Redundancy:** the current introduction needs representative evidence for online computation and dwell-constrained optimization, not every paper in the broader review that makes a similar point.
3. **Scope control:** the manuscript avoids global nonlinear stability, general switched-system stability, robust synthesis, and complete schedule optimization. Citing papers centered on those topics would make the literature claims broader than the results support.

The unused records can remain in `references.bib` as a research archive, but they should be removed from the submission bibliography if the goal is a clean final manuscript. No article-text change is required merely because a reviewed paper was not cited. The important correction is to keep the bibliography consistent with the paper's final claims and its narrower contribution boundary.
