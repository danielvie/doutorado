# Introduction reference review, 2019–2026

## Scope and result

**Search date:** 3 September 2026.

This review supports the introduction's funnel from converter control to fixed-period cycle-to-cycle switching-time feedback, minimum dwell-duration feasibility, and the paper's conditioner. It applies the cutoff in `handoff/handoff-12-deep-research-for-recent-introduction-references.md`: the earliest official publication or first preprint date must be 3 September 2019 or later.

The strongest addition is Karamanakos et al. (2020), a peer-reviewed open-access survey that can carry the broad power-electronics and computation claims. The closest eligible predecessor remains Marcolino et al. (2021). A second new source, Nakamura-Zimmerer and Miller (2026), changes the novelty assessment in an important way: maximal direction-preserving scaling is established in control allocation. It is not a switching-time conditioner, but it means the paper should not claim the generic scaling idea as new across control.

The defensible paper-level contribution is the specialization and combination of:

- fixed-period, fixed-order switching-instant feedback;
- the closed-form maximal feasible scalar for the adjacent-dwell inequalities;
- an `O(N)` online scan; and
- the maximal invariant subset of the Raw-Action Admissible Region under the linearized raw closed loop.

The current manuscript correctly makes no convergence claim while conditioning is active.

## Search record

Eight parallel research lanes covered the eight fields in the handoff. Their web tools were unavailable, so they performed independent audits of the local primary-source archive and recorded unexecuted queries as limitations. The integration pass then queried live primary metadata and discovery services.

### Services queried

- Crossref REST API for DOI identity, author lists, online/print dates, venue, pagination, and publisher links.
- OpenAlex API for open-access status, repository locations, publication dates, and abstract text where supplied by the publisher.
- Semantic Scholar API for publication dates, open-access locations, and abstract discovery. Bibliographic facts were checked against Crossref or a first-party record before use.
- DOAJ API for the Karamanakos et al. open-access record and license.
- NASA Technical Reports Server API for the Nakamura-Zimmerer and Miller record, abstract, review status, meeting date, and public manuscript.
- Official arXiv records and PDFs for Xu and Lazar and Sakha and Kamalapurkar, as already validated in the local archive.
- IEEE and NASA PDFs, local lawful manuscripts, and `pdftotext` for full-text claim checks.

### Exact live queries

Crossref queries used the date filter `from-pub-date:2019-09-03,until-pub-date:2026-09-03` with these strings:

1. `power electronics converter control review switching frequency`
2. `constraint aware power converter control short computation time`
3. `switched affine converter hybrid model`
4. `switched affine periodic trajectory limit cycle return map`
5. `cycle-to-cycle switching time feedback fixed period`
6. `minimum dwell time switching schedule feasibility filter`
7. `radial scaling direction preserving constraint handling control`
8. `reference governor switching schedule dwell time`
9. `maximal feasible scalar contraction control polytope`
10. `invariant set raw control action feasibility filter`

Additional title and DOI lookups covered:

- `10.1109/OJIA.2020.3020184`
- `10.1109/TIE.2022.3150085`
- `10.1080/00207721.2024.2302883`
- `10.1016/j.ejcon.2024.101094`
- `10.2514/6.2026-2353`
- all DOIs of the recommended papers already in `references.bib`.

The NASA NTRS queries were `Robust Direction-Preserving Control Allocation` and `Nakamura-Zimmerer Miller direction preserving control allocation`.

### Access limitations

- IEEE's open PDF endpoint rejected scripted HTTP requests but loaded lawfully in a normal browser. The browser download was validated locally.
- Some publisher full texts remained subscription-only. Those records are labeled `abstract-only`, and no claim extends beyond the abstract or publisher metadata.
- The HAL file for Albea et al. (2024) was discoverable through the HAL and OpenAlex records but challenged automated retrieval. It is therefore not treated as locally inspected full text.
- Search APIs rank by textual relevance and can miss papers filed under different vocabulary. The novelty conclusion remains corpus-limited.
- No patent search was completed.

## Coverage matrix

| Field | Strongest recent sources | Recommended introduction role | Coverage |
|---|---|---|---|
| 1. Power electronics and converter control | Karamanakos et al. (2020) | Broad opening anchor | Strong, peer-reviewed survey and open full text |
| 2. Constraint-aware control under short budgets | Yang et al. (2022); Saeed et al. (2022) | Fixed-frequency timing QP and reduced MPC decision space | Strong, peer-reviewed, laboratory hardware |
| 3. Switched-affine and hybrid converter models | Albea-Sanchez et al. (2021); Ma and Zhang (2023) | Interval-level hybrid-affine/PWM modeling and a recent converter example | Strong full text plus strong abstract-only article |
| 4. Periodic trajectories and limit cycles | Xu and Lazar (2024); Egidio et al. (2020) | Periodic terminal ingredients and established switched-affine limit-cycle control | Good, but one recommendation is a preprint |
| 5. Mode selection versus instant adjustment | Egidio et al. (2022); Marcolino et al. (2021) | Define the neighboring mode-selection branch and the retained-cycle timing branch | Strong |
| 6. Fixed-period cycle-to-cycle timing feedback | Marcolino et al. (2021) | Closest eligible predecessor | Sparse. Do not pad with unrelated MPC papers |
| 7. Minimum dwell constraints and action feasibility | Marcolino et al. (2021); Sakha and Kamalapurkar (2025) | Coupled dwell inequalities and a recent switching-time filter | Strong predecessor plus preprint neighbor |
| 8. Closest conditioner alternatives | Nakamura-Zimmerer and Miller (2026); Marcolino et al. (2021) | Generic direction-preserving maximal scaling versus timing-specific conditioning | Strong conceptual neighbor, but no recent switching-schedule match found |

## Selected references and evidence

### Karamanakos et al. (2020)

**Citation:** Petros Karamanakos, Eyke Liegmann, Tobias Geyer, and Ralph Kennel, "Model Predictive Control of Power Electronic Systems: Methods, Results, and Challenges," *IEEE Open Journal of Industry Applications*, vol. 1, pp. 95–114, 2020. DOI: [10.1109/OJIA.2020.3020184](https://doi.org/10.1109/OJIA.2020.3020184).

- **Dates:** Crossref record created 28 August 2020; PDF says current version 15 September 2020; issue year 2020.
- **Status/access:** peer-reviewed invited survey; open-access IEEE version of record; CC BY 4.0; full text.
- **Lawful PDF:** <https://ieeexplore.ieee.org/ielx7/8782707/8820181/09180048.pdf>
- **Local path:** `research/articles/27-karamanakos-2020-mpc-power-electronics-review.pdf`.
- **Evidence:** p. 95 introduces power-semiconductor switching-frequency and computation history and names converter application classes. P. 96 separates FCS switch selection from variable switching instants and fixed-frequency direct MPC. P. 97 identifies inductor currents and capacitor voltages as energy-storage states and says power-electronic actions occur within tens of microseconds. P. 99 discusses hard input and soft state constraints. Pp. 104–105 discuss few-microsecond solver budgets and embedded platforms.
- **Exact claim supported:** converter control regulates electrical variables through switch or modulation decisions, commonly under explicit constraints and tight computation budgets; switching frequency and application time are control concerns.
- **Relevance:** best single broad introduction anchor.
- **Distinction:** a survey of predictive control, not a source for the proposed conditioner or invariant raw-action certificate.
- **Repository status before this review:** absent from `references.bib` and the PDF archive.

### Yang et al. (2022)

**Citation:** Qifan Yang et al., "Computationally Efficient Fixed Switching Frequency Direct Model Predictive Control," *IEEE Transactions on Power Electronics*, vol. 37, no. 3, pp. 2761–2777, 2022. DOI: [10.1109/TPEL.2021.3114979](https://doi.org/10.1109/TPEL.2021.3114979).

- **Dates:** published online 24 September 2021; issue March 2022.
- **Status/access:** peer-reviewed journal article; full text already archived as `research/articles/13-yang-2022-fixed-frequency-direct-mpc.pdf`.
- **Evidence:** abstract and Secs. II–IV formulate a constrained QP over switching sequences and switching instants at fixed switching frequency. The abstract reports few-microsecond solution and 3 kW drive experiments. Sec. VII reports computation and laboratory validation.
- **Claim supported:** continuous switching-instant optimization can enforce fixed-frequency converter operation, but fitting the online QP into the switching budget requires a custom solver and pruning.
- **Distinction:** online timing optimization, not static cycle-to-cycle feedback followed by analytic conditioning.
- **Repository status:** already in `references.bib` and the archive.

### Saeed et al. (2022)

**Citation:** Junaid Saeed, Liuping Wang, and Nuwantha Fernando, "Model Predictive Control of Phase Shift Full-Bridge DC–DC Converter Using Laguerre Functions," *IEEE Transactions on Control Systems Technology*, vol. 30, no. 2, pp. 819–826, 2022. DOI: [10.1109/TCST.2021.3069148](https://doi.org/10.1109/TCST.2021.3069148).

- **Dates:** accepted 5 March 2021; final manuscript 24 March 2021; Crossref record created 19 April 2021; issue March 2022.
- **Status/access:** peer-reviewed journal article; full author manuscript in `research/articles/14-saeed-2022-laguerre-converter-mpc.pdf`.
- **Evidence:** abstract and Sec. III state the nonlinear peak-current constraint and Laguerre reduction. Sec. IV and Figs. 4–8 report a 60 W laboratory converter, Texas Instruments F28069M DSP, and 40 microsecond sampling.
- **Claim supported:** reduced parameterization is one way to enforce converter constraints within a short sample period.
- **Distinction:** phase-shift MPC with an online optimization, not an interior-instant vector conditioned along its ray.
- **Repository status:** already present.

### Albea-Sanchez et al. (2021)

**Citation:** Carolina Albea-Sanchez, Antonino Sferlazza, Fabio Gómez-Estern, and Francisco Gordillo, "Control of Power Converters With Hybrid Affine Models and Pulse-Width Modulated Inputs," *IEEE Transactions on Circuits and Systems I: Regular Papers*, vol. 68, no. 8, pp. 3485–3494, 2021. DOI: [10.1109/TCSI.2021.3083900](https://doi.org/10.1109/TCSI.2021.3083900).

- **Dates:** Crossref record created 3 June 2021; issue August 2021.
- **Status/access:** peer-reviewed article; lawful HAL author manuscript; full text in `research/articles/24-albea-sanchez-2021-hybrid-affine-pwm.pdf`.
- **Lawful PDF:** <https://laas.hal.science/hal-03326994v1/file/PWM_ST19.pdf>
- **Evidence:** Secs. II–III, especially Eqs. (4)–(11), retain exact evolution over PWM subintervals and include PWM/sample-and-hold variables in a hybrid-affine model. The application is a boost converter.
- **Claim supported:** converter switch/PWM configurations can be modeled through interval-level affine dynamics rather than only an averaged model.
- **Distinction:** two-mode PWM hybrid control, not the paper's prescribed nine-interval timing feedback.
- **Repository status:** already present.

### Ma and Zhang (2023), abstract-only

**Citation:** Wenjie Ma and Bo Zhang, "Periodic Time-Triggered Hybrid Control for DC–DC Converter Based on Switched Affine System Model," *IEEE Transactions on Industrial Electronics*, vol. 70, no. 1, pp. 311–321, 2023. DOI: [10.1109/TIE.2022.3150085](https://doi.org/10.1109/TIE.2022.3150085).

- **Dates:** earliest publisher record 15 February 2022; issue January 2023.
- **Status/access:** peer-reviewed journal article; publisher abstract accessible; full text was not lawfully downloadable in this pass.
- **Abstract-supported claim:** the paper uses a switched-affine converter model, periodic time-triggered hybrid control, LMI design conditions, a linear state switching law, and simulation plus buck-boost-converter experiments.
- **Not verified:** equations, exact timing structure, dwell constraints, and implementation details.
- **Relevance:** strong recent converter-specific bridge from switched-affine modeling to periodic control.
- **Distinction:** the abstract describes a state switching law, not fixed-order interior-instant offsets.
- **Repository status:** absent from `references.bib` and the local archive.

### Xu and Lazar (2024)

**Citation:** Duo Xu and Mircea Lazar, "Finite Control Set Model Predictive Control with Limit Cycle Stability Guarantees," arXiv:2407.07615, 2024. DOI: [10.48550/arXiv.2407.07615](https://doi.org/10.48550/arXiv.2407.07615).

- **Date:** first public version 10 July 2024.
- **Status/access:** preprint; official arXiv full text in `research/articles/07-xu-2024-fcs-limit-cycle.pdf`.
- **Evidence:** Secs. 2–3 define the switched-affine limit cycle and FCS-MPC problem. Sec. 3.2 and Theorem 9 give recursive-feasibility and asymptotic-stability conditions using periodic terminal sets. Sec. 4 computes ellipsoidal and polytopic periodic terminal sets.
- **Claim supported:** limit cycles can be explicit control objectives for switched-affine systems, with cycle-indexed terminal ingredients and stability analysis.
- **Distinction:** FCS mode selection, not fixed-sequence continuous switching-instant adjustment; it does not by itself establish phase locking to the paper's continuous-time reference periodic trajectory.
- **Repository status:** already present.

### Egidio, Daiha, and Deaecto (2020)

**Citation:** Lucas N. Egidio, Hamilton R. Daiha, and Grace S. Deaecto, "Global Asymptotic Stability of Limit Cycle and H2/H∞ Performance of Discrete-Time Switched Affine Systems," *Automatica*, vol. 116, 108927, 2020. DOI: [10.1016/j.automatica.2020.108927](https://doi.org/10.1016/j.automatica.2020.108927).

- **Dates:** Crossref record created 19 March 2020; issue June 2020.
- **Status/access:** peer-reviewed journal article; full text already held at `research-material/literature/articles-control/[Egidio 2020]__discreto Global Asymptoic stability of limit cycle.pdf`.
- **Evidence:** Sec. 2 defines the limit cycle and state-dependent switching problem. Sec. 3, Theorems 1–2, gives limit-cycle generation and a state-dependent switching function with global asymptotic guarantees under the paper's assumptions.
- **Claim supported:** limit-cycle stabilization is established in switched-affine control.
- **Distinction:** discrete-time mode selection with a global result in its own model, not the present local continuous-time fixed-schedule timing controller.
- **Repository status:** bibliography entry exists; the DOI is missing from that entry. The PDF is held outside `research/articles/` and was not duplicated.

### Egidio, Deaecto, and Jungers (2022)

**Citation:** Lucas N. Egidio, Grace S. Deaecto, and Raphaël M. Jungers, "Stabilization of Rank-Deficient Continuous-Time Switched Affine Systems," *Automatica*, vol. 143, 110426, 2022. DOI: [10.1016/j.automatica.2022.110426](https://doi.org/10.1016/j.automatica.2022.110426).

- **Dates:** earliest publisher record 17 June 2022; issue September 2022.
- **Status/access:** peer-reviewed; full text in `research/articles/03-egidio-2022-rank-deficient-switched-affine.pdf`.
- **Evidence:** abstract and Secs. 2–3 define a state-dependent switching rule. Sec. 5 applies it to a DC motor driven by an H-bridge and boost converter.
- **Claim supported:** state-dependent active-subsystem selection is a modern switched-affine control branch.
- **Distinction:** chooses the active mode; the present paper preserves mode order and changes interior instants.
- **Repository status:** already present.

### Marcolino, Galvão, and Kienitz (2021)

**Citation:** Matheus Henrique Marcolino, Roberto Kawakami Harrop Galvão, and Karl Heinz Kienitz, "Predictive Control of Linear Systems with Switched Actuators Subject to Dwell-Time Constraints," *Journal of Control, Automation and Electrical Systems*, vol. 32, no. 1, pp. 1–17, 2021. DOI: [10.1007/s40313-020-00667-9](https://doi.org/10.1007/s40313-020-00667-9).

- **Dates:** published online 23 November 2020; issue February 2021.
- **Status/access:** peer-reviewed; full text in `research/articles/01-marcolino-2021-dwell-constrained-predictive-control.pdf`.
- **Evidence:** Secs. 2–3, Eqs. (3), (8)–(12), (19), and (27)–(28) fix the cycle boundaries, use `N-1` interior instants, derive adjacent dwell inequalities, and obtain the one-cycle model. Sec. 4, Eqs. (38)–(44), gives the constrained QP and terminal-set machinery. Sec. 5.2, Eqs. (47)–(49), Algorithm 1, and Table 4 give the static DLQR and sequential saturation comparison.
- **Claim supported:** fixed-period timing coordinates, coupled dwell inequalities, one-cycle timing feedback, static LQR, and dwell-constrained predictive control are explicit prior art.
- **Distinction:** common plant matrix with switched actuator levels; constrained operation uses optimization, while the standalone comparator uses sequential saturation. It does not disclose the present timing-specific maximal scalar scan plus raw-action invariant certificate.
- **Repository status:** already present.

### Sakha and Kamalapurkar (2025)

**Citation:** Masoud S. Sakha and Rushikesh Kamalapurkar, "Switched Optimal Control with Dwell Time Constraints," arXiv:2501.05548, 2025. DOI: [10.48550/arXiv.2501.05548](https://doi.org/10.48550/arXiv.2501.05548).

- **Date:** first public version 9 January 2025.
- **Status/access:** preprint; official full text in `research/articles/05-sakha-2025-switched-optimal-dwell.pdf`.
- **Evidence:** abstract and Sec. V state that a filter removes switching times violating the dwell constraint. Algorithm 1 performs the filtering. The conclusion calls the method a post-filtered embedding approach.
- **Claim supported:** action-side filtering of dwell-infeasible switching times exists in recent switched optimal control.
- **Distinction:** the filter is embedded in an optimization pipeline and removes switching times. It is not shown to return the maximal scalar multiple of a fixed-period raw offset vector.
- **Repository status:** already present.

### Nakamura-Zimmerer and Miller (2026)

**Citation:** Tenavi Nakamura-Zimmerer and Luke J. Miller, "Robust Direction-Preserving Control Allocation," AIAA SciTech 2026 Forum, 2026. DOI: [10.2514/6.2026-2353](https://doi.org/10.2514/6.2026-2353).

- **Dates:** NASA manuscript submitted 5 December 2025; first official AIAA online record 8 January 2026; conference 12–16 January 2026.
- **Status/access:** conference paper reviewed by a NASA peer committee; public NASA manuscript; full text.
- **Lawful PDF:** <https://ntrs.nasa.gov/api/citations/20250011126/downloads/RDPCPpaperv4.pdf>
- **Local path:** `research/articles/28-nakamura-zimmerer-2026-direction-preserving-control-allocation.pdf`.
- **Evidence:** Sec. II.A, Eqs. (7a)–(7d), reviews direction-preserving linear-programming allocation. It maximizes a scalar in `[0,1]`, keeps the realized command collinear with the request, and scales it to satisfy constraints. Sec. III develops a robust SOCP version. Sec. IV.C reports that optimization runs online for each command and gives median times near 0.3 ms for LP and 1 ms for SOCP in the stated MATLAB test.
- **Claim supported:** maximal scalar direction preservation is a known generic control-allocation construction.
- **Relevance:** closest terminology and mathematical neighbor found for radial action scaling.
- **Distinction:** aircraft control allocation, actuator redundancy, and LP/SOCP optimization. It has no switching schedule, adjacent dwell inequalities, fixed period, cycle map, or raw-action invariant set.
- **Repository status before this review:** absent.

## Ranked introduction recommendations

| Introduction area | Rank 1 | Rank 2 | Use |
|---|---|---|---|
| Broad converter control | Karamanakos et al. (2020) | None needed | Opening field anchor |
| Constraints and computation | Yang et al. (2022) | Saeed et al. (2022) | Continuous timing/custom solver; reduced decision space |
| Switched-affine converter models | Albea-Sanchez et al. (2021) | Ma and Zhang (2023), abstract-only | Interval dynamics; recent periodic converter example |
| Periodic trajectories/limit cycles | Xu and Lazar (2024) | Egidio et al. (2020) | Periodic terminal ingredients; established limit-cycle control |
| Mode selection versus instant adjustment | Egidio et al. (2022) | Marcolino et al. (2021) | Neighboring branches |
| Fixed-period cycle feedback | Marcolino et al. (2021) | None found | Report scarcity |
| Minimum dwell feasibility | Marcolino et al. (2021) | Sakha and Kamalapurkar (2025) | Coupled inequalities; filter neighbor |
| Conditioner positioning | Nakamura-Zimmerer and Miller (2026) | Marcolino et al. (2021) | Generic direction-preserving scaling; timing-specific predecessor |

For a short introduction, do not cite every row independently. Karamanakos, Yang, Albea-Sanchez, Egidio 2022, Marcolino, and Sakha cover the funnel economically. Use Xu or Egidio 2020 only if the limit-cycle transition needs explicit support. The NASA control-allocation paper belongs in the gap/novelty comparison, not the application opening.

## Ready-to-add BibTeX

These entries are not in `references.bib`. Metadata was checked against primary records. The bibliography file was not edited.

```bibtex
@article{karamanakos2020mpcPowerElectronics,
  author  = {Karamanakos, Petros and Liegmann, Eyke and Geyer, Tobias and Kennel, Ralph},
  title   = {Model Predictive Control of Power Electronic Systems: Methods, Results, and Challenges},
  journal = {IEEE Open Journal of Industry Applications},
  volume  = {1},
  pages   = {95--114},
  year    = {2020},
  doi     = {10.1109/OJIA.2020.3020184}
}

@article{ma2023periodicHybridConverter,
  author  = {Ma, Wenjie and Zhang, Bo},
  title   = {Periodic Time-Triggered Hybrid Control for {DC--DC} Converter Based on Switched Affine System Model},
  journal = {IEEE Transactions on Industrial Electronics},
  volume  = {70},
  number  = {1},
  pages   = {311--321},
  year    = {2023},
  doi     = {10.1109/TIE.2022.3150085}
}

@inproceedings{nakamuraZimmerer2026directionPreserving,
  author    = {Nakamura-Zimmerer, Tenavi and Miller, Luke J.},
  title     = {Robust Direction-Preserving Control Allocation},
  booktitle = {AIAA SciTech 2026 Forum},
  year      = {2026},
  doi       = {10.2514/6.2026-2353}
}
```

## Current citation cutoff audit

### Introduction citations outside the window

| Citation | Earliest official date | Treatment |
|---|---:|---|
| Stellato, Geyer, and Goulart (2017) | 2016 online / 2017 issue | Remove from the recent scene-setting cluster. Yang 2022 and Saeed 2022 support the current short-budget claim. Keep only as historical FPGA/FCS attribution if that exact point is needed. |
| Repecho et al. (2017) | 2016 online / 2017 issue | The comparison is method-specific. Keep explicitly as historical attribution or remove the comparison. No like-for-like recent replacement was verified. |
| Patino, Riedinger, and Ruiz (2010) | 2010 | Retain for original switching-sensitivity and benchmark attribution. A recent source cannot replace it without misattribution. |

### Older citation outside the Introduction

Briat and Seuret (2013), cited in the conditioning section, is outside the window. It may remain for original minimum and mode-dependent dwell-time theory. Della Rossa et al. (2022, 2023) can supply recent restricted-switching context, but they do not replace the original result and do not correct requested timing actions.

## Older sources that remain necessary

- **Patino et al. (2010):** converter benchmark, fixed-period cyclic optimization, and mode-dependent vector-field-jump sensitivity, especially Proposition 7 and Eqs. (19)–(24).
- **Flieller et al. (2006):** switching-time sensitivity for hybrid limit-cycle computation and sampled local stability, if that lineage sentence remains.
- **Gilbert and Tan (1991):** maximal output-admissible-set and preimage-iteration attribution.
- **Briat and Seuret (2013):** original affine minimum/mode-dependent dwell-time characterizations.
- **Repecho et al. (2017):** only if the specific hysteresis-band frequency-regulation comparison remains.

Older sources should be labeled foundational or method-specific. They should not carry recent scene-setting claims.

## Evidence gaps

1. No eligible source was verified for the exact combination of fixed order, fixed period, interior switching instants, static proportional cycle feedback, maximal radial dwell conditioning, and the invariant raw-action certificate.
2. Marcolino et al. remains the only verified recent source covering nearly all of the fixed-period cycle-to-cycle timing architecture. This is a real scarcity finding, but only within the searched corpus.
3. No recent paper was verified that applies a reference governor, command governor, or safety filter specifically to a vector of interior switching instants with adjacent dwell inequalities.
4. Projection onto the feasible timing polytope is mathematically a QP and generally leaves the requested ray, but no recent primary source was found that studies this exact timing projection as an actuator filter.
5. Ma and Zhang (2023) is abstract-only here. Its equations and exact timing mechanism must not be described beyond the abstract.
6. A lawful HAL manuscript exists for Albea et al. (2024), "Stabilization of aperiodic sampled-data switched affine systems to hybrid limit cycles," DOI `10.1016/j.ejcon.2024.101094`, but automated retrieval was blocked. Its abstract supports convergence to a predetermined hybrid limit cycle under aperiodic sampling and dwell times; details remain unverified.
7. Deaecto, Egidio, and Costanzo (2024), DOI `10.1080/00207721.2024.2302883`, is a strong abstract-only source for state-dependent integral tracking of a periodic affine profile. It is not needed in the compact recommendation because its control variable is mode selection and full text was unavailable.
8. No patent search was completed. Do not make a worldwide first claim.

## Conservative novelty assessment

The literature now supports a sharper split.

**Established pieces:**

- Patino gives mode-dependent switching-instant sensitivity.
- Marcolino gives fixed-period timing coordinates, the one-cycle model, adjacent dwell inequalities, static DLQR, constrained MPC, and polyhedral terminal-set machinery.
- Generic maximal admissible/invariant sets are standard from Gilbert and Tan.
- Direction-preserving maximization of a common scalar is established in control allocation. Nakamura-Zimmerer and Miller review a standard LP construction with exactly that structure before adding robustness.
- Dwell-time filters and dwell-constrained switching optimization exist in Sakha and Kamalapurkar and related work.

**What was not found as a complete method:**

No reviewed source applies the maximal common scalar in closed form to the complete vector of fixed-period interior switching-instant offsets, exploits the adjacent-dwell structure for an `O(N)` scan, and pairs it with the maximal invariant subset of the Raw-Action Admissible Region under the linearized raw closed loop.

This supports wording such as:

> We specialize direction-preserving command scaling to fixed-period switching-instant feedback. The adjacent dwell inequalities yield the maximal feasible scalar through an `O(N)` scan. A standard maximal-invariant-set construction then identifies the largest raw-action-feasible subset on which conditioning remains inactive and the Schur linearized raw closed loop converges.

It does not support saying that radial scaling, direction preservation, invariant-set iteration, dwell constraints, one-cycle timing feedback, or switching-instant sensitivity is new by itself.

The certificate must stay narrow. Inside the maximal invariant Raw-Action Admissible Region, every raw action is feasible, conditioning remains inactive, and the linearized raw closed loop converges because its matrix is Schur. Outside that set, the conditioner guarantees only current-cycle dwell feasibility. The manuscript makes no convergence claim while the Conditioning Factor is below one, and the exact nonlinear claim is local where strict dwell margin keeps conditioning inactive.

## Repository changes from this review

- Added `research/articles/27-karamanakos-2020-mpc-power-electronics-review.pdf`.
- Added `research/articles/28-nakamura-zimmerer-2026-direction-preserving-control-allocation.pdf`.
- Updated `research/articles/README.md` with lawful provenance.
- Created this report.
- Did not edit `latex/article.tex` or `references.bib`.
