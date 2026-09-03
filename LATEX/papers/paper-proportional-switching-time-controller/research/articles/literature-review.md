# Literature review

This review covers the 26 PDFs in this folder. It is a screening document, not a substitute for reading the original papers. Its purpose is to answer three questions quickly: what problem does each paper solve, what can it safely support in our paper, and is a full reading worth the time?

The current set contains 16 core papers and 10 supporting papers. Core papers address periodic or switched-affine behavior, switching-time or dwell-time decisions, or Lyapunov certification. Supporting papers mainly establish converter-control computation, constraints, or implementation context. All 26 pass the current inclusion rule. No paper was screened out.

## Review 01: Marcolino, Galvão, and Kienitz (2021)

**Article:** [Predictive Control of Linear Systems with Switched Actuators Subject to Dwell-Time Constraints](01-marcolino-2021-dwell-constrained-predictive-control.pdf)  
**Source:** [DOI and publisher record](https://doi.org/10.1007/s40313-020-00667-9)  
**Class:** Core. Themes: fixed-period switched control, schedule optimization, dwell-time feasibility.

### Problem and setting
The paper studies a linear plant whose actuator is selected from switched levels. The switching schedule is periodic or cycle based, and the actuator must remain in each level for a minimum dwell duration. The central practical issue is that a controller may improve regulation by moving switching boundaries, but not every mathematically convenient schedule is physically admissible.

### Method and guarantee
The authors build a one-cycle prediction model and use it for LQR and constrained MPC designs. Dwell constraints enter the predictive formulation as explicit restrictions on the timing variables. The contribution is therefore an optimization-based treatment of the coupled timing constraints, not a componentwise clipping rule.

### Evidence and computation
The collected paper reports numerical converter-oriented examples. The archive source does not establish laboratory hardware, HIL, or industrial deployment. The computational burden is tied to solving the constrained predictive problem over admissible schedules.

### Relation to our article
This is the closest direct predecessor for fixed-period coordinates, dwell constraints, and timing feedback. Our article asks what happens when a raw timing law is already available but its output may violate coupled dwell constraints. We preserve the raw direction and contract its magnitude with one scalar instead of redesigning the action through constrained MPC.

### Safe citation use
Use it for the existence of fixed-period switched-actuator models and optimization-based dwell enforcement. Do not claim that it provides our maximal direction-preserving scalar conditioner or a solver-free O(N) feasibility scan.

### Reading recommendation
**Read the full paper.** Prioritize the one-cycle model, timing variables, dwell constraints, and the relation between the unconstrained timing law and the constrained predictive formulation.

## Review 02: Della Rossa, Pasquini, and Angeli (2022)

**Article:** [Continuous-Time Switched Systems with Switching Frequency Constraints: Path-Complete Stability Criteria](02-della-rossa-2022-switching-frequency.pdf)  
**Source:** [DOI and publisher record](https://doi.org/10.1016/j.automatica.2021.110099), [lawful accepted manuscript](https://spiral.imperial.ac.uk/handle/10044/1/93796)  
**Class:** Core. Themes: dwell or frequency restrictions, Lyapunov certification.

### Problem and setting
The paper considers continuous-time switched systems whose switching signals are restricted by frequency or dwell-time conditions. The question is not how to choose one preferred schedule, but how to certify stability for an entire language of admissible switching signals.

### Method and guarantee
It constructs path-complete Lyapunov certificates using a labeled graph. Inequalities associated with graph edges encode how Lyapunov functions evolve across modes and constrained switching patterns. The analysis covers constant switching frequency and is generalized to dwell-time settings. The result is a sufficient stability certificate, not a necessary characterization.

### Evidence and computation
The validation is theoretical and numerical. The source does not establish physical converter experiments, HIL, or deployment. The certificate search is an offline matrix-inequality problem; online operation is not the focus.

### Relation to our article
This paper supports the need to include switching restrictions in stability analysis. The difference matters for positioning. Its certificate covers classes of switching signals, whereas our article fixes the mode order and period and changes interior switching instants from cycle to cycle. Our common-quadratic argument certifies a segment of linearized cycle maps produced by the conditioner.

### Safe citation use
Use it for recent stability certification under switching-frequency or dwell restrictions. Do not describe it as a fixed-period timing-feedback method or as a switching-time optimizer.

### Reading recommendation
**Read the full paper.** Focus on the graph construction, the frequency-to-dwell interpretation, and how its certificate differs from a common quadratic certificate for a one-cycle matrix family.

## Review 03: Egidio, Deaecto, and Jungers (2022)

**Article:** [Stabilization of Rank-Deficient Continuous-Time Switched Affine Systems](03-egidio-2022-rank-deficient-switched-affine.pdf)  
**Source:** [DOI and publisher record](https://doi.org/10.1016/j.automatica.2022.110426), [author record](https://hdl.handle.net/2078.5/252130)  
**Class:** Core. Theme: Lyapunov-certified switched-affine control.

### Problem and setting
The paper addresses continuous-time switched-affine systems where convex combinations of the mode matrices can be rank deficient. It seeks stabilization of a selected equilibrium despite the structural difficulty created by rank deficiency.

### Method and guarantee
The controller uses state-dependent mode selection. LMI-based conditions establish global asymptotic and local exponential stability under the paper's assumptions. The method is a mode-selection synthesis: the state determines which subsystem is active.

### Evidence and computation
The work includes a modeled DC-motor and converter-oriented example with several subsystems. The collected author material describes an application example but does not establish physical hardware, HIL, or industrial deployment. The LMI design is offline; the online action is mode selection.

### Relation to our article
It is a useful modern example of LMI-certified switched-affine feedback. It also makes the contrast with our method clear. Egidio et al. select modes from the state. Our article preserves a prescribed mode order and computes timing offsets for the next cycle. The two methods address different control freedoms.

### Safe citation use
Use it to support the claim that recent switched-affine stabilization often relies on state-dependent mode selection and LMI certificates. Do not use it as evidence for fixed-period timing feedback or dwell conditioning.

### Reading recommendation
**Read the full paper if the introduction emphasizes switched-affine stabilization.** Otherwise, the abstract, controller definition, stability theorem, and application section are enough for citation placement.

## Review 04: Della Rossa, Egidio, and Jungers (2023)

**Article:** [Stability of Switched Affine Systems: Arbitrary and Dwell-Time Switching](04-della-rossa-2023-stability-switched-affine.pdf)  
**Source:** [DOI and publisher record](https://doi.org/10.1137/22M1482226), [arXiv author manuscript](https://arxiv.org/abs/2203.06968)  
**Class:** Core. Themes: dwell-time stability, Lyapunov and LMI certification.

### Problem and setting
The paper studies stability and boundedness of switched-affine systems under arbitrary switching and under dwell-time restrictions. It treats the admissible switching law as part of the stability problem rather than as an implementation detail.

### Method and guarantee
The analysis develops Lyapunov, LMI, and sum-of-squares conditions. The conditions provide computable sufficient certificates for set stability and boundedness. They are aimed at broad switched-affine behavior, not at one fixed periodic orbit.

### Evidence and computation
The results are theoretical with numerical examples. No physical hardware, HIL, or deployment is established. The computational work is offline certificate construction and verification.

### Relation to our article
This paper supplies recent dwell-time stability framing for the literature review. Our result is more specialized. We use a fixed mode order, a fixed period, and a local one-cycle map. The conditioner produces a family of closed-loop matrices along a line segment, and a common quadratic Lyapunov function certifies that family. We should present this as a specialization, not as a replacement for general dwell-time stability theory.

### Safe citation use
Use it for arbitrary and dwell-time switched-affine stability certificates. Do not claim that it handles our cycle-to-cycle switching-instant feedback law.

### Reading recommendation
**Read the full paper.** The stability definitions, dwell-time conditions, and comparison with arbitrary switching are the relevant sections.

## Review 05: Sakha and Kamalapurkar (2025)

**Article:** [Switched Optimal Control with Dwell Time Constraints](05-sakha-2025-switched-optimal-dwell.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2501.05548)  
**Class:** Core. Themes: switching-time optimization and dwell-time feasibility.

### Problem and setting
The paper formulates optimal control for switched systems when switching times must obey minimum dwell constraints. The switching signal is part of the optimization rather than a fixed schedule supplied in advance.

### Method and guarantee
The method embeds switching in a continuous optimization formulation and adds a filtering layer that removes switching times violating dwell restrictions. The filter is an admissibility mechanism inside an optimization workflow. It does not claim to preserve the direction of an arbitrary raw timing action.

### Evidence and computation
The paper provides numerical examples. The source does not establish converter hardware, HIL, or industrial deployment. The main computational burden comes from the switched optimal-control problem and its switching-time variables.

### Relation to our article
It is a direct comparison for the optimization-heavy route. Both papers care about switching-time feasibility, but their control workflows differ. Sakha and Kamalapurkar optimize the switched trajectory and filter infeasible switching times. Our method receives a raw timing vector from a static cycle-level feedback law and computes the largest feasible scalar multiple without an online optimizer.

### Safe citation use
Use it to establish that recent switched optimal-control methods require explicit dwell-time filtering. Do not call its filter equivalent to our analytic direction-preserving contraction.

### Reading recommendation
**Read the full paper.** Focus on the switching-time parameterization, the filter definition, and the computational workflow.

## Review 06: Augustine and Patil (2023)

**Article:** [A Practically Stabilizing Model Predictive Control Scheme for Switched Affine Systems](06-augustine-2023-switched-affine-mpc.pdf)  
**Source:** [DOI and publisher record](https://doi.org/10.1109/LCSYS.2022.3210368)  
**Class:** Supporting. Theme: computation-aware switched-affine MPC.

### Problem and setting
The paper addresses the online burden of model predictive control for switched-affine systems. The controller must search over candidate switched trajectories while retaining a practical-stability property.

### Method and guarantee
Candidate pruning and cost approximation reduce the search. The paper gives a practical-stability result for the resulting scheme, rather than simply presenting a heuristic speedup.

### Evidence and computation
The available source reports converter simulation rather than laboratory hardware, HIL, or deployment. Computation is central: the method reduces candidate evaluation and approximates the cost within an MPC framework.

### Relation to our article
It supports the motivation for removing online optimization from dwell enforcement. The difference is that Augustine and Patil still solve an approximate predictive-control problem. Our raw feedback law is static, and the conditioner adds only a scalar feasibility calculation after that law has been evaluated.

### Safe citation use
Use it for the claim that switched-affine MPC often needs candidate pruning or cost approximation to meet online computation limits. Do not use it as evidence for timing-direction preservation.

### Reading recommendation
**Read only the relevant sections initially.** Read the candidate-pruning mechanism, practical-stability result, and converter example. Read the full paper if the computation comparison becomes central.

## Review 07: Xu and Lazar (2024)

**Article:** [Finite Control Set Model Predictive Control with Limit Cycle Stability Guarantees](07-xu-2024-fcs-limit-cycle.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2407.07615)  
**Class:** Core. Themes: periodic switched-affine control, limit-cycle stability, feasibility.

### Problem and setting
The paper designs finite-control-set MPC for discrete-time switched-affine systems with a desired steady-state periodic limit cycle. The setting is close to converter control because the available actions are discrete and the target is not necessarily an equilibrium.

### Method and guarantee
Periodic terminal costs and terminal sets are used to obtain recursive feasibility and asymptotic-stability conditions for the desired limit cycle. The design remains an FCS-MPC scheme, so the online controller still evaluates a finite set of discrete alternatives.

### Evidence and computation
The paper uses switched-system and power-electronics benchmarks. The available record does not establish industrial deployment. The computational profile is that of FCS-MPC with terminal ingredients, not a solver-free timing update.

### Relation to our article
This is a strong replacement for the periodic-converter role of the inaccessible paper. It supports the statement that limit-cycle stability can be made an explicit predictive-control objective. Our article takes a different route: it fixes the mode order, uses a cycle map, and conditions continuous switching-time offsets rather than searching over discrete switch sequences.

### Safe citation use
Use it for periodic FCS-MPC, limit-cycle stability, and recursive feasibility. Do not imply that it optimizes the same timing coordinates or uses a common-quadratic endpoint certificate.

### Reading recommendation
**Read the full paper.** Prioritize the switched-affine model, terminal construction, feasibility theorem, and power-electronics benchmark.

## Review 08: Seuret, Albea, and Gordillo (2023)

**Article:** [LMI Relaxations and Its Application to Data-Driven Control Design for Switched Affine Systems](08-seuret-2023-data-driven-affine.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2302.11923)  
**Class:** Core. Themes: switched-affine stabilization, data-driven design, Lyapunov certification.

### Problem and setting
The paper studies control design for uncertain switched-affine systems when data can be used in place of a fully known model. The goal is to obtain useful stability or hybrid-behavior guarantees without relying on an exact model description.

### Method and guarantee
Data-dependent matrix conditions and LMI relaxations support Lyapunov-based controller design. The paper applies the conditions to robust hybrid limit-cycle behavior. The guarantee is tied to the stated data and uncertainty assumptions; it is not a general certificate for every possible plant.

### Evidence and computation
The paper presents theoretical conditions and examples. The source does not establish physical hardware, HIL, or industrial deployment. The LMI work is primarily offline, with the resulting controller used online.

### Relation to our article
It supports the connection between switched-affine control, limited model knowledge, and Lyapunov certification. Our article is less data-driven and more timing-specific. We assume a local cycle model, then certify the family of conditioned one-cycle matrices with a common quadratic Lyapunov function.

### Safe citation use
Use it for recent data-driven or LMI-based stabilization of uncertain switched-affine systems. Do not claim it validates our direction-preserving conditioner or fixed-period timing law.

### Reading recommendation
**Read the full paper if model uncertainty becomes part of the paper's positioning.** Otherwise, read the assumptions, LMI conditions, and application section.

## Review 09: Hanke and Stursberg (2023)

**Article:** [On the Design of Limit Cycles of Planar Switching Affine Systems](09-hanke-2023-planar-limit-cycles.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2303.16505)  
**Class:** Core. Theme: periodic switching-affine limit-cycle design.

### Problem and setting
The paper asks how to design stable limit cycles in planar switching-affine systems with desired oscillation amplitudes and frequencies. It treats periodic behavior as a design target rather than as an incidental consequence of switching.

### Method and guarantee
The method selects switching-affine phase portraits that generate the requested oscillation characteristics. The result is a design procedure for stable planar cycles, supported by analysis and numerical examples.

### Evidence and computation
The paper is theoretical and numerical. The source does not establish converter hardware, HIL, or industrial deployment. The computational burden is associated with offline cycle design rather than online timing conditioning.

### Relation to our article
It supports the periodic-orbit part of the funnel and narrows any claim that hybrid limit-cycle design is new. The difference is central: Hanke and Stursberg design the phase portrait, while our article starts from a prescribed mode order and period and regulates the cycle through switching-instant feedback.

### Safe citation use
Use it for recent switching-affine limit-cycle design and frequency or amplitude specification. Do not use it as evidence for dwell-feasibility conditioning.

### Reading recommendation
**Read only the relevant sections initially.** Read the cycle-design formulation and examples. Full reading is optional unless the paper's periodic-orbit novelty claim is expanded.

## Review 10: Russo, Incremona, and Colaneri (2026)

**Article:** [Stabilization of Switched Affine Systems With Dwell-Time Constraint](10-russo-2026-dwell-time-stabilization.pdf)  
**Source:** [DOI and author manuscript](https://re.public.polimi.it/bitstream/11311/1307779/1/sas_dwell_time_TAC_pub.pdf)  
**Class:** Core. Themes: dwell-time stabilization and Lyapunov certification.

### Problem and setting
The paper stabilizes switched-affine systems while enforcing a minimum dwell time. The switching law is state dependent, so the method chooses which mode is active subject to the dwell restriction.

### Method and guarantee
The analysis uses differential Lyapunov equations and Lyapunov–Metzler inequalities. The paper derives stability conditions and quadratic-cost bounds for the resulting state-switching law.

### Evidence and computation
The source reports numerical examples. It does not establish physical hardware, HIL, or industrial deployment. The synthesis is an offline matrix-inequality problem; online control is state-dependent mode selection.

### Relation to our article
It is a current and technically close dwell-time stabilization comparison. The contrast must be explicit. Russo et al. synthesize a mode-selection law. Our article does not change the sequence. It conditions the magnitude of a timing action and certifies the resulting linearized cycle-map segment.

### Safe citation use
Use it for state-dependent switched-affine stabilization under dwell time. Do not describe it as a fixed-sequence switching-time controller.

### Reading recommendation
**Read the full paper.** Prioritize the dwell-time law, Lyapunov–Metzler conditions, cost bound, and distinction between mode selection and timing adjustment.

## Review 11: Abbasi-Esfeden et al. (2025)

**Article:** [An Efficient Mixed-Integer Formulation and an Iterative Method for Optimal Control of Switched Systems Under Dwell Time Constraints](11-abbasi-2025-dwell-optimization.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2501.05158)  
**Class:** Core. Themes: sequence and switching-time optimization, dwell constraints.

### Problem and setting
The paper considers optimal control of switched systems where both the sequence and switching times are decision variables, subject to dwell-time restrictions. This is a broader optimization problem than our fixed-sequence timing update.

### Method and guarantee
The formulation separates sequence optimization from switching-time optimization. It limits the growth of binary variables with the discretization grid and uses an iterative method to reduce the mixed-integer burden. The guarantee is the optimization formulation and its reported numerical behavior, not the common-Lyapunov property used in our article.

### Evidence and computation
The validation is algorithmic and numerical. No converter hardware or deployment is established. Computation is the main topic: the method reduces the cost of mixed-integer schedule optimization but does not remove optimization altogether.

### Relation to our article
It is one of the strongest alternatives to cite when explaining why complete schedule optimization is more expensive than conditioning a prescribed schedule. We optimize neither the sequence nor the full timing vector online. We scan the dwell changes induced by a raw vector and retain its largest feasible scalar multiple.

### Safe citation use
Use it for efficient mixed-integer schedule optimization under dwell constraints. Do not call it a solver-free method or suggest that it preserves a raw timing direction.

### Reading recommendation
**Read the full paper.** Focus on the sequence/timing decomposition and the binary-variable scaling argument.

## Review 12: Feng et al. (2024)

**Article:** [Stability-Constrained Learning for Frequency Regulation in Power Grids with Variable Inertia](12-feng-2024-stability-constrained-power-grid.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2405.20489)  
**Class:** Supporting. Themes: converter-rich application, switched-affine modeling, stability-constrained computation.

### Problem and setting
The paper studies frequency regulation in power grids with variable inertia, including converter-rich dynamics. The variable-inertia model is represented as a switched-affine hybrid system, and the controller must balance regulation with stability.

### Method and guarantee
A stability-constrained learning controller is compared with simpler control baselines. The paper uses a quadratic stability certificate to constrain the learned policy and keep the online method computationally tractable.

### Evidence and computation
The available source reports simulation and numerical comparison. It does not establish physical hardware, HIL, or industrial deployment. The computational concern is making stability-constrained learning usable in a changing grid model.

### Relation to our article
It supports the application funnel from switched-affine models to stability-constrained control in converter-rich systems. It is not a direct timing-method predecessor. Its controller learns state feedback, while our article uses a fixed cycle map and modifies switching instants without changing the mode sequence.

### Safe citation use
Use it for converter-rich switched-affine applications and stability-constrained computation. Avoid claiming that it addresses periodic switching-time feedback or dwell conditioning.

### Reading recommendation
**Read only the relevant sections initially.** Read the switched-affine model, stability constraint, and computational comparison. Full reading is optional.

## Review 13: Yang et al. (2022)

**Article:** [Computationally Efficient Fixed Switching Frequency Direct Model Predictive Control](13-yang-2022-fixed-frequency-direct-mpc.pdf)  
**Source:** [DOI and publisher record](https://doi.org/10.1109/TPEL.2021.3114979)  
**Class:** Core. Themes: fixed-frequency timing, converter computation, online optimization.

### Problem and setting
The paper develops direct MPC for power converters while preserving fixed switching frequency. The short switching period leaves little time for online optimization, but the controller still needs to coordinate switching instants and converter objectives.

### Method and guarantee
Switching instants are optimized through a constrained quadratic program. Custom solver techniques and early termination reduce execution time. The work emphasizes computational execution rather than a closed-form feasibility correction or a common-quadratic cycle-map certificate.

### Evidence and computation
The paper reports laboratory experiments on a 3 kW two-level inverter and induction-machine drive. This is laboratory hardware, not industrial deployment. The central computation result is few-microsecond execution of the online QP.

### Relation to our article
It is a strong comparison for fixed-frequency timing control. Both methods care about the timing budget, but Yang et al. retain online optimization. Our conditioner is designed for the case where the raw timing feedback has already been computed and only feasibility remains to be enforced.

### Safe citation use
Use it for fixed-frequency switching-time control, constrained online QP, and the tight execution budget of converter control. Do not claim that it uses a solver-free scan or a fixed mode order of the type used here.

### Reading recommendation
**Read the full paper.** The QP formulation, custom solver, timing variables, and experimental timing results are directly relevant.

## Review 14: Saeed, Wang, and Fernando (2022)

**Article:** [Model Predictive Control of Phase Shift Full-Bridge DC–DC Converter Using Laguerre Functions](14-saeed-2022-laguerre-converter-mpc.pdf)  
**Source:** [DOI and publisher record](https://doi.org/10.1109/TCST.2021.3069148)  
**Class:** Supporting. Theme: constrained converter MPC with reduced computation.

### Problem and setting
The paper controls a phase-shift full-bridge DC–DC converter while enforcing a nonlinear peak-current constraint within a short sampling interval. The problem is representative of converter control where physical constraints and computation are coupled.

### Method and guarantee
Laguerre-function parameterization reduces the number of MPC decision variables. The method retains predictive optimization but makes the decision problem smaller. Its contribution is computational reduction within MPC, not a switched-affine timing-feasibility theorem.

### Evidence and computation
The work reports a 60 W laboratory converter with 40 microsecond sampling. It is laboratory validation, not industrial deployment. The relevant computational result is the reduction in optimization dimension.

### Relation to our article
It supports the application claim that constraint handling must fit the available sampling budget. Our article uses a different simplification: the raw feedback action is not reparameterized or reoptimized; dwell feasibility is enforced analytically by one scalar scan.

### Safe citation use
Use it for reduced-variable constrained converter MPC and laboratory-scale timing budgets. Do not use it as a direct predecessor for fixed-sequence cycle maps.

### Reading recommendation
**Read only the relevant sections initially.** Read the peak-current constraint, Laguerre parameterization, and experimental timing information.

## Review 15: Katz et al. (2026)

**Article:** [Observer-Based Sampled-Data Stabilisation of Switched Systems with Lipschitz Nonlinearities and Dwell-Time](15-katz-2026-sampled-dwell.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2511.01672)  
**Class:** Core. Themes: sampled-data switching, dwell-time stability, Lyapunov certification.

### Problem and setting
The paper studies switched systems observed through sampled measurements, with Lipschitz nonlinearities and dwell-time constraints. It extends dwell-time analysis beyond a full-state, continuously observed idealization.

### Method and guarantee
Observer-based switching is combined with Lyapunov–Metzler and LMI conditions. The results provide global asymptotic stability in the relevant nonlinear setting and ultimate-boundedness results for switched-affine terms under the paper's assumptions.

### Evidence and computation
The paper uses theoretical and numerical examples. The source does not establish physical hardware, HIL, or industrial deployment. The key computational work is offline LMI condition construction; the online controller uses sampled observations.

### Relation to our article
It supports the role of sampling, dwell time, and offline stability certificates. Our article assumes a prescribed mode order and uses cycle-start state error to update timing offsets. It does not solve the observer-based mode-selection problem studied here.

### Safe citation use
Use it for sampled-data dwell-time stability and the effect of measurement structure on switched-system certification. Do not claim that it provides a timing-direction conditioner.

### Reading recommendation
**Read the full paper.** Focus on the sampled-data model, observer, dwell-time conditions, and the distinction between stability and ultimate boundedness.

## Review 16: Singh et al. (2026)

**Article:** [Exponential Weighting Model Predictive Control with Observer for Modular Multilevel Converters](16-singh-2026-mmc-exponential-mpc.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2606.16631)  
**Class:** Supporting. Theme: constrained and computation-aware MMC MPC.

### Problem and setting
The paper addresses long-horizon MPC for modular multilevel converters. Long prediction horizons can create numerical-conditioning problems, while the controller must also account for plant and control constraints.

### Method and guarantee
Exponential weighting changes the cost structure to improve long-horizon conditioning. An observer supplies state information, and the paper analyzes closed-loop stability and constraints under its formulation. This remains an online MPC method.

### Evidence and computation
The source reports MMC simulations and numerical analysis. It does not establish physical hardware, HIL, or industrial deployment. Its computational contribution is improved conditioning and tractability, not elimination of online optimization.

### Relation to our article
It supports the converter funnel's claim that long-horizon predictive control must address computation and constraints together. Our article takes a smaller online route: it applies a raw static timing law and performs a scalar dwell-feasibility scan rather than solving a long-horizon MPC problem.

### Safe citation use
Use it for constrained, observer-based, computation-aware MMC MPC. Do not claim it supports fixed-period timing feedback or a solver-free implementation.

### Reading recommendation
**Read only the relevant sections initially.** Read the cost weighting, constraints, stability analysis, and computational comparison.

## Review 17: Wu et al. (2023)

**Article:** [Data-Driven Finite-Control-Set Model Predictive Control for Modular Multilevel Converter](17-wu-2023-data-driven-mmc-mpc.pdf)  
**Source:** [DOI and publisher record](https://doi.org/10.1109/JESTPE.2022.3207454)  
**Class:** Supporting. Theme: data-driven and lower-cost MMC control.

### Problem and setting
The paper applies finite-control-set MPC to an MMC without depending on a fully accurate converter model and without accepting excessive online computation. MMC balancing and switching objectives create a large candidate and model-evaluation burden.

### Method and guarantee
Model-free adaptive control is embedded in FCS-MPC and the cost function is simplified. The controller uses data or adaptive information to reduce model dependence while retaining finite-control-set decision making.

### Evidence and computation
The paper reports simulation and laboratory experiments. It does not establish industrial deployment. The practical contribution is the combined reduction in model burden and online cost, not a dwell-time or cycle-map stability result.

### Relation to our article
It supports the application funnel's claim that embedded converter control must manage both model uncertainty and candidate evaluation. Our paper assumes a switched-affine one-cycle model for local analysis and focuses on timing feasibility and certification instead.

### Safe citation use
Use it for data-driven FCS-MPC and computational constraints in MMC control. Do not use it to support fixed-period dwell conditioning.

### Reading recommendation
**Read only the relevant sections initially.** Read the adaptive model, simplified cost, and hardware results. Full reading is optional unless MMC data-driven control becomes central.

## Review 18: Li et al. (2024)

**Article:** [Stability-Oriented Design of Model Predictive Control for DC/DC Boost Converter](18-li-2024-stability-oriented-mpc.pdf)  
**Source:** [DOI and accepted manuscript](https://doi.org/10.1109/TIE.2023.3247785)  
**Class:** Supporting. Themes: fixed-frequency converter control and stability-oriented tuning.

### Problem and setting
The paper designs fixed-frequency boost-converter MPC with explicit attention to closed-loop stability and nonminimum-phase behavior. It addresses the fact that a controller can meet a local objective while still producing undesirable closed-loop dynamics if the weights and horizon are poorly chosen.

### Method and guarantee
A single-horizon formulation and Jacobian-based guidance are used to select weighting parameters and improve stability behavior. The result is stability-oriented MPC tuning, not a common-quadratic certificate for a family of conditioned cycle maps.

### Evidence and computation
The paper reports laboratory experimental validation. It does not establish industrial deployment. The computation remains MPC, but the tuning procedure aims to make the resulting controller practical and stable.

### Relation to our article
It supports the need to pair converter-control computation with a stability argument. Our article moves the certificate to the complete conditioned linearized cycle-map family and uses offline endpoint inequalities, while Li et al. guide MPC tuning.

### Safe citation use
Use it for stability-oriented fixed-frequency converter MPC and laboratory evidence. Do not describe it as a dwell-time or switching-time conditioner.

### Reading recommendation
**Read only the relevant sections initially.** Read the stability rationale, Jacobian-based tuning, and experimental results.

## Review 19: Sheng et al. (2026)

**Article:** [Robust Neural Policy Distillation of Long-Horizon FCS-MPC for Flying-Capacitor Three-Level Boost Converters](19-sheng-2026-neural-fcs-mpc.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2604.11192)  
**Class:** Supporting. Theme: reducing long-horizon converter sequence search.

### Problem and setting
The paper addresses the cost of long-horizon finite-control-set MPC for a flying-capacitor three-level boost converter. Searching over long sequences can be too expensive for online execution.

### Method and guarantee
Beam-search expert trajectories are distilled into a neural policy. Randomized operating conditions and disagreement-based relabeling are used to improve robustness of the learned policy. The learned policy replaces online sequence search; it does not preserve a fixed prescribed sequence.

### Evidence and computation
The source reports converter simulations and robustness tests. It does not establish physical hardware, HIL, or industrial deployment. The main computation claim is reduced online evaluation through policy distillation.

### Relation to our article
It is a clear alternative to solver-based or search-heavy converter control. Our article takes a deliberately narrower and more transparent route: no learned policy, no sequence search, and no change of action direction. It only contracts the timing action enough to satisfy dwell constraints.

### Safe citation use
Use it for recent efforts to reduce long-horizon FCS-MPC sequence-search cost. Do not use it as evidence for analytic dwell feasibility or Lyapunov certification.

### Reading recommendation
**Read only the relevant sections initially.** Read the expert-search cost, distillation method, and robustness evaluation. Full reading is optional.

## Review 20: Monir, Sadabadi, and Soudjani (2025)

**Article:** [Robust Control of Uncertain Switched Affine Systems via Scenario Optimization](20-monir-2025-scenario-switched-affine.pdf)  
**Source:** [arXiv record and PDF](https://arxiv.org/abs/2505.06943)  
**Class:** Core. Themes: uncertain switched-affine control and Lyapunov certification.

### Problem and setting
The paper designs switching laws for uncertain switched-affine systems whose matrix parameters are not known exactly. The uncertainty affects stability, regulation error, and the amount of switching or chattering required.

### Method and guarantee
Data-driven scenario optimization is combined with quadratic Lyapunov functions to design robust invariant sets and switching laws. The guarantee is probabilistic or scenario-based under the paper's uncertainty and sampling assumptions, not a universal guarantee for all plant uncertainties.

### Evidence and computation
The paper includes numerical examples involving power-electronic converters. The source does not establish physical hardware, HIL, or industrial deployment. The main computation is an offline or optimization-based robust-control design, rather than an O(N) online feasibility scan.

### Relation to our article
It represents the robust optimization route for uncertain switched-affine control and helps delimit our claim. Our article does not solve a scenario problem or claim robustness to arbitrary model uncertainty. It conditions the timing action and certifies the linearized family through a common quadratic Lyapunov function under the stated model assumptions.

### Safe citation use
Use it for scenario-based robust switched-affine control and converter-oriented examples. Do not claim that it establishes the contribution of our conditioner.

### Reading recommendation
**Read the full paper if uncertainty becomes part of the paper's scope.** Otherwise, read the uncertainty model, quadratic Lyapunov formulation, and converter example.

## Review 21: Flieller, Riedinger, and Louis (2006)

**Article:** [Computation and Stability of Limit Cycles in Hybrid Systems](21-flieller-2006-hybrid-limit-cycles.pdf)
**Source:** [DOI and publisher record](https://doi.org/10.1016/j.na.2005.06.054), [HAL author manuscript](https://hal.science/hal-00119807)
**Class:** Core. Themes: hybrid limit-cycle computation, switching-time sensitivity, sampled-time stability.

### Problem and setting
The paper studies computation and stability of periodic orbits in hybrid systems whose switching events depend on the state and parameters. The timing of the events is part of the periodic-orbit calculation.

### Method and guarantee
A Newton procedure updates the initial condition and switching-time vector to satisfy periodicity and switching constraints. The paper derives sensitivities with respect to switching instants and uses the resulting Jacobian to assess sampled-time local stability through its eigenvalues.

### Evidence and computation
The paper gives analytical developments and a phase-locked-loop application with numerical stability results. It does not establish the direction-preserving dwell conditioner used in our article.

### Relation to our article
This is prior work for switching-time sensitivity, periodic-orbit computation, and sampled-time local stability. Our article should therefore present its switching-sensitivity derivation as a controller-ready specialization and its novelty as the feasible scalar conditioning layer, not as the first switching-time sensitivity method.

### Safe citation use
Use it for the historical claim that hybrid limit-cycle computation and sampled-time stability have used switching-time sensitivities. Do not use it as evidence for fixed-period feedback that scales a prescribed offset vector or for the common-Lyapunov certificate.

### Reading recommendation
**Read the full paper.** Focus on the switching-time sensitivity proposition, periodic-orbit Newton iteration, and sampled-time stability discussion.

## Review 22: Repecho, Biel, Olm, and Fossas Colet (2017)

**Article:** [Switching Frequency Regulation in Sliding Mode Control by a Hysteresis Band Controller](22-repecho-2017-switching-frequency-regulation.pdf)
**Source:** [DOI and publisher record](https://doi.org/10.1109/TPEL.2016.2546382), [UPCommons author postprint](https://upcommons.upc.edu/handle/2117/99560)
**Class:** Supporting. Theme: feedback regulation of switching timing by hysteresis-band adaptation.

### Problem and setting
The paper regulates the switching frequency of a sliding-mode controller. The switching period is measured and compared with a desired value while the controller remains state-triggered by a hysteresis comparator.

### Method and guarantee
A discrete-time integral controller changes the hysteresis-band amplitude according to the measured switching-period error. A feedforward term extends the method to tracking, and the paper gives stability conditions for the regulation and tracking cases.

### Evidence and computation
The paper reports numerical simulations and experimental results. Its actuator is the hysteresis-band amplitude, not a vector of prescribed interior switching instants in a fixed-period cycle.

### Relation to our article
It is a useful adjacent timing-feedback reference. Our article preserves the mode order, interval count, and cycle boundaries and directly displaces the interior switching instants once per cycle. Repecho et al. regulate a measured switching period indirectly by changing a comparator band.

### Safe citation use
Use it when distinguishing other feedback mechanisms that regulate switching timing. Do not describe it as fixed-schedule timing feedback or as a dwell conditioner.

### Reading recommendation
**Read the full paper.** Focus on the measured-period update, hysteresis-band mechanism, stability conditions, and experimental setup.

## Review 23: Stellato, Geyer, and Goulart (2017)

**Article:** [High-Speed Finite Control Set Model Predictive Control for Power Electronics](23-stellato-2017-high-speed-fcs-mpc.pdf)
**Source:** [DOI and publisher record](https://doi.org/10.1109/TPEL.2016.2584678), [arXiv author preprint](https://arxiv.org/abs/1510.05578)
**Class:** Supporting. Themes: computation-aware power-electronics MPC, short horizons, implementation timing.

### Problem and setting
The paper addresses the computational cost of finite-control-set MPC for power electronics, especially when long prediction horizons create too many integer candidates.

### Method and guarantee
An approximate dynamic-programming construction supplies an offline tail-cost approximation, allowing short horizons. The implementation evaluates candidates with fixed-point exhaustive search on an FPGA and reports measurements for horizons one and two.

### Evidence and computation
The paper reports deterministic timing for its specific implementation, including measured execution times of 5.76 microseconds for horizon one and 17.27 microseconds for horizon two. It does not prove a hardware-independent computation bound or an offline explicit MPC solution.

### Relation to our article
It supports the implementation-pressure paragraph in the introduction. The contrast is direct: the FCS-MPC controller still solves a finite candidate-selection problem, whereas our static timing law is followed by an O(N) scalar feasibility scan.

### Safe citation use
Use it for implementation-specific short-horizon and computation-timing evidence. Do not generalize its deterministic timing result to arbitrary hardware, horizons, or converters.

### Reading recommendation
**Read the relevant sections.** Focus on the approximate tail cost, horizon restriction, implementation algorithm, and timing measurements.

## Review 24: Albea-Sanchez, Sferlazza, Gómez-Estern, and Gordillo (2021)

**Article:** [Control of Power Converters With Hybrid Affine Models and Pulse-Width Modulated Inputs](24-albea-sanchez-2021-hybrid-affine-pwm.pdf)
**Source:** [DOI and publisher record](https://doi.org/10.1109/TCSI.2021.3083900), [HAL author manuscript](https://hal.science/hal-03326994)
**Class:** Core. Themes: hybrid-affine converter modeling, PWM, exact propagation, Lyapunov analysis.

### Problem and setting
The paper models power converters with hybrid-affine dynamics and pulse-width-modulated inputs. The model includes switching, sample-and-hold variables, and timer-related hybrid behavior.

### Method and guarantee
The paper uses exact matrix-exponential propagation over two PWM subintervals and constructs an augmented hybrid model. Its Lyapunov analysis gives conditions for stability of a compact target set under the stated assumptions.

### Evidence and computation
The source is a published journal article available as a HAL author manuscript. It provides analytical results and converter examples, not the prescribed nine-interval timing controller studied here.

### Relation to our article
It prevents broad claims that exact hybrid-affine propagation or PWM augmentation is new. Our case study instead retains a prescribed nine-interval mode sequence and uses its cycle map for timing feedback and dwell conditioning.

### Safe citation use
Use it for hybrid-affine converter modeling with PWM and Lyapunov analysis. Do not cite it as prior art for the article's scalar conditioner, fixed-period offset coordinates, or nine-interval sequence.

### Reading recommendation
**Read the full paper.** Focus on the affine model, exact subinterval propagation, augmented PWM state, and Lyapunov theorem.

## Review 25: Briat and Seuret (2013)

**Article:** [Affine Characterizations of Minimal and Mode-Dependent Dwell-Times for Uncertain Linear Switched Systems](25-briat-2013-dwell-times.pdf)
**Source:** [DOI and publisher record](https://doi.org/10.1109/TAC.2012.2220031), [arXiv author preprint](https://arxiv.org/abs/1209.0444)
**Class:** Core. Themes: minimum and mode-dependent dwell time, switched-system stability, looped-functionals.

### Problem and setting
The paper studies stability of uncertain linear switched systems under minimum and mode-dependent dwell-time restrictions. The switching signal is constrained by elapsed-time conditions rather than by a prescribed timing-offset feedback law.

### Method and guarantee
Lyapunov and looped-functional conditions characterize stability for minimum and mode-dependent dwell times. The paper also treats uncertain subsystem matrices and derives conditions affine in those matrices.

### Evidence and computation
The results are theoretical with numerical examples. The certificate construction is an offline stability analysis; it does not compute the largest feasible scalar multiple of a raw timing action.

### Relation to our article
This paper supplies broader dwell-time stability context. Its use of the word affine refers to the stability conditions' dependence on subsystem matrices, not to the article's convex family of conditioned cycle matrices. The present scalar scan and endpoint-norm certificate remain separate contributions.

### Safe citation use
Use it for general minimum and mode-dependent dwell-time stability conditions. Do not present it as prior art for radial conditioning, fixed-period timing coordinates, or the article's common-Lyapunov endpoint argument.

### Reading recommendation
**Read the full paper.** Focus on the minimum and mode-dependent dwell-time theorems, looped-functionals, and uncertainty assumptions.

## Review 26: Fiore, Hogan, and di Bernardo (2016)

**Article:** [Contraction Analysis of Switched Systems via Regularization](26-fiore-2016-contraction-regularization.pdf)
**Source:** [DOI and publisher record](https://doi.org/10.1016/j.automatica.2016.06.028), [arXiv author preprint](https://arxiv.org/abs/1507.07126)
**Class:** Supporting. Theme: contraction analysis for bimodal Filippov systems.

### Problem and setting
The paper studies incremental stability and convergence in switched, bimodal Filippov systems with discontinuous switching surfaces. It uses regularization to connect the discontinuous system to smooth contraction conditions.

### Method and guarantee
Matrix-measure conditions are applied to regularized vector fields, and the resulting theorems establish convergence between trajectories under the paper's Filippov and regularization assumptions.

### Evidence and computation
The paper is theoretical with numerical illustrations. It does not use the discrete-time cycle-map segment, endpoint induced norms, or radial dwell conditioning of our article.

### Relation to our article
This is general contraction background, not a direct foundation for the common-Lyapunov paragraph. It was verified and archived but intentionally omitted from `latex/article.tex` and `references.bib` because adding it would invite a Filippov or incremental-stability comparison that the article does not need.

### Safe citation use
Use it only if the manuscript later introduces general contraction or Filippov-system context. Do not cite it as support for the endpoint-norm bound or the scalar conditioner.

### Reading recommendation
**Read only the relevant sections initially.** Focus on the regularization construction and matrix-measure conditions if a broader contraction comparison becomes necessary.

# Cross-paper synthesis

## Method taxonomy

### 1. Fixed-period and periodic behavior

Marcolino et al. provide a fixed-period one-cycle prediction model for switched actuators. Flieller et al. compute hybrid limit cycles with switching-time sensitivities. Xu and Lazar use periodic terminal ingredients for FCS-MPC with a desired limit cycle. Hanke and Stursberg treat limit-cycle amplitude and frequency as design targets. These papers establish that periodic behavior is a legitimate control objective, but they use different control freedoms. Our article keeps the period and mode order fixed and changes interior switching instants.

### 2. Switching-time and schedule optimization

Yang et al. optimize fixed-frequency converter timing through an online QP. Sakha and Kamalapurkar filter switching times in a switched optimal-control workflow. Abbasi-Esfeden et al. jointly address sequence and switching-time optimization under dwell constraints. Repecho et al. regulate measured switching periods through hysteresis-band adaptation rather than direct schedule displacement. These methods are useful alternatives when the schedule or switching behavior must be redesigned. Our article deliberately solves a smaller problem: it takes a raw timing vector as given and finds the largest feasible scalar multiple along that vector.

### 3. Dwell-time enforcement and switched-system stability

Della Rossa et al. 2022 and 2023 provide stability certificates for constrained switching classes and switched-affine systems. Briat and Seuret give minimum and mode-dependent dwell-time conditions for uncertain linear switched systems. Russo et al. synthesize state-dependent switching laws with dwell time. Katz et al. adds sampled-data and observer structure. These works show that dwell time belongs in the stability problem, not only in a timer implementation. Their switching freedom differs from ours because they analyze or synthesize mode selection or admissible switching classes rather than fixed-order timing correction.

### 4. Lyapunov and LMI certification

Egidio et al., Della Rossa et al. 2023, Seuret et al., Russo et al., Katz et al., Monir et al., Briat and Seuret, and Fiore et al. use Lyapunov, LMI, Lyapunov–Metzler, data-driven, scenario-based, looped-functional, or matrix-measure arguments. The recurring lesson is that the certificate depends on the admissible switching family and uncertainty assumptions. Our paper's specific certificate is narrower: a common quadratic Lyapunov function for the nominal and raw endpoint cycle matrices certifies the line segment created by scalar conditioning in the linearized model.

### 5. Converter computation and constraints

Augustine et al., Saeed et al., Yang et al., Wu et al., Li et al., Singh et al., Sheng et al., and Stellato et al. show different ways to fit predictive or finite-control-set control into converter computation budgets. They prune candidates, reduce variables, simplify models or costs, tune MPC, improve numerical conditioning, distill a policy, or use short horizons with an offline tail-cost approximation. Albea-Sanchez et al. add hybrid-affine PWM converter modeling and Lyapunov analysis. These papers support the practical motivation for avoiding online optimization when a simpler feasibility mechanism is available. They do not establish our fixed-mode-order timing conditioner.

### 6. Application and evidence level

The archive contains experimental evidence from Repecho et al. and laboratory converter evidence from Yang et al., Saeed et al., Wu et al., and Li et al. The remaining reviewed material is theoretical, numerical, or simulation based. None of the 26 papers establishes industrial deployment or hardware-in-the-loop validation in the collected sources. The introduction should therefore say "industrially relevant" rather than "industrially deployed."

# Screening result

All 26 archived PDFs pass the inclusion rule because each has a direct connection to at least one review theme: periodic switched-affine control, switching-time or schedule optimization, dwell-time feasibility or stability, converter control with timing or computation constraints, or Lyapunov certification for switched or hybrid systems.

No papers were screened out, and no PDFs were deleted. The core/supporting labels indicate relevance to this paper's particular combination of cycle timing, dwell feasibility, switched-affine behavior, and stability certification. They are not quality rankings.

# Position of our article

The reviewed papers contain neighboring pieces of the problem:

- fixed-period switched-actuator modeling and dwell-constrained predictive control;
- hybrid limit-cycle computation and switching-time sensitivity;
- feedback regulation of measured switching periods through hysteresis-band adaptation;
- fast online switching-time optimization;
- schedule optimization under dwell constraints;
- state-dependent or sampled-data dwell-time stabilization;
- periodic and limit-cycle switched-affine control;
- hybrid-affine PWM converter modeling;
- converter methods that reduce online search or optimization;
- Lyapunov, LMI, looped-functional, and contraction certificates for constrained switched systems.

The review did not identify a method that combines all of the following in the same fixed-period, fixed-mode-order timing controller:

1. a cycle-to-cycle feedback law producing arbitrary raw switching-instant offsets;
2. a maximal scalar contraction that preserves the raw timing direction;
3. preservation of the two fixed cycle boundaries and all dwell constraints;
4. an O(N) online scan with no optimization solver; and
5. an offline common-quadratic certificate for the complete line segment of conditioned one-cycle linearized matrices.

This is a local and model-specific gap statement, not a claim that no related feasibility filters or switching-time projections exist. The paper should also keep its limits visible: the nonlinear result is local, the common-quadratic result concerns the linearized family, and the study does not establish hardware, HIL, global nonlinear stability, or industrial deployment.
