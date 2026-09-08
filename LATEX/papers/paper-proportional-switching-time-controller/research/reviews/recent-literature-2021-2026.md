# Recent literature for a funnel-shaped introduction, 2021–2026

## Scope and verification policy

This note covers 20 research articles and author preprints published from 2020 through 19 August 2026. It prioritizes publisher DOI records, publisher pages, and lawful author manuscripts. Reviews are not counted. Online-first and issue dates are stated when they differ.

"Verified" means that the article identity and bibliographic data were checked against a publisher or repository record, and the problem, method, or evidence statement below is supported by publisher material or the collected author manuscript. When the primary material did not establish whether an application was simulated or physical, the record says so rather than inferring hardware validation.

Evidence labels are used narrowly:

- **Industrial deployment:** operation in a production facility or fielded industrial system.
- **Laboratory hardware:** a physical converter, drive, or low-power system tested in a laboratory.
- **Hardware-in-the-loop:** a real-time controller or plant simulator closes the loop without the full physical plant.
- **Embedded implementation:** code executes on embedded hardware, but the collected source does not establish a complete physical-plant experiment.
- **Simulation or numerical example:** no physical plant is established.
- **Generic industrial motivation:** the paper names an industrial application but does not validate in an industrial installation.

No reviewed paper establishes genuine industrial deployment. Several report laboratory hardware, and one reports embedded implementation. None of the collected primary sources establishes hardware-in-the-loop validation. Industry affiliation, converter relevance, and use of the word "industrial" in a journal title are not treated as deployment.

## Strongest recent papers

### 1. Predictive control with switched actuators and dwell constraints

**Matheus Henrique Marcolino, Roberto Kawakami Harrop Galvão, and Karl Heinz Kienitz.** "Predictive Control of Linear Systems with Switched Actuators Subject to Dwell-Time Constraints." *Journal of Control, Automation and Electrical Systems*, 32(1), 1–17, 2021. [DOI and publisher record](https://doi.org/10.1007/s40313-020-00667-9).

- **Problem:** regulate linear plants actuated through a fixed-period sequence while respecting minimum dwell times. [Source](https://doi.org/10.1007/s40313-020-00667-9)
- **Method:** a one-cycle prediction model supports LQR and dwell-constrained model predictive control. The optimization treats admissible switching schedules explicitly. [Source](https://doi.org/10.1007/s40313-020-00667-9)
- **Evidence/application:** numerical converter-oriented examples; no laboratory hardware, HIL, or deployment is established by the collected primary source. [Source](https://doi.org/10.1007/s40313-020-00667-9)
- **Relevance or contrast:** this is the closest direct predecessor for fixed-period cycle models and dwell-constrained timing. The present paper instead conditions a raw timing action by one scalar and avoids an online optimization problem.

### 2. Stability under switching-frequency constraints

**Matteo Della Rossa, Mirko Pasquini, and David Angeli.** "Continuous-time switched systems with switching frequency constraints: Path-complete stability criteria." *Automatica*, 137, 110099, 2022. [DOI and publisher record](https://doi.org/10.1016/j.automatica.2021.110099).

- **Problem:** certify continuous-time switched-system stability when admissible signals obey switching-frequency restrictions. [Source](https://doi.org/10.1016/j.automatica.2021.110099)
- **Method:** path-complete Lyapunov criteria encode the constrained switching language. [Source](https://doi.org/10.1016/j.automatica.2021.110099)
- **Evidence/application:** theoretical and numerical validation; no physical converter, HIL, or deployment. [Source](https://doi.org/10.1016/j.automatica.2021.110099)
- **Relevance or contrast:** it supports the need to include switching restrictions in stability analysis. It certifies classes of switching signals rather than correcting cycle-to-cycle switching instants for a fixed mode order and period.

### 3. Rank-deficient switched-affine stabilization

**Lucas N. Egidio, Grace S. Deaecto, and Raphaël M. Jungers.** "Stabilization of rank-deficient continuous-time switched affine systems." *Automatica*, 143, 110426, 2022. [DOI and publisher record](https://doi.org/10.1016/j.automatica.2022.110426). [Author manuscript record](https://hdl.handle.net/2078.5/252130).

- **Problem:** globally stabilize a selected equilibrium when convex combinations of the mode matrices are rank deficient. [Author record and abstract](https://hdl.handle.net/2078.5/252130)
- **Method:** an LMI-based state-dependent switching function gives global asymptotic and local exponential stability under the paper's conditions. [Author record and abstract](https://hdl.handle.net/2078.5/252130)
- **Evidence/application:** a modeled DC-motor position and velocity-control application uses an H-bridge and boost converter with eight subsystems. The source calls it a practical application example but does not report physical hardware or deployment. [Author record and abstract](https://hdl.handle.net/2078.5/252130)
- **Relevance or contrast:** it demonstrates modern LMI-certified switched-affine feedback. Its controller selects modes from state, whereas the present paper preserves the prescribed mode order and adjusts switching instants once per cycle.

### 4. Arbitrary and dwell-time switching in affine systems

**Matteo Della Rossa, Lucas N. Egidio, and Raphaël M. Jungers.** "Stability of Switched Affine Systems: Arbitrary and Dwell-Time Switching." *SIAM Journal on Control and Optimization*, 61(4), 2165–2192, 2023. [DOI and publisher record](https://doi.org/10.1137/22M1482226).

- **Problem:** characterize set stability and boundedness of switched-affine systems under arbitrary and dwell-time switching. [Source](https://doi.org/10.1137/22M1482226)
- **Method:** Lyapunov, LMI, and sum-of-squares conditions provide computable certificates. [Source](https://doi.org/10.1137/22M1482226)
- **Evidence/application:** theoretical results with numerical examples; no hardware, HIL, or deployment. [Source](https://doi.org/10.1137/22M1482226)
- **Relevance or contrast:** it supplies recent dwell-time stability framing. The problem is admissible switching and set stability, not fixed-sequence periodic-orbit regulation through switching-time feedback.

### 5. Finite-control-set MPC with limit-cycle guarantees

**Duo Xu and Mircea Lazar.** "Finite Control Set Model Predictive Control with Limit Cycle Stability Guarantees." arXiv:2407.07615, 2024. [Author manuscript and PDF](https://arxiv.org/abs/2407.07615).

- **Problem:** design finite-control-set MPC for discrete-time switched-affine systems with a desired steady-state limit cycle. [Source](https://arxiv.org/abs/2407.07615)
- **Method:** periodic terminal costs and terminal sets provide recursive-feasibility and asymptotic-stability conditions. [Source](https://arxiv.org/abs/2407.07615)
- **Evidence/application:** switched-system and power-electronics benchmarks; no industrial deployment is established. [Source](https://arxiv.org/abs/2407.07615)
- **Relevance or contrast:** it directly supports periodic switched-affine control and limit-cycle stability. It uses FCS-MPC and terminal ingredients, while the present paper updates switching instants through static cycle-to-cycle feedback.

### 6. Practically stabilizing MPC for switched-affine systems

**Midhun T. Augustine and Deepak U. Patil.** "A Practically Stabilizing Model Predictive Control Scheme for Switched Affine Systems." *IEEE Control Systems Letters*, 7, 625–630, 2023, published online in 2022. [DOI and publisher record](https://doi.org/10.1109/LCSYS.2022.3210368).

- **Problem:** reduce the online burden of stabilizing MPC for switched-affine systems. [Source](https://doi.org/10.1109/LCSYS.2022.3210368)
- **Method:** candidate pruning and cost approximation reduce the search while retaining a practical-stability result. [Source](https://doi.org/10.1109/LCSYS.2022.3210368)
- **Evidence/application:** converter simulation; no laboratory hardware, HIL, or deployment. [Source](https://doi.org/10.1109/LCSYS.2022.3210368)
- **Relevance or contrast:** it confirms that online complexity is a central design issue. Its answer remains an approximate MPC search; the present paper uses a solver-free linear scan after the raw feedback action is computed.

### 7. Limit cycles of planar switching-affine systems

**Nils Hanke and Olaf Stursberg.** "On the Design of Limit Cycles of Planar Switching Affine Systems." arXiv:2303.16505, 2023. [Author manuscript and PDF](https://arxiv.org/abs/2303.16505).

- **Problem:** design stable limit cycles in planar switching-affine systems with specified oscillation properties. [Source](https://arxiv.org/abs/2303.16505)
- **Method:** the paper selects switching-affine phase portraits to obtain desired oscillation amplitudes and frequencies. [Source](https://arxiv.org/abs/2303.16505)
- **Evidence/application:** theoretical design and numerical examples; no physical hardware or deployment is established. [Source](https://arxiv.org/abs/2303.16505)
- **Relevance or contrast:** it supports periodic switching and limit-cycle design as recent goals. It designs the phase portrait, whereas the present paper preserves a prescribed mode order and conditions timing feedback.

### 8. Data-driven stabilization of switched-affine systems

**Alexandre Seuret, Carolina Albea, and Francisco Gordillo.** "LMI Relaxations and Its Application to Data-Driven Control Design for Switched Affine Systems." arXiv:2302.11923, 2023. [Author manuscript and PDF](https://arxiv.org/abs/2302.11923).

- **Problem:** design control for uncertain switched-affine systems using data and LMI relaxations. [Source](https://arxiv.org/abs/2302.11923)
- **Method:** data-dependent matrix conditions support Lyapunov-based design for robust hybrid behavior. [Source](https://arxiv.org/abs/2302.11923)
- **Evidence/application:** theoretical results and examples; no physical hardware or deployment is established. [Source](https://arxiv.org/abs/2302.11923)
- **Relevance or contrast:** it connects recent switched-affine stabilization with limited model knowledge and LMI certificates. Its controller addresses data-driven uncertainty, while the present paper focuses on timing feasibility for a fixed sequence.

### 9. Dwell-time constrained switched optimal control

**Masoud S. Sakha and Rushikesh Kamalapurkar.** "Switched Optimal Control with Dwell Time Constraints." arXiv:2501.05548, 2025. [Author manuscript and PDF](https://arxiv.org/abs/2501.05548).

- **Problem:** solve switched optimal-control problems while enforcing minimum dwell times. [Source](https://arxiv.org/abs/2501.05548)
- **Method:** continuous optimization is combined with a filter that removes switching times violating dwell constraints. [Source](https://arxiv.org/abs/2501.05548)
- **Evidence/application:** numerical examples; no physical hardware, HIL, or industrial deployment is established. [Source](https://arxiv.org/abs/2501.05548)
- **Relevance or contrast:** it provides a direct recent comparison for dwell-time filtering and switching-time optimization. The present paper computes a maximal scalar contraction analytically instead of solving an optimization problem.

### 10. State-dependent affine stabilization with dwell time

**Antonio Russo, Gian Paolo Incremona, and Patrizio Colaneri.** "Stabilization of Switched Affine Systems With Dwell-Time Constraint." *IEEE Transactions on Automatic Control*, 71(5), 3030–3043, 2026, published online in 2025. [DOI and publisher record](https://doi.org/10.1109/TAC.2025.3634172). [Author manuscript](https://re.public.polimi.it/bitstream/11311/1307779/1/sas_dwell_time_TAC_pub.pdf).

- **Problem:** stabilize switched-affine systems while enforcing a minimum dwell time. [Author manuscript](https://re.public.polimi.it/bitstream/11311/1307779/1/sas_dwell_time_TAC_pub.pdf)
- **Method:** state-switching laws use differential Lyapunov equations and Lyapunov–Metzler inequalities, with quadratic-cost bounds. [Author manuscript](https://re.public.polimi.it/bitstream/11311/1307779/1/sas_dwell_time_TAC_pub.pdf)
- **Evidence/application:** three numerical examples; no physical hardware, HIL, or industrial deployment. [Author manuscript](https://re.public.polimi.it/bitstream/11311/1307779/1/sas_dwell_time_TAC_pub.pdf)
- **Relevance or contrast:** it is a current dwell-time stabilization benchmark. It synthesizes state-dependent switching laws, whereas the present paper conditions a fixed-sequence timing action and certifies the conditioned one-cycle matrices.

### 11. Mixed-integer switching optimization under dwell constraints

**Ramin Abbasi-Esfeden, Armin Nurkanovic, Moritz Diehl, Panagiotis Patrinos, and Jan Swevers.** "An Efficient Mixed-Integer Formulation and an Iterative Method for Optimal Control of Switched Systems Under Dwell Time Constraints." arXiv:2501.05158, 2025. [Author manuscript and PDF](https://arxiv.org/abs/2501.05158).

- **Problem:** optimize switched-system schedules and switching times under dwell-time constraints. [Source](https://arxiv.org/abs/2501.05158)
- **Method:** the formulation separates sequence optimization from switching-time optimization and limits binary-variable growth with the discretization grid. [Source](https://arxiv.org/abs/2501.05158)
- **Evidence/application:** algorithmic and numerical examples; no converter hardware or deployment is established. [Source](https://arxiv.org/abs/2501.05158)
- **Relevance or contrast:** it is a direct comparison for online schedule optimization and computational burden. The present method retains a fixed sequence and uses a scalar feasibility scan instead of mixed-integer optimization.

### 12. Stability-constrained control in variable-inertia power grids

**Jie Feng, Manasa Muralidharan, Rodrigo Henriquez-Auba, Patricia Hidalgo-Gonzalez, and Yuanyuan Shi.** "Stability-Constrained Learning for Frequency Regulation in Power Grids with Variable Inertia." arXiv:2405.20489, 2024. [Author manuscript and PDF](https://arxiv.org/abs/2405.20489).

- **Problem:** regulate frequency in a converter-rich power-grid model with variable inertia while maintaining stability. [Source](https://arxiv.org/abs/2405.20489)
- **Method:** a switched-affine hybrid model and quadratic stability certificate constrain a computationally tractable learning controller. [Source](https://arxiv.org/abs/2405.20489)
- **Evidence/application:** simulation and numerical comparisons; no physical hardware or deployment is established. [Source](https://arxiv.org/abs/2405.20489)
- **Relevance or contrast:** it represents a stability-constrained, computation-aware control route in a converter-rich application. It learns a state-feedback policy, whereas the present paper conditions timing feedback for a fixed mode order.

### 13. Fixed-frequency direct MPC with a fast custom solver

**Qifan Yang, Petros Karamanakos, Wei Tian, Xiaonan Gao, Xinyue Li, Tobias Geyer, and Ralph Kennel.** "Computationally Efficient Fixed Switching Frequency Direct Model Predictive Control." *IEEE Transactions on Power Electronics*, 37(3), 2761–2777, 2022, published online in 2021. [DOI and publisher record](https://doi.org/10.1109/TPEL.2021.3114979).

- **Problem:** obtain direct predictive control at fixed switching frequency without missing the short timing budget of power-converter control. [Source](https://doi.org/10.1109/TPEL.2021.3114979)
- **Method:** switching instants are optimized through a constrained quadratic program using a custom solver, early termination, and few-microsecond execution. [Source](https://doi.org/10.1109/TPEL.2021.3114979)
- **Evidence/application:** experiments on a 3 kW two-level inverter and induction-machine drive. This is laboratory hardware. Industry-affiliated authors do not make it industrial deployment. [Source](https://doi.org/10.1109/TPEL.2021.3114979)
- **Relevance or contrast:** it strongly supports fixed-frequency timing control and the need for bounded online computation. The comparison is a fast online QP versus the present paper's solver-free timing correction.

### 14. Reduced-variable MPC for a phase-shift full-bridge converter

**Junaid Saeed, Liuping Wang, and Nuwantha Fernando.** "Model Predictive Control of Phase Shift Full-Bridge DC–DC Converter Using Laguerre Functions." *IEEE Transactions on Control Systems Technology*, 30(2), 819–826, 2022, published online in 2021. [DOI and publisher record](https://doi.org/10.1109/TCST.2021.3069148).

- **Problem:** control a phase-shift full-bridge DC–DC converter while enforcing a nonlinear peak-current constraint within a short sampling period. [Source](https://doi.org/10.1109/TCST.2021.3069148)
- **Method:** Laguerre parameterization reduces the number of MPC decision variables. [Source](https://doi.org/10.1109/TCST.2021.3069148)
- **Evidence/application:** a 60 W laboratory converter with 40 μs sampling. This is a laboratory prototype, not deployment. [Source](https://doi.org/10.1109/TCST.2021.3069148)
- **Relevance or contrast:** it shows that converter constraints can be handled on embedded time scales by reducing optimization dimension. The present paper uses an analytic dwell-feasibility contraction rather than a reduced MPC problem.

### 15. Neural policy distillation for long-horizon FCS-MPC

**Jinjian Sheng, Kazumune Hashimoto, Shuang Zhao, and Mahdieh S. Sadabadi.** "Robust Neural Policy Distillation of Long-Horizon FCS-MPC for Flying-Capacitor Three-Level Boost Converters." arXiv:2604.11192, 2026. [Author manuscript and PDF](https://arxiv.org/abs/2604.11192).

- **Problem:** reduce the computational burden of long-horizon finite-control-set MPC for a flying-capacitor converter. [Source](https://arxiv.org/abs/2604.11192)
- **Method:** beam-search expert trajectories are distilled into a neural policy and relabeled using disagreement under randomized operating conditions. [Source](https://arxiv.org/abs/2604.11192)
- **Evidence/application:** converter simulations and robustness tests; no industrial deployment is established. [Source](https://arxiv.org/abs/2604.11192)
- **Relevance or contrast:** it supports sequence-search reduction as an embedded-control concern. Its learned policy replaces online FCS-MPC search, while the present paper retains static timing feedback and enforces dwell feasibility analytically.

### 16. Exponentially weighted MPC for modular multilevel converters

**Sunny Singh, Saurabh Mishra, Dušan M. Stipanović, and Aleksandra Lekić.** "Exponential Weighting Model Predictive Control with Observer for Modular Multilevel Converters." arXiv:2606.16631, 2026. [Author manuscript and PDF](https://arxiv.org/abs/2606.16631).

- **Problem:** control an MMC with long-horizon MPC while managing numerical conditioning and plant or control constraints. [Source](https://arxiv.org/abs/2606.16631)
- **Method:** exponential cost weighting and an observer improve long-horizon conditioning, with closed-loop stability analysis. [Source](https://arxiv.org/abs/2606.16631)
- **Evidence/application:** MMC simulations and numerical analysis; no physical hardware or deployment is established. [Source](https://arxiv.org/abs/2606.16631)
- **Relevance or contrast:** it supports the converter funnel's emphasis on constrained, computation-aware predictive control. It remains an online MPC method, while the present paper uses a solver-free timing conditioner.

### 17. Data-driven finite-control-set MPC for an MMC

**Wenjie Wu, Lin Qiu, Jose Rodriguez, Xing Liu, Jien Ma, and Youtong Fang.** "Data-Driven Finite Control-Set Model Predictive Control for Modular Multilevel Converter." *IEEE Journal of Emerging and Selected Topics in Power Electronics*, 11(1), 523–531, 2023, published online in 2022. [DOI and publisher record](https://doi.org/10.1109/JESTPE.2022.3207454).

- **Problem:** apply finite-control-set MPC to an MMC without relying on an accurate converter model and without an excessive online cost. [Source](https://doi.org/10.1109/JESTPE.2022.3207454)
- **Method:** model-free adaptive control is embedded in FCS-MPC with a simplified cost function. [Source](https://doi.org/10.1109/JESTPE.2022.3207454)
- **Evidence/application:** simulation and laboratory experiment; no industrial deployment. [Source](https://doi.org/10.1109/JESTPE.2022.3207454)
- **Relevance or contrast:** it supports the application funnel's claim that model burden and online search both matter in MMC control. It addresses model uncertainty, whereas the present paper relies on a switched-affine one-cycle linearization and focuses on timing feasibility and local certification.

### 18. Stability-oriented MPC design for a boost converter

**Yuan Li, Subham Sahoo, Tomislav Dragičević, Yichao Zhang, and Frede Blaabjerg.** "Stability-Oriented Design of Model Predictive Control for DC/DC Boost Converter." *IEEE Transactions on Industrial Electronics*, 71(1), 922–932, 2024, published online in 2023. [DOI and publisher record](https://doi.org/10.1109/TIE.2023.3247785). [Author manuscript](https://vbn.aau.dk/ws/files/515389854/Stability_Oriented_Design_of_Model_Predictive.pdf).

- **Problem:** design fixed-frequency boost-converter MPC with explicit attention to closed-loop stability and nonminimum-phase behavior. [Author manuscript](https://vbn.aau.dk/ws/files/515389854/Stability_Oriented_Design_of_Model_Predictive.pdf)
- **Method:** a single-horizon formulation and Jacobian-based guidance choose weighting parameters to improve stability behavior. [Author manuscript](https://vbn.aau.dk/ws/files/515389854/Stability_Oriented_Design_of_Model_Predictive.pdf)
- **Evidence/application:** laboratory experimental validation; no industrial deployment. [Author manuscript](https://vbn.aau.dk/ws/files/515389854/Stability_Oriented_Design_of_Model_Predictive.pdf)
- **Relevance or contrast:** it supports the need to pair computationally practical converter control with a stability argument. Its stability guidance tunes MPC; the present paper certifies the complete conditioned cycle-map segment offline.

### 19. Sampled-data switched-system stabilization with dwell time

**Rami Katz, Antonio Russo, Gian Paolo Incremona, Patrizio Colaneri, and Giulia Giordano.** "Observer-Based Sampled-Data Stabilisation of Switched Systems with Lipschitz Nonlinearities and Dwell-Time." arXiv:2511.01672, 2026 version. [Author manuscript and PDF](https://arxiv.org/abs/2511.01672).

- **Problem:** stabilize switched systems from sampled measurements while enforcing dwell-time restrictions. [Source](https://arxiv.org/abs/2511.01672)
- **Method:** observer-based switching and Lyapunov–Metzler/LMI conditions provide stability or ultimate-boundedness results. [Source](https://arxiv.org/abs/2511.01672)
- **Evidence/application:** theoretical and numerical examples; no physical hardware or deployment is established. [Source](https://arxiv.org/abs/2511.01672)
- **Relevance or contrast:** it supports the role of sampling, dwell time, and offline stability certificates. Its switching law is observer-based, whereas the present paper preserves a prescribed mode order and conditions timing offsets.

### 20. Robust scenario control of uncertain switched-affine systems

**Negar Monir, Mahdieh S. Sadabadi, and Sadegh Soudjani.** "Robust Control of Uncertain Switched Affine Systems via Scenario Optimization." arXiv:2505.06943, 2025. [Author manuscript and PDF](https://arxiv.org/abs/2505.06943).

- **Problem:** design robust switching laws for uncertain switched-affine systems. [Source](https://arxiv.org/abs/2505.06943)
- **Method:** data-driven scenario optimization and quadratic Lyapunov functions produce robust invariant sets and reduce regulation error or chattering. [Source](https://arxiv.org/abs/2505.06943)
- **Evidence/application:** numerical examples include power-electronic converters; no physical hardware or deployment is established. [Source](https://arxiv.org/abs/2505.06943)
- **Relevance or contrast:** it represents robust optimization under model uncertainty and includes a converter application. The present paper does not solve a robust scenario problem; it conditions a timing action and certifies the linearized family through a common quadratic Lyapunov function.

## Evidence summary

| Evidence class | Papers | Count |
|---|---:|---:|
| Genuine industrial deployment | None | 0 |
| Laboratory hardware | Yang et al.; Saeed et al.; Wu et al.; Li et al. | 4 |
| Hardware-in-the-loop | None established | 0 |
| Embedded implementation without a verified full-plant experiment | None established | 0 |
| Simulation, numerical, or theoretical evidence only | Marcolino et al.; Della Rossa et al. 2022; Egidio et al.; Della Rossa et al. 2023; Augustine and Patil; Xu and Lazar; Hanke and Stursberg; Seuret et al.; Sakha and Kamalapurkar; Russo et al.; Abbasi-Esfeden et al.; Feng et al.; Sheng et al.; Singh et al.; Katz et al.; Monir et al. | 16 |

The evidence classifications and counts follow the cited primary records in the 20 entries above. The replacement set is mostly theoretical or simulation-based because its lawful full texts are author preprints. The four laboratory-hardware records are retained from the original set: Yang et al., Saeed et al., Wu et al., and Li et al. The replacement papers do not establish industrial deployment or hardware-in-the-loop validation.

## Funnel outline for the introduction

### 1. Start with converter and switched-control relevance

Power converters, electric drives, and microgrid interfaces are controlled by discrete switch configurations whose timing determines current, voltage, balancing, and switching behavior. Recent work covers DC–DC converters, multilevel converters, and converter-rich power-grid models, which is enough to establish application relevance without claiming field deployment. [Saeed et al.](https://doi.org/10.1109/TCST.2021.3069148), [Yang et al.](https://doi.org/10.1109/TPEL.2021.3114979), [Sheng et al.](https://arxiv.org/abs/2604.11192), [Feng et al.](https://arxiv.org/abs/2405.20489).

Suggested move: describe these systems as industrially relevant, then state plainly that the recent evidence reviewed here is mainly simulation and laboratory validation, not deployed industrial operation.

### 2. Narrow to application-driven converter constraints

Converter controllers must coordinate switch states or sequences, fixed-frequency operation, current and capacitor objectives, and physical input limits. Recent work handles these requirements through constrained QPs, finite-control-set searches, policy distillation, observer-based MPC, and reduced models. [Yang et al.](https://doi.org/10.1109/TPEL.2021.3114979), [Sheng et al.](https://arxiv.org/abs/2604.11192), [Singh et al.](https://arxiv.org/abs/2606.16631), [Wu et al.](https://doi.org/10.1109/JESTPE.2022.3207454).

### 3. Explain why online computation remains a design constraint

The application papers repeatedly reduce decision variables, prune candidates, restrict sequences, identify smaller models, or implement custom solvers. This repeated engineering work shows that constraint handling is useful only if it fits the switching and sampling budget. [Saeed et al.](https://doi.org/10.1109/TCST.2021.3069148), [Augustine and Patil](https://doi.org/10.1109/LCSYS.2022.3210368), [Yang et al.](https://doi.org/10.1109/TPEL.2021.3114979), [Sheng et al.](https://arxiv.org/abs/2604.11192), [Sakha and Kamalapurkar](https://arxiv.org/abs/2501.05548).

### 4. Move from converter implementation to periodic switched-affine behavior

Periodic trajectories and hybrid limit cycles are explicit recent control targets for switched-affine systems, not merely side effects of switching. Recent methods use finite-control-set MPC with periodic terminal ingredients, planar switching-affine cycle design, and data-driven LMI conditions. [Xu and Lazar](https://arxiv.org/abs/2407.07615), [Hanke and Stursberg](https://arxiv.org/abs/2303.16505), [Seuret et al.](https://arxiv.org/abs/2302.11923).

### 5. Introduce switching instants as control variables

Switching-time optimization treats switching instants as continuous decisions, including mixed-integer schedules under dwell constraints. Fixed-frequency converter MPC also optimizes switching instants directly. [Abbasi-Esfeden et al.](https://arxiv.org/abs/2501.05158), [Sakha and Kamalapurkar](https://arxiv.org/abs/2501.05548), [Yang et al.](https://doi.org/10.1109/TPEL.2021.3114979).

Then separate two ideas that are often conflated: optimizing a complete schedule online and applying a static cycle-to-cycle timing correction. The present paper belongs to the second class.

### 6. Narrow to dwell-time feasibility and certification

Recent dwell-time work follows three main routes: certify stability for restricted switching languages, synthesize state-dependent mode laws that obey dwell time, or optimize schedules subject to dwell constraints. [Della Rossa et al. 2022](https://doi.org/10.1016/j.automatica.2021.110099), [Della Rossa et al. 2023](https://doi.org/10.1137/22M1482226), [Marcolino et al.](https://doi.org/10.1007/s40313-020-00667-9), [Russo et al.](https://re.public.polimi.it/bitstream/11311/1307779/1/sas_dwell_time_TAC_pub.pdf), [Abbasi-Esfeden et al.](https://arxiv.org/abs/2501.05158), [Sakha and Kamalapurkar](https://arxiv.org/abs/2501.05548).

This creates the final opening for the paper: a controller can preserve a prescribed period and mode direction while enforcing dwell feasibility by contracting only the magnitude of the requested timing action.

## Conservative gap statement

Among the 20 reviewed papers, none clearly combines all of the following in one method:

1. a fixed-period, fixed-mode-order, cycle-to-cycle switching-instant feedback law;
2. a maximal scalar correction of an arbitrary raw timing action that preserves its direction and preserves the cycle period;
3. an `O(N)` online feasibility scan with no online optimization solver; and
4. an offline common-quadratic certificate for the complete line segment of conditioned one-cycle linearized matrices.

The literature contains each neighboring idea separately. Fixed-period dwell-constrained MPC appears in Marcolino et al.; fast online switching-time QPs appear in Yang et al.; schedule optimization under dwell constraints appears in Abbasi-Esfeden et al. and Sakha and Kamalapurkar; state-dependent dwell-time stabilization appears in Russo et al.; and periodic or limit-cycle affine control appears in Xu and Lazar, Hanke and Stursberg, and Seuret et al. [Marcolino et al.](https://doi.org/10.1007/s40313-020-00667-9), [Yang et al.](https://doi.org/10.1109/TPEL.2021.3114979), [Abbasi-Esfeden et al.](https://arxiv.org/abs/2501.05158), [Sakha and Kamalapurkar](https://arxiv.org/abs/2501.05548), [Russo et al.](https://doi.org/10.1109/TAC.2025.3634172), [Xu and Lazar](https://arxiv.org/abs/2407.07615), [Hanke and Stursberg](https://arxiv.org/abs/2303.16505), [Seuret et al.](https://arxiv.org/abs/2302.11923).

A defensible introduction should therefore say "among the reviewed papers, this combination was not found" rather than claim an absolute first. The claim should remain local and model-specific. The paper's evidence is exact nonlinear simulation, not hardware, HIL, global nonlinear stability, or industrial deployment.

## Older foundational context, not included in the count

These works can establish lineage without displacing the recent literature:

- **D. Patiño, P. Riedinger, and F. Ruiz,** "A Predictive Control Approach for DC–DC Power Converters and Cyclic Switched Systems," *2010 IEEE International Conference on Industrial Technology*, 1259–1264. Use it for cyclic converter prediction and schedule-based control. [IEEE publisher search](https://ieeexplore.ieee.org/search/searchresult.jsp?queryText=A%20Predictive%20Control%20Approach%20for%20DC-DC%20Power%20Converters%20and%20Cyclic%20Switched%20Systems)
- **M. Benmiloud, A. Benalia, M. Djemai, and M. Defoort,** "On the Local Stabilization of Hybrid Limit Cycles in Switched Affine Systems," *IEEE Transactions on Automatic Control*, 64(2), 841–846, 2019. Use it for local hybrid-limit-cycle stabilization. [IEEE publisher search](https://ieeexplore.ieee.org/search/searchresult.jsp?queryText=On%20the%20Local%20Stabilization%20of%20Hybrid%20Limit%20Cycles%20in%20Switched%20Affine%20Systems)
- **L. N. Egidio, H. R. Daiha, and G. S. Deaecto,** "Global Asymptotic Stability of Limit Cycle and H2/H∞ Performance of Discrete-Time Switched Affine Systems," *Automatica*, 116, 108927, 2020. Use it for affine limit-cycle stability and performance. [Publisher DOI](https://doi.org/10.1016/j.automatica.2020.108927)
- **S. Boyd, L. El Ghaoui, E. Feron, and V. Balakrishnan,** *Linear Matrix Inequalities in System and Control Theory*, SIAM, 1994. Use it only for standard LMI and common-quadratic background. [Publisher DOI](https://doi.org/10.1137/1.9781611970777)

## Introduction-writing cautions

- Say **industrially relevant applications**, not **industrial deployment**. The reviewed evidence is mostly numerical or laboratory scale.
- Describe the contribution as a **combination and specialization** of cycle timing feedback, analytic dwell enforcement, low online cost, and segment certification.
- Do not claim a new switching sensitivity formula, timing coordinate system, LQR method, MPC method, global nonlinear theorem, or hardware demonstration.
- Keep the stability claim local to the nonlinear periodic orbit and tied to the conditioned one-cycle linearization and the paper's stated regularity assumptions.
- Present maximal scalar contraction precisely: maximal along the requested timing direction under the dwell constraints, not globally optimal among all feasible timing changes.
