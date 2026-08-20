# Abstract Confrontation Decision Record

## Decision

**Revise before final acceptance; no blocker.** The abstract contains no false numerical claim or prohibited first-ever/global novelty claim. However, several scope and evidence qualifications should be made explicit because they are required by the body and `GOAL.md`, not merely stylistic preferences.

This adjudication is based on the article evidence rather than report agreement.

## Accepted fixes

1. **Moderate — State the nominal-feasibility hypothesis**  
   **Location:** `article.tex:33`, “the raw offset vector is multiplied by the largest factor…”  
   The conditioner’s feasibility and maximality proposition assumes strict nominal dwell margin at `article.tex:219–253`. The abstract should therefore say that the schedule has strict nominal dwell margin before claiming that a feasible largest factor exists.

2. **Moderate — Signal simulation-only evidence and scope the comparison to the run**  
   **Location:** `article.tex:33`, “On a nine-interval DC--DC converter benchmark…”  
   State that the evidence comes from an **exact nonlinear simulation**. The body explicitly says that the simulation uses exact interval propagation rather than the linearized model (`article.tex:357–365`) and that no hardware experiment was performed (`article.tex:413–421`).  
   Replace the generic claim that the conservative law “never violates” the bound with “remained feasible throughout the 100-cycle run.”

3. **Moderate — Define the reported settling event**  
   **Location:** `article.tex:33`, “settles in 6 cycles, against 20…”  
   The reported cycles are the first crossings of  
   \(\lVert S_x^{-1}e_k\rVert_2<0.01\), not an unspecified settling-time measure (`article.tex:363–385`). The abstract should either state that threshold or call the values “threshold-crossing cycles.”

4. **Moderate — State where the exact nonlinear guarantee applies**  
   **Location:** `article.tex:33`, final sentence  
   Replace “the nonlinear guarantee is local” with the sharper body result: it is local **in a neighborhood where conditioning is inactive** (`article.tex:276–278`). This is expressly required by `GOAL.md` and prevents readers from inferring a nonlinear guarantee under active conditioning.

5. **Moderate — Narrow the opening stabilization claim**  
   **Location:** `article.tex:33`, “can hold a switched-affine plant on a periodic trajectory”  
   Identify the setting as a prescribed fixed-period mode sequence and describe stabilization as local. The article proves local phase-locked stabilization near the cycle anchor, not unrestricted stabilization of switched-affine plants (`article.tex:278`; `GOAL.md`, “Boundaries”).

6. **Low — Distinguish exact propagation from linearization**  
   **Location:** `article.tex:33`, “We obtain that model by exact augmented matrix-exponential propagation”  
   Exact propagation produces the nonlinear one-cycle map; the linearized cycle model follows through a first-order expansion (`article.tex:84–198`). Prefer “derive the one-cycle linearization from exact augmented matrix-exponential propagation for mode-dependent affine dynamics.”

7. **Moderate — Correct the causal and technical wording of the numerical result**  
   **Location:** `article.tex:33`, “an aggressive law… requests a −43.045 µs dwell. Conditioning restores…”  
   The law requests switching-instant offsets; those offsets produce a schedule with a negative dwell. Conditioning enforces feasibility, while the aggressive tuning accounts for the faster response. State that:
   - an aggressive **LQR** raw action produces a \(-43.045\,\mu\mathrm{s}\) dwell;
   - the conditioner enforces the assumed \(3\,\mu\mathrm{s}\) bound; and
   - the **conditioned aggressive loop** crosses the threshold at cycle 6, versus cycle 20 for the conservative LQR.

## Rejected findings

1. **Rejected severity: simulation ambiguity is not a blocker.**  
   The student report correctly identifies the missing modality, but the body makes the evidence unambiguous and the abstract does not explicitly claim experimentation. This is a moderate scope correction, not a blocking falsehood.

2. **Rejected as a separate requirement: define every symbol in an additional sentence.**  
   In `article.tex:33`, \(\Phi\) and \(A_{\mathrm{cl}}\) are already identified by their positions as the nominal and raw closed-loop endpoints, while \(N\) is used conventionally as the number of dwell changes. Inline clarification is welcome, but a separate definition sentence is unnecessary.

3. **Rejected as redundant: separately state that the nominal endpoint must contract.**  
   The existing requirement that one quadratic Lyapunov function contract **both endpoints** already includes the nominal matrix. Naming \(\Phi\) explicitly as the nominal cycle matrix during the rewrite is sufficient.

4. **Rejected as mandatory: cite or fully attribute prior work in the abstract.**  
   The abstract makes no first-ever claim. The introduction explicitly credits Patiño and Marcolino (`article.tex:45–47`), and the derivation identifies their published sensitivity and switched-actuator foundations (`article.tex:198–206`). Adding “published” is optional polish rather than a correctness fix.

5. **Rejected as mandatory: include finite-difference validation, \(\beta_{\min}\), active-cycle count, or spectral radii.**  
   These are valid body results, but they are not necessary to substantiate the abstract’s central conditioner-and-certificate contribution. Adding them would compete with required scope qualifications within the journal’s 150–250-word limit.

6. **Rejected as mandatory: cite benchmark provenance in the abstract.**  
   `CONTEXT.md` requires provenance when the three-cell converter benchmark is first introduced in the article body. `article.tex:286` names the configuration and cites Patiño et al. The abstract may name the benchmark more fully without adding a citation.

## Optional deferred polish

- Replace “or even reverse it” with “produce a negative dwell and invert adjacent cycle boundaries.”
- Name the case study as the “nine-interval three-cell multilevel DC–DC converter benchmark.”
- Replace “repair” with the more neutral “condition” or “correct.”
- Add “published” before “switched-actuator model” if word count permits.
- Use `\SI{\MinimumRawDwell}{\micro\second}` rather than a text macro followed by `\si` so the signed value has proper mathematical typography.
- Prepare a hand-expanded plain-text abstract for submission portals that do not resolve LaTeX macros.

## Unresolved author decisions

- Whether to spend remaining word budget on the benchmark’s full name or on explicit prior-foundation wording. Neither is required for correctness.
- Whether to retain the enabling derivation sentence at all. If the required qualifications push the abstract above 250 words, compressing that sentence is preferable to removing the conditioner, certificate, simulation modality, threshold, or nonlinear-scope statements.

## Ordered rewrite brief

1. Open with the prescribed fixed-period mode sequence and local stabilization of a reference periodic trajectory; identify infeasible or negative dwells as the problem.
2. Introduce the raw and applied switching-instant offsets using the terminology in `CONTEXT.md`.
3. State the strict nominal dwell-margin hypothesis and the maximal scalar conditioner.
4. Retain direction preservation, mode order, cycle period, \(O(N)\) scan, and no-online-solver claims.
5. Define \(\Phi\) as the nominal cycle matrix and \(A_{\mathrm{cl}}\) as the full raw-feedback matrix when presenting  
   \(A(\beta)=(1-\beta)\Phi+\beta A_{\mathrm{cl}}\).
6. State that a common quadratic contraction of both endpoints certifies arbitrary, including state-dependent, conditioning-factor sequences in the **linearized** model.
7. If retained, describe the model as a first-order linearization derived from exact augmented propagation for mode-dependent affine dynamics.
8. Introduce the numerical evidence explicitly as an exact nonlinear 100-cycle simulation of the nine-interval three-cell converter.
9. Attribute \(-43.045\,\mu\mathrm{s}\) to the schedule resulting from the aggressive LQR raw action; state that conditioning enforces the assumed \(3\,\mu\mathrm{s}\) bound.
10. Report cycles 6 and 20 as crossings of the normalized-error \(0.01\) threshold, and scope conservative feasibility to that run.
11. Close by stating that the exact nonlinear guarantee is local where conditioning is inactive and that the large-error result is simulation evidence, not a global or experimental guarantee.
12. Keep the final abstract within the journal’s 150–250-word range.

## Invariants

- The primary contribution remains the maximal direction-preserving conditioner plus its common-Lyapunov certificate.
- Do not present switching-instant sensitivity, fixed-period one-cycle modeling, static LQR, or dwell polyhedra as first-ever contributions (`research/novelty-review.md`).
- Preserve the fixed mode order, fixed cycle period, and \(N-1\) independent interior switching instants.
- Preserve the strict nominal dwell-margin hypothesis.
- Preserve maximality, whole-vector radial scaling, \(O(N)\) execution, and absence of an online solver.
- Do not extend the common-Lyapunov result beyond the linearized family.
- Do not claim an exact nonlinear guarantee under active conditioning; the proved neighborhood has \(\beta=1\).
- Keep the \(3\,\mu\mathrm{s}\) dwell bound identified as a simulation assumption, not a hardware-calibrated limit.
- If retained, numerical values must remain: \(-43.045\,\mu\mathrm{s}\), \(3\,\mu\mathrm{s}\), and threshold cycles \(6/20\), consistent with `results/metrics.tex:28–36`.
- Use “reference periodic trajectory” when timing and phase matter, following `CONTEXT.md`.
- Do not introduce new claims, numbers, citations, experimental evidence, or global-stability language.

## Residual risks

- Generated numerical values were checked against `results/metrics.tex`, but the generation script and simulations were not rerun under the review-only constraint.
- The novelty position is defensible only against the reviewed corpus described in `research/novelty-review.md`; it is not evidence of worldwide priority.
- The rewritten abstract still requires a compiler and word-count check after the accepted qualifications are applied.