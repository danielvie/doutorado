# Handoff: review introduction funnel

## Purpose

Review the proposed conceptual funnel for the paper introduction before any rewrite of `draft.md`. Assess whether the sequence leads cleanly from the broad control problem to the paper's exact research area, and recommend corrections where needed.

## Authoritative context

Read these first:

- `project-knowledge/README.md`
- `project-knowledge/project/manuscript-description.md`
- `project-knowledge/concepts/terminology.md`
- `project-knowledge/concepts/controller-model.md`
- `GOAL.md`
- `CONTEXT.md`

The working introduction is in `draft.md`. It will later be migrated to LaTeX. Do not edit it during the review unless explicitly asked.

## Proposed funnel

Use five conceptual layers, followed by a contribution paragraph:

1. **Power-converter regulation**
   - Converters regulate electrical variables through semiconductor switching.
   - Switching schedules must respect implementation constraints, including switching frequency and minimum dwell duration.
   - Establish the broad question of producing an executable schedule.

2. **Constrained switched control**
   - Locate predictive or optimal control and static feedback as broad alternatives.
   - Predictive methods enforce constraints explicitly but require online optimization.
   - Static feedback removes the solver but does not guarantee a feasible requested action.
   - Narrow toward solver-free feedback.

3. **Fixed-period prescribed schedules**
   - The mode sequence, number of intervals, cycle boundaries, and period are fixed.
   - The controller moves only interior switching instants.
   - The target is a reference periodic trajectory, not an equilibrium.
   - Define this setting positively before distinguishing it from mode selection, hysteresis, or online schedule reconstruction.

4. **Cycle-to-cycle switching-time feedback**
   - At each cycle start, static feedback maps the cycle-start error to offsets for the next cycle's interior switching instants.
   - A one-cycle model relates those offsets to the next cycle-start state.
   - Place Patiño and Marcolino here as prior foundations.
   - Make clear that the paper does not propose a new LQR or feedback synthesis.

5. **Dwell-feasible static timing actions**
   - Each interior switching instant affects two adjacent dwell durations, so the constraints couple the timing coordinates.
   - Raw static feedback can request an infeasible schedule.
   - Independent clipping changes the requested direction and does not respect the coupled structure.
   - Online constrained optimization restores feasibility but loses the solver-free advantage.
   - End with the research question: how can a raw switching-instant offset be made dwell-feasible without online optimization while preserving its direction and the fixed-period schedule?

6. **Contribution landing, not another domain layer**
   - Apply the largest feasible scalar in `[0,1]` to the complete raw offset vector.
   - Compute it with an `O(N)` scan.
   - Preserve direction, mode order, and fixed period.
   - Use `A(beta) = (1-beta) Phi + beta Acl` and a common quadratic Lyapunov certificate for the endpoints.
   - State boundaries: no new LQR synthesis, no new reference-schedule optimization, no global nonlinear claim, and simulation rather than hardware validation.

The proposed concise positioning is:

> power converters -> constrained switching control -> prescribed fixed-period schedules -> cycle-to-cycle switching-time feedback -> dwell-feasible static timing actions -> maximal radial conditioning and certification

The proposed exact research area is the intersection of fixed-period switching-time control, solver-free minimum-dwell enforcement, and stability certification under state-dependent action scaling.

## Diagnosis of the current draft

The current first paragraph crosses converter switching, hardware limits, predictive control, optimization literature, static feedback, and infeasible actions before defining the paper's control architecture. The second paragraph defines the setting mainly through exclusions. The proposal instead delays the dwell-feasibility problem until the reader understands the prescribed schedule, timing coordinates, and cycle-to-cycle feedback.

## Review questions

1. Is power-converter control the right broadest layer, or should the introduction begin one level above or below it?
2. Are any proposed layers redundant or missing?
3. Does the sequence establish a causal narrowing, rather than merely classify neighboring literature?
4. Is the predictive-control versus static-feedback contrast accurate and fair?
5. Does the proposed landing overstate novelty or the stability result?
6. Where should the closest literature enter without turning the opening into a citation catalogue?
7. Should the final introduction use six paragraphs as proposed, or combine some layers?

Return a concrete recommendation. Identify the strongest part, the weakest transition, any technical mischaracterization, and a revised layer sequence if different. Do not rewrite the full introduction yet.

## Constraints

- Preserve the canonical terminology in `CONTEXT.md`.
- Treat dwell-time conditioning and the common-Lyapunov certificate as the central contribution.
- Treat the one-cycle derivation and validation as enabling contributions.
- Avoid first-ever, global-stability, and hardware-validated claims.
- Keep the eventual paper within its 8–10 page target.
- Prefer a short, causal introduction over a comprehensive literature survey.

## Suggested skills

- `shared-understanding` for evaluating the conceptual sequence and tradeoffs.
- `unslop` for checking clarity, density, and formulaic academic phrasing.
- `research` only if a technical positioning claim cannot be resolved from the existing project knowledge and reference summaries.
