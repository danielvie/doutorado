# Open replacement candidates, 2020–2026

**Checked:** 2026-08-19  
**Purpose:** Ten distinct, lawful, directly downloadable full-text papers that can replace inaccessible literature records in `paper-proportional-switching-time-controller` while preserving its main themes: switched/switched-affine stability and dwell time; periodic or hybrid converter control; switching-time or schedule optimization; computationally efficient MPC; and converter/MMC constraints or sequence reduction.

## Scope and verification

- The 20 excluded records supplied for this search were not selected: `marcolino2021`, `dellarossa2022frequency`, `egidio2022rank`, `dellarossa2023stability`, `ma2023periodic`, `augustine2023mpc`, `albea2024limit`, `deaecto2024tracking`, `ghawash2025embedded`, `russo2026dwell`, `zhu2023switching`, `peng2024robust`, `yang2022fixed`, `saeed2022laguerre`, `zhang2023sequence`, `jayan2023multilevel`, `wu2023datadriven`, `li2024stability`, `gao2024constraints`, and `raja2024sparse`.
- Every source below is the official arXiv record and its arXiv PDF endpoint. This is an author-uploaded open-access repository source, not a paywalled mirror or an unauthorized copy.
- Each landing page was checked for the exact title, author list, arXiv identifier, submission/version date, and the presence of a PDF link. Each PDF URL was then requested with redirects followed; all ten returned HTTP `200` with `Content-Type: application/pdf`.
- The year below is the arXiv publication/submission year, except where a later version is explicitly noted. These are therefore arXiv preprints unless the landing-page comments explicitly mention a publication status; no unverified journal publication is claimed.
- The arXiv-issued DOI form is included where useful: `10.48550/arXiv.<identifier>`.

## Candidate overview

| Key | Year | Primary identifier | Main replacement theme |
|---|---:|---|---|
| `switchedOptimalDwell2025` | 2025 | arXiv:2501.05548 | Dwell-constrained switched optimal control and switching-time filtering |
| `abbasiEsfeden2025dwell` | 2025 | arXiv:2501.05158 | Sequence optimization plus switching-time optimization with few binary variables |
| `xu2024fcsLimitCycle` | 2024 | arXiv:2407.07615 | FCS-MPC, periodic terminal ingredients, and limit-cycle stability |
| `seuret2023dataDrivenAffine` | 2023 | arXiv:2302.11923 | LMI/data-driven stabilization of uncertain switched-affine systems |
| `hanke2023planarLimitCycles` | 2023 | arXiv:2303.16505 | Design of stable periodic trajectories in planar switching-affine systems |
| `feng2024variableInertia` | 2024 | arXiv:2405.20489 | Switched-affine converter-rich power-grid control with stability certificates |
| `katz2026sampledDwell` | 2026 version; v1 in 2025 | arXiv:2511.01672v2 | Sampled-data output feedback, dwell time, and switched-system LMIs |
| `singh2026mmcExponentialMpc` | 2026 | arXiv:2606.16631 | Constraint-aware, numerically conditioned MPC for MMCs |
| `sheng2026neuralFcsMpc` | 2026 | arXiv:2604.11192 | Computational reduction of long-horizon FCS-MPC sequence search |
| `monir2025scenarioSwitchedAffine` | 2025 | arXiv:2505.06943 | Robust switched-affine control under uncertainty and converter applications |

## Detailed records

### 1. `switchedOptimalDwell2025`

- **Full title:** *Switched Optimal Control with Dwell Time Constraints*
- **Authors:** Masoud S. Sakha; Rushikesh Kamalapurkar
- **Year:** 2025; submitted to arXiv on 9 January 2025
- **Journal/identifier:** arXiv preprint, arXiv:2501.05548 [math.OC]; arXiv-issued DOI `10.48550/arXiv.2501.05548`
- **Direct PDF:** <https://arxiv.org/pdf/2501.05548>
- **Primary landing page:** <https://arxiv.org/abs/2501.05548>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page title is identical to the title above and lists Sakha and Kamalapurkar. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Direct replacement for the dwell-time/switching-time theme. The paper embeds the switching signal in a continuous optimization problem, adds a mechanism to promote feasible bang-bang switching, and uses a filter layer to remove switching times that violate dwell-time constraints. It is useful for motivating admissibility filtering and the distinction between optimizing switching times and enforcing minimum dwell time.

### 2. `abbasiEsfeden2025dwell`

- **Full title:** *An Efficient Mixed-Integer Formulation and an Iterative Method for Optimal Control of Switched Systems Under Dwell Time Constraints*
- **Authors:** Ramin Abbasi-Esfeden; Armin Nurkanovic; Moritz Diehl; Panagiotis Patrinos; Jan Swevers
- **Year:** 2025; submitted to arXiv on 9 January 2025
- **Journal/identifier:** arXiv preprint, arXiv:2501.05158 [math.OC]; arXiv-issued DOI `10.48550/arXiv.2501.05158`
- **Direct PDF:** <https://arxiv.org/pdf/2501.05158>
- **Primary landing page:** <https://arxiv.org/abs/2501.05158>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page title and five-author list match this record. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Strong replacement for schedule optimization and computational efficiency. It explicitly decomposes the problem into sequence optimization and switching-time optimization, while restricting the feasible sequence search so the number of binary variables does not grow with the number of discretization nodes. The iterative method is relevant to real-time or reduced-computation switching schedule design.

### 3. `xu2024fcsLimitCycle`

- **Full title:** *Finite Control Set Model Predictive Control with Limit Cycle Stability Guarantees*
- **Authors:** Duo Xu; Mircea Lazar
- **Year:** 2024; submitted to arXiv on 10 July 2024
- **Journal/identifier:** arXiv preprint, arXiv:2407.07615 [math.OC]; arXiv-issued DOI `10.48550/arXiv.2407.07615`
- **Direct PDF:** <https://arxiv.org/pdf/2407.07615>
- **Primary landing page:** <https://arxiv.org/abs/2407.07615>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page title and author list match this record. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Strong replacement for periodic switched-converter control and limit-cycle stability. It designs FCS-MPC for discrete-time switched-affine systems, uses periodic terminal costs and terminal sets, provides recursive-feasibility and asymptotic-stability conditions for a desired steady-state limit cycle, and validates the approach on switched-system and power-electronics benchmarks.

### 4. `seuret2023dataDrivenAffine`

- **Full title:** *LMI relaxations and its application to data-driven control design for switched affine systems*
- **Authors:** Alexandre Seuret; Carolina Albea; Francisco Gordillo
- **Year:** 2023; submitted to arXiv on 23 February 2023
- **Journal/identifier:** arXiv preprint, arXiv:2302.11923 [eess.SY]; arXiv-issued DOI `10.48550/arXiv.2302.11923`
- **Direct PDF:** <https://arxiv.org/pdf/2302.11923>
- **Primary landing page:** <https://arxiv.org/abs/2302.11923>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page preserves the lower-case title wording and lists Seuret, Albea, and Gordillo. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Replacement for switched-affine stability and data-driven/hybrid control analysis. It derives data-dependent matrix conditions and applies Lyapunov-based design to robust hybrid limit cycles for uncertain switched-affine systems. It supports a literature link between LMI relaxations, limited model knowledge, and stabilization of periodic hybrid behavior.

### 5. `hanke2023planarLimitCycles`

- **Full title:** *On the Design of Limit Cycles of Planar Switching Affine Systems*
- **Authors:** Nils Hanke; Olaf Stursberg
- **Year:** 2023; submitted to arXiv on 29 March 2023
- **Journal/identifier:** arXiv preprint, arXiv:2303.16505 [eess.SY]; arXiv-issued DOI `10.48550/arXiv.2303.16505`. The landing page comments that the paper was accepted at ECC 2022; the report does not infer any additional journal publication.
- **Direct PDF:** <https://arxiv.org/pdf/2303.16505>
- **Primary landing page:** <https://arxiv.org/abs/2303.16505>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page title and two-author list match this record. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Replacement for periodic switching, limit-cycle generation, and frequency/amplitude specification. It studies stable limit cycles in planar switching-affine systems and gives a design method for selecting phase portraits from desired oscillation amplitudes and frequencies. This is useful for framing periodic switching as a trajectory-design problem rather than only a regulation problem.

### 6. `feng2024variableInertia`

- **Full title:** *Stability-Constrained Learning for Frequency Regulation in Power Grids with Variable Inertia*
- **Authors:** Jie Feng; Manasa Muralidharan; Rodrigo Henriquez-Auba; Patricia Hidalgo-Gonzalez; Yuanyuan Shi
- **Year:** 2024; submitted to arXiv on 30 May 2024, revised 11 June 2024
- **Journal/identifier:** arXiv preprint, arXiv:2405.20489 [eess.SY]; arXiv-issued DOI `10.48550/arXiv.2405.20489`. The landing page comments that it is to appear in *IEEE Control Systems Letters*; no journal publication is asserted here without a primary published record.
- **Direct PDF:** <https://arxiv.org/pdf/2405.20489>
- **Primary landing page:** <https://arxiv.org/abs/2405.20489>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page title and five-author list match this record. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Replacement for switched-affine modeling and computationally tractable stability-constrained control in converter-rich power systems. It models time-varying inertia with a switched-affine hybrid system, supplies a quadratic stability certificate, and compares a real-time-tractable controller against linear and finite-horizon LQR baselines.

### 7. `katz2026sampledDwell`

- **Full title:** *Observer-Based Sampled-Data Stabilisation of Switched Systems with Lipschitz Nonlinearities and Dwell-Time*
- **Authors:** Rami Katz; Antonio Russo; Gian Paolo Incremona; Patrizio Colaneri; Giulia Giordano
- **Year:** 2026 version; arXiv v1 submitted 3 November 2025 and v2 submitted 28 April 2026
- **Journal/identifier:** arXiv preprint, arXiv:2511.01672v2 [math.OC]; arXiv-issued DOI `10.48550/arXiv.2511.01672`
- **Direct PDF:** <https://arxiv.org/pdf/2511.01672>
- **Primary landing page:** <https://arxiv.org/abs/2511.01672>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The current landing page title, five authors, and v2 date match this record. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Replacement for dwell-time stability analysis with sampled measurements and output feedback. It develops Lyapunov–Metzler/LMI conditions for sampled-data switching, including global asymptotic stability for switched systems with Lipschitz nonlinearities and ultimate boundedness for switched-affine terms. It broadens the paper’s stability context beyond full-state continuous-time switching.

### 8. `singh2026mmcExponentialMpc`

- **Full title:** *Exponential Weighting Model Predictive Control with Observer for Modular Multilevel Converters*
- **Authors:** Sunny Singh; Saurabh Mishra; Dušan M. Stipanović; Aleksandra Lekić
- **Year:** 2026; submitted to arXiv on 15 June 2026
- **Journal/identifier:** arXiv preprint, arXiv:2606.16631 [eess.SY]; arXiv-issued DOI `10.48550/arXiv.2606.16631`
- **Direct PDF:** <https://arxiv.org/pdf/2606.16631>
- **Primary landing page:** <https://arxiv.org/abs/2606.16631>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page title and four-author list match this record. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Replacement for computationally efficient constrained MPC in MMCs. It addresses numerical conditioning as the prediction horizon grows through an exponentially weighted cost, includes an observer, analyzes control and plant constraints, and reports a priori closed-loop stability guarantees. It is especially relevant to long-horizon MPC without claiming a particular switching-time optimization method.

### 9. `sheng2026neuralFcsMpc`

- **Full title:** *Robust Neural Policy Distillation of Long-Horizon FCS-MPC for Flying-Capacitor Three-Level Boost Converters*
- **Authors:** Jinjian Sheng; Kazumune Hashimoto; Shuang Zhao; Mahdieh S. Sadabadi
- **Year:** 2026; submitted to arXiv on 13 April 2026
- **Journal/identifier:** arXiv preprint, arXiv:2604.11192 [math.OC]; arXiv-issued DOI `10.48550/arXiv.2604.11192`
- **Direct PDF:** <https://arxiv.org/pdf/2604.11192>
- **Primary landing page:** <https://arxiv.org/abs/2604.11192>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page title and four-author list match this record. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Replacement for switching-sequence reduction and real-time FCS-MPC computation in power converters. It distills a long-horizon FCS-MPC policy using beam-search expert trajectories, randomized operating conditions, and disagreement-based relabeling, with reported voltage-regulation and flying-capacitor-balancing performance under perturbations.

### 10. `monir2025scenarioSwitchedAffine`

- **Full title:** *Robust Control of Uncertain Switched Affine Systems via Scenario Optimization*
- **Authors:** Negar Monir; Mahdieh S. Sadabadi; Sadegh Soudjani
- **Year:** 2025; submitted to arXiv on 11 May 2025
- **Journal/identifier:** arXiv preprint, arXiv:2505.06943 [eess.SY]; arXiv-issued DOI `10.48550/arXiv.2505.06943`
- **Direct PDF:** <https://arxiv.org/pdf/2505.06943>
- **Primary landing page:** <https://arxiv.org/abs/2505.06943>
- **Source type:** Official arXiv author preprint; lawful open-access repository copy
- **Title match:** **Exact.** The landing page title, three-author list, identifier, and 11 May 2025 submission date match this record. The direct PDF request returned HTTP `200`, `application/pdf`.
- **Replacement role:** Replacement for robust switched-affine control under parameter uncertainty. The paper uses data-driven scenario optimization and quadratic Lyapunov functions to obtain robust regulation with reduced chattering effects, and the landing-page abstract explicitly reports an application to power-electronic converters.

## Selection notes

The ten records are distinct by both title and arXiv identifier. They collectively cover the requested themes without reusing any of the 20 excluded records:

- **Dwell time and switching-time optimization:** `switchedOptimalDwell2025`, `abbasiEsfeden2025dwell`, `katz2026sampledDwell`
- **Periodic/hybrid switched-affine behavior and stability:** `xu2024fcsLimitCycle`, `seuret2023dataDrivenAffine`, `hanke2023planarLimitCycles`, `feng2024variableInertia`, `monir2025scenarioSwitchedAffine`
- **Computationally efficient MPC and converter constraints:** `xu2024fcsLimitCycle`, `singh2026mmcExponentialMpc`, `sheng2026neuralFcsMpc`
- **Converter/MMC applications and sequence reduction:** `feng2024variableInertia`, `singh2026mmcExponentialMpc`, `sheng2026neuralFcsMpc`, with converter applications also present in `xu2024fcsLimitCycle` and `monir2025scenarioSwitchedAffine`.
