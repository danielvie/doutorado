# Introduction reference research results

## Purpose

Carry the completed literature research into the next introduction-review or citation-integration session. The research requested by `handoff/handoff-12-deep-research-for-recent-introduction-references.md` is complete.

## Authoritative result

Read `research/introduction-reference-review-2019-2026.md`. It contains the search record, eight-field coverage matrix, detailed evidence, ranked recommendations, BibTeX candidates, cutoff audit, historical attribution list, evidence gaps, and conservative novelty assessment.

Do not reconstruct the findings from older research notes. Some of them still describe a common-quadratic certificate for active conditioning. The current `article.tex` has no such result and explicitly makes no convergence claim while the Conditioning Factor is below one.

## Main conclusion

The search found that maximal direction-preserving scalar scaling is established generically in control allocation. Nakamura-Zimmerer and Miller (2026) review a direction-preserving LP that maximizes a scalar in `[0,1]` so the realized command remains collinear with the request, then develop a robust SOCP version.

This narrows the defensible novelty. Do not claim that direction-preserving scaling itself is new across control. Position the contribution as the specialization and combination of:

- fixed-period, fixed-order switching-instant feedback;
- a closed-form maximal feasible scalar for adjacent dwell inequalities;
- an `O(N)` online scan; and
- the maximal invariant subset of the Raw-Action Admissible Region under the linearized raw closed loop.

Marcolino et al. (2021) remains the closest eligible predecessor for the cycle-to-cycle timing architecture. The search did not find a second recent source with the same fixed-period, fixed-order, static timing-feedback structure. Report that scarcity rather than padding the comparison with loosely related MPC papers.

## New archive material

The research added two lawful, validated PDFs:

- `research/articles/27-karamanakos-2020-mpc-power-electronics-review.pdf`
- `research/articles/28-nakamura-zimmerer-2026-direction-preserving-control-allocation.pdf`

`research/articles/README.md` now records their DOI, provenance, and direct download URLs. The archive contains 28 PDFs.

Karamanakos et al. (2020) is the recommended broad power-electronics anchor. It supports converter-control objectives, explicit constraints, switching-frequency and switching-instant concerns, and microsecond computation budgets.

## Recommended introduction set

Use the ranked table in `research/introduction-reference-review-2019-2026.md` as the source of truth. The economical set is:

- Karamanakos et al. (2020) for broad converter control;
- Yang et al. (2022) and Saeed et al. (2022) for constraint handling under short computation budgets;
- Albea-Sanchez et al. (2021) for interval-level hybrid-affine converter modeling;
- Egidio et al. (2022) for the neighboring state-dependent mode-selection branch;
- Marcolino et al. (2021) for fixed-period one-cycle timing feedback and coupled dwell inequalities;
- Sakha and Kamalapurkar (2025) for recent dwell-violating switching-time filtering.

Use Xu and Lazar (2024) or Egidio, Daiha, and Deaecto (2020) only if the limit-cycle transition needs explicit support. Use Nakamura-Zimmerer and Miller (2026) in the novelty or alternative-method comparison, not as an application anchor.

## Cutoff and attribution

The current Introduction contains three sources outside the seven-year window:

- Stellato et al. (2017) can be replaced for its scene-setting role by recent computation sources.
- Repecho et al. (2017) is a narrow method attribution. Retain it as historical or remove that comparison; no like-for-like recent replacement was verified.
- Patiño et al. (2010) must remain for original switching-sensitivity and benchmark attribution.

Flieller et al. (2006), Gilbert and Tan (1991), and Briat and Seuret (2013) also remain valid historical sources for their specific original results. Do not present them as recent field anchors.

## Files and boundaries

Files created or updated by the research pass:

- `research/introduction-reference-review-2019-2026.md`
- `research/articles/README.md`
- `research/articles/27-karamanakos-2020-mpc-power-electronics-review.pdf`
- `research/articles/28-nakamura-zimmerer-2026-direction-preserving-control-allocation.pdf`

The research pass did not edit `article.tex` or `references.bib`. Both already have unrelated working-tree modifications, so inspect the current versions and preserve user work.

## Next session

Review the recommendations with the user before changing citations. If approved:

1. add only the accepted BibTeX entries from the report to `references.bib`;
2. rewrite the Introduction using the four-paragraph structure in `handoff/handoff-8-introduction-funnel-review-result.md`;
3. fix the cycle-index wording so the error measured at the start of cycle `k` produces offsets applied during cycle `k`, yielding the state at `k+1`;
4. keep predictive control as a constraint-aware alternative rather than the parent field;
5. preserve the geometric target-limit-cycle versus phase-specific reference-periodic-trajectory distinction;
6. keep the certificate limited to repeated raw-action feasibility and convergence inside the invariant region; and
7. build the paper and check page count, references, and unresolved citations.

## Residual evidence gaps

The report records the full list. The main unresolved point is whether different terminology hides a recent switching-schedule governor or filter with the same timing-specific radial construction. No patent search was completed. Use "not found among the reviewed sources," never a worldwide first claim.

Ma and Zhang (2023) and two other useful recent records are abstract-only in this pass. Do not infer equations or implementation details from them.

## Suggested skills

- `shared-understanding` to review the narrowed novelty position with the user before manuscript edits.
- `research` only if the remaining switching-schedule governor or patent gap must be closed.
- `unslop` for the Introduction rewrite.
