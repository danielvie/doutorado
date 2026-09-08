# Handoff: specialization funnel and citation integration

## Purpose

Continue work on the paper's introduction and literature positioning. The introduction now uses four layers rather than seven. Preserve that shorter argument and use references as evidence for specific claims, not as a coverage target or paper-by-paper list.

## Existing artifacts

- Rewritten paper and current funnel introduction: `article.tex`
- BibTeX records: `references.bib`
- Full 20-paper research synthesis: `research/recent-literature-2021-2026.md`
- Local PDF/link archive: `research/articles/recent-2021-2026/README.md`
- Novelty boundaries: `research/novelty-review.md`
- Project contribution and non-goals: `GOAL.md`
- Previous PDF replacement handoff: `handoff/handoff-2-replace-literature-links-with-pdfs.md`

## Four-layer introduction

The seven-layer funnel was too visible in the prose. It delayed the specific problem and gave distant literature as much space as the closest prior work. `article.tex` now uses four paragraphs:

1. **Implementation pressure.** Power-converter timing and physical constraints must be enforced within short sampling intervals. Predictive methods handle these constraints, but static feedback avoids their online optimization cost and still needs a feasibility mechanism.
2. **Exact control setting.** A prescribed affine-mode sequence repeats with fixed period. Cycle-to-cycle feedback moves only the interior switching instants to regulate a periodic trajectory. This distinguishes the paper from active-mode selection and complete online schedule optimization.
3. **Closest prior work and gap.** Pati\~no supplies the mode-dependent switching sensitivity. Marcolino supplies fixed-period coordinates, the one-cycle model, static LQR, and dwell-constrained predictive control. Raw static timing actions can violate coupled dwell limits, while clipping or sequential saturation can alter the requested direction or final cycle boundary.
4. **Contribution and evidence.** The conditioner retains the largest feasible scalar multiple of the complete raw timing action. It preserves direction, mode order, and period, requires an $O(N)$ scan, and admits a common-quadratic certificate for the conditioned linearized family. The derivation, Jacobian checks, and converter simulation support these two main results; they are not equal novelty claims.

The reader should encounter this argument:

```text
real-time timing constraints
  -> fixed-period cycle-to-cycle feedback
  -> infeasible raw timing action
  -> maximal scalar conditioning and certification
```

Do not restore separate paragraphs for industrial applications, generic switched-affine theory, periodic trajectories, and switching-time optimization unless a reviewer asks for that context. Those topics belong inside the four layers.

## Reference integration strategy

Each citation must have a job. Cite the exact claim it supports, immediately after that claim. Do not append all references at the end of a paragraph containing unrelated assertions.

### Layer 1: implementation pressure

Use a small representative set of references. The current paragraph assigns one job to each group:

- lower-dimensional MPC parameterization: `saeed2022laguerre`
- fast fixed-frequency solver: `yang2022fixed`
- candidate pruning or approximation: `augustine2023mpc`, `switchedOptimalDwell2025`

The point is not to survey converter control. It is to establish that direct constraint handling costs online computation, then motivate a static law whose raw output still needs an admissible implementation. Do not claim production deployment. If application evidence is added, describe it as simulation or laboratory validation according to the source.

### Layer 2: exact control setting

Use `egidio2022rank` and `russo2026dwell` only to distinguish state-dependent active-mode selection from this paper's actuator choice. The present controller preserves the mode order and cycle period and moves only interior switching instants once per cycle.

References on periodic control or online schedule optimization are optional. Add them only if the text makes a factual comparison that needs support. Do not create separate paragraphs to accommodate `ma2023periodic`, `albea2024limit`, `deaecto2024tracking`, `zhu2023switching`, or `peng2024robust`.

### Layer 3: closest prior work and gap

Give the most detailed treatment to:

- `patino2010`: published mode-dependent switching sensitivity and cyclic predictive control;
- `marcolino2021`: fixed-period timing coordinates, one-cycle model, dwell inequalities, static LQR, constrained predictive control, and the standalone LQR saturation behavior.

State the distinction precisely. Pati\~no optimizes switching instants online. Marcolino's constrained predictive controller enforces dwell limits, but its standalone static LQR comparison needs actuator-side saturation. According to the reviewed source, that sequential saturation can move the final switching instant, and the reported example diverges. Cite `marcolino2021` immediately after this claim.

Do not claim novelty for switching sensitivity, fixed-period coordinates, one-cycle feedback, LQR, or dwell-constrained switching-time control generally.

### Layer 4: contribution and supporting evidence

Do not cite the paper's own contribution. State the two main results:

1. the largest feasible scalar on the raw timing-action ray, found by an $O(N)$ scan while preserving direction and both cycle boundaries;
2. a common-quadratic certificate for every state-dependent conditioning factor in the resulting linearized matrix segment.

Treat the mode-dependent one-cycle derivation, numerical differentiation, residual check, and converter simulation as support. They should not appear as a third equal contribution. LQR supplies comparison laws rather than a new synthesis method.

A conservative literature claim remains acceptable:

> Among the reviewed papers, no method was found that combines fixed-period, fixed-mode-order switching-time feedback with a maximal direction-preserving scalar correction, an $O(N)$ online feasibility scan, and a common-quadratic certificate for the resulting conditioned cycle-map family.

Do not claim global priority or first use of any individual standard component.

## Citation style rules

- Use narrative citations when the authors' method is important: “Yang et al. formulate...”.
- Use parenthetical citations for background support.
- A citation should support one identifiable factual claim.
- Prefer one to three citations per sentence and a small group per paragraph.
- A reference is optional unless the sentence makes a factual claim that needs it. Do not cite papers merely because they were reviewed.
- Integrate papers through problem, relevant approach, remaining limitation, and transition to the next layer.
- Avoid "Paper A does this. Paper B does that." This produces an annotated bibliography.
- Use local PDFs for reading and verification only. The article cites BibTeX keys, not filesystem paths.
- Check every method/evidence claim against `research/recent-literature-2021-2026.md` and the downloaded paper before strengthening language.

## Suggested skills

- `research` for further source verification or replacing remaining link-only references.
- `unslop` for any prose revision.
- `shared-understanding` if the funnel or novelty boundary needs a design decision.
- `handoff` when passing the literature or introduction work to another agent.
