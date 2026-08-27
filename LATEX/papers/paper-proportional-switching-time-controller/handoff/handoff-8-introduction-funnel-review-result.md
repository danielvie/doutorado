# Handoff: introduction funnel review result

## Purpose

Carry the completed review of the proposed introduction funnel into the rewrite of
`draft.md`. The review requested by `handoff/handoff-7-review-introduction-funnel.md`
is finished. This document records its conclusions and the decisions the user made
afterwards. `draft.md` was not edited.

## Authoritative context

Read `handoff/handoff-7-review-introduction-funnel.md` first for the funnel that was
reviewed and the review questions. Then read `draft.md`, `GOAL.md`, and `CONTEXT.md`.
The knowledge files under `project-knowledge/` were consulted during the review and
did not need correction.

## Review verdict

The funnel's content is sound; its six-paragraph shape is not. Four paragraphs are
recommended, matching the count `draft.md` already has. The rewrite is a re-ordering
plus one added clause, not an expansion. Six paragraphs would cost roughly 1.5 pages
of the 8-10 page budget.

### Strongest part

Proposed layer 5. The dwell-coupling argument - each interior switching instant sets
two adjacent dwell durations, so the constraints couple, so per-coordinate clipping
changes the requested direction - is the causal hinge of the paper and correctly sits
last before the contribution. Layer 3's instruction to define the setting positively
before excluding neighbours is the other real improvement over the current draft.

### Weakest transition

Layer 2 to layer 3. The funnel interleaves two orthogonal axes: what is being
controlled (converter, switched-affine limit cycle, prescribed fixed-period schedule,
interior switching instants) and how the action is computed (online optimization
versus static feedback). The order runs A, B, A, A+B, B. Settling the first axis
completely before introducing the second removes the break.

### Technical corrections required

1. Cycle indexing is wrong in proposed layer 4 and in `draft.md` paragraph 2. Per
   `CONTEXT.md`, offsets are applied *during* the cycle whose start produced the
   error. Error at start of cycle k, offsets within cycle k, next cycle-start state
   k+1. Both places say "the next cycle's" switching instants.
2. The fast-MPC cluster (Stellato, Yang, Saeed, Augustine, Sakha) is largely
   finite-control-set or mode-selection MPC, a different decision variable. Cite it
   as evidence that online solver cost is a live concern, not as a competitor to
   solver-free timing feedback. The timing-parameterized predecessors are Patino and
   Marcolino. `draft.md` already does this correctly; the funnel would regress it.
3. "Static feedback removes the solver" overstates the ledger. It removes the
   *online* solver, replaced by offline LQR synthesis, an offline common-Lyapunov
   SDP, and a fixed-cost `O(N)` scan.
4. The two dwell bounds must not be conflated. Patino's `22 us` is a nominal
   benchmark-design constraint; the controller-applied bound is a separate assumed
   `3 us`. If the introduction states a number, it is the controller-applied one.
5. "Certification" unqualified overstates the result. The certificate covers the
   conditioned *linearized* family for arbitrary conditioning-factor sequences; the
   nonlinear statement is local and conditioning-inactive. `draft.md` handles this
   correctly in prose and the one-line positioning statement does not.
6. Keep Marcolino's diverging standalone-LQR comparison concrete. It is the
   documented instance of direction-breaking sequential saturation; the funnel
   dissolves it into an abstract claim.

### Missing beat

Projection onto the feasible dwell polytope is unaddressed and a referee will raise
it. One clause: it is a QP, so a solver, and it does not preserve direction. This is
the only genuinely missing element.

## Recommended four-paragraph sequence

1. **Setting, defined positively.** Prescribed, repeating, fixed-period sequence of
   affine modes tracking a reference periodic trajectory. Mode order, interval count,
   and both cycle boundaries fixed. The controller displaces only interior switching
   instants. Target is the cycle anchor, not an equilibrium. Hardware imposes a
   minimum dwell duration. (Funnel layers 1 and 3, positive half.)
2. **How timing actions are computed.** Online optimization enforces dwell
   constraints directly - Patino's sensitivities inside a predictive scheme,
   Marcolino's dwell-constrained predictive controller - at solver cost, a cost the
   finite-control-set literature works to reduce. Static timing feedback removes the
   online solver. Close with exclusions as one compact clause: not mode selection
   (Egidio, Russo), not hysteresis-band frequency regulation (Repecho), not online
   schedule rebuilding. (Funnel layers 2 and 4, plus layer 3's negative half.)
3. **The gap.** Dwell coupling. A raw static action can request an infeasible
   schedule. Per-coordinate clipping changes direction, with Marcolino's diverging
   comparison as the instance. Projection restores feasibility but is a solver and
   also leaves the ray. End on the research question. (Funnel layer 5 plus the
   missing beat.)
4. **Contribution and boundaries.** Largest feasible scalar in `[0,1]` on the
   complete raw vector via an `O(N)` scan; direction, mode order, and period
   preserved; `A(beta) = (1-beta) Phi + beta Acl` with a common quadratic Lyapunov
   certificate for the endpoints covering every conditioning sequence in the
   linearized model. Enabling contributions named as such. Boundaries and roadmap.
   (Funnel layer 6, unchanged - it is already correct.)

## Layer titles

The user rejected two of the funnel's titles as confusing. Diagnosis: the other four
name recognized research areas, while those two named the paper's own constructs, so
a reader cannot place them. The user wants identifiable areas, not claims or slogans.

Agreed replacements:

- "Fixed-period prescribed schedules" becomes **Switching-time control of periodic
  switched systems**, or **Switching-time control** if the shorter form is preferred,
  with "periodic" and "fixed-period" carried by the paragraph body.
- "Dwell-feasible static timing actions" becomes **Minimum dwell-time constraints**.

Resulting register, before the four-paragraph consolidation is applied:

1. Power-converter regulation
2. Constrained switched control
3. Switching-time control of periodic switched systems
4. Cycle-to-cycle switching-time feedback
5. Minimum dwell-time constraints
6. Contribution

These are working outline labels. They will not appear as headings in the paper.

## Next session

Rewrite the `draft.md` introduction to the four-paragraph sequence above, applying
the six technical corrections and adding the projection clause. `draft.md` is the
working file; migration to LaTeX comes later.

## Constraints

- Preserve the canonical terminology in `CONTEXT.md`.
- Dwell-time conditioning and the common-Lyapunov certificate are the central
  contribution; the one-cycle derivation and validation are enabling contributions.
- Avoid first-ever, global-stability, and hardware-validated claims.
- Keep the paper within its 8-10 page target.
- Prefer a short, causal introduction over a literature survey.

## Suggested skills

- `unslop` for the prose pass over the rewritten introduction.
- `shared-understanding` only if the four-paragraph consolidation is reopened.
- `research` only if a positioning claim cannot be settled from `project-knowledge/`
  and the existing reference summaries.
