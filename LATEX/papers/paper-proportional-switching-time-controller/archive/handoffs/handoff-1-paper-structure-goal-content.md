# Handoff: Decide Paper Structure, Goal, and Content

## Next-session objective

Review and refine the implemented focused manuscript. The scientific goal, relative novelty claim, evidence package, and section structure are agreed. Remaining publication decisions are venue selection, venue-specific formatting, and whether additional experimental or uncertainty evidence is required.

## Canonical sources

- Current manuscript: `article.tex`
- Agreed terminology: `CONTEXT.md`
- Generated numerical results: `results/metrics.csv` and `results/metrics.tex`
- Main experiment generator: `scripts/generate_results.m`
- Robust synthesis: `scripts/design_robust_controllers.m`
- Thesis trajectory closure derivation: `../../thesis/tex/chapters/cap2/cap2_otim_get_x0.tex`
- Thesis linearization setup: `../../thesis/tex/chapters/cap4/cap4_statement_problem.tex`
- Thesis endpoint linearization: `../../thesis/tex/chapters/cap4/cap4_linearization_instanteN.tex`
- Thesis MPC application: `../../thesis/tex/chapters/cap4/cap4_mpc_problem.tex`
- Wider-repository linearization notes, per `AGENTS.md`: `research-material/working-notes/linearization/linearization_v2_augmented.tex`

## Agreed scientific direction

The paper presents an approach for **local stabilization of a target limit cycle in a switched-affine system by adjusting switching instants**. The one-cycle linearization is the enabling method rather than the complete contribution.

Agreed scope:

- The one-cycle linearized model is controller-independent.
- A standard LQR demonstrates use of the model but is not a contribution.
- The case study adopts Patiño's published three-cell converter benchmark: its nine-mode sequence, `286 µs` period, and reported cycle-start state.
- Because the published numerical values are rounded, the nominal dwell durations are minimally adjusted to enforce exact cycle closure while preserving the period, reported cycle-start state, and `22 µs` nominal-design dwell bound.
- The paper does not rerun or claim the offline trajectory-optimization method.
- Robust control, conditioning theory, invariant regions, and common-Lyapunov analysis are outside the paper's scope.

## Agreed contribution framing

Center the paper on:

> An extension of cycle-to-cycle switching-time feedback from Marcolino's LTI plants with switched actuator levels to fixed sequences of general affine modes whose state matrices and affine vectors may both change. The approach derives a controller-independent one-cycle model in fixed-period switching-instant coordinates and uses standard discrete-time feedback for local target-limit-cycle stabilization.

Under this framing:

- trajectory generation is prior work/input data;
- LQR is an illustrative application, not a contribution;
- robust guaranteed-cost and H-infinity control are removed or deferred;
- direct validation of the analytical Jacobian and first-order model is essential;
- controller results demonstrate local stabilization of the nonlinear plant;
- no global-stability claim is made;
- Marcolino's propagation equation is shown explicitly as a special case;
- Patiño's earlier mode-dependent switching-instant sensitivity is acknowledged, so the paper does not claim that sensitivity formula as globally new.

## Existing manuscript currently tells three stories

1. One-cycle linearization with respect to switching instants.
2. Constraint-conditioned LQR with admissible and invariant regions plus a common-Lyapunov argument.
3. Robust nominal-LQR, guaranteed-cost, and H-infinity comparison.

The next session must decide which story is the paper and which material is supporting or out of scope.

## Agreed terminology

`CONTEXT.md` was updated during this session and is canonical.

- **Target limit cycle**: the isolated closed state-space behavior to be stabilized.
- **Reference periodic trajectory**: the time-parameterized trajectory that traces the target limit cycle.
- **Cycle anchor**, then **anchor**: the selected cycle-start point on the reference periodic trajectory and fixed point of the nominal one-cycle map.
- **Cycle-start state**: actual state at the beginning of a cycle.
- **Cycle-start error**: difference between cycle-start state and anchor.
- **One-cycle map**: exact boundary-to-boundary mapping.
- **One-cycle linearized model**: first-order approximation around the anchor and nominal schedule.

Use “limit cycle” for the control objective and stability discussion. Use “reference periodic trajectory” where timing and phase matter. Do not use “one-cycle state,” “orbit anchor,” “cycle input state,” or “orbit deviation.”

## Relevant evidence and concerns

### Missing evidence for the proposed primary contribution

The current manuscript validates controller behavior extensively but does not directly validate linearization accuracy.

Recommended evidence:

- compare the analytical switching-instant Jacobian with central finite differences;
- compare the exact one-cycle map with its linearized prediction;
- scale perturbations and demonstrate second-order residual decay.

### Main LQR experiment

The current gain is effectively deadbeat because switching offsets are expressed in seconds while the timing weight is the identity. Reported closed-loop spectral radius is approximately `5.86e-8`.

Consequences:

- timing effort is effectively unpenalized;
- equality of admissible and invariant regions is configuration-specific;
- machine-precision terminal error should not be described as a nonlinear residual floor;
- a normalized, physically meaningful LQR design is preferable if the controller example remains.

### Conditioning material

Still unresolved. Alternatives:

1. Remove conditioning theory and keep validation local enough that constraints remain inactive.
2. Retain a short feasibility mechanism as an implementation detail.
3. Keep conditioning, admissible regions, and stability as a second contribution—but accept a broader and less concise paper.

Recommended starting position: option 1 or 2.

### Robust material

Likely remove. It substantially expands the paper and introduces a separate scientific question.

There is also an unresolved robustness-certification issue: the cycle matrices depend nonlinearly on physical parameters, so checking endpoint combinations does not automatically prove convex-hull coverage of the full uncertainty box.

### Stability wording

A concise controller application can state:

- the linearized closed-loop matrix is Schur;
- under standard differentiability assumptions and inactive conditioning, this establishes local stability of the anchor and associated target limit cycle.

The current common-Lyapunov result should not claim that open-loop Schur stability alone guarantees a common quadratic Lyapunov function.

### Reference-schedule provenance

Patiño 2010 directly reports the converter parameters, physical mode sequence `[0,1,3,7,2,0,4,7,4]`, rounded switching boundaries `[0,66,88,110,132,154,220,242,264,286] µs`, and cycle-start state `[9.9247,19.2928,0.9823]`. The paper uses this as a precomputed benchmark. A one-time least-squares adjustment of the nominal dwell durations reconciles the rounded data with exact matrix-exponential propagation while preserving the `286 µs` period, reported anchor, and `22 µs` nominal-design dwell bound. The largest boundary adjustment is approximately `2.11 µs`.

The controller experiment uses a separate assumed `3 µs` applied-schedule minimum dwell duration. This is not presented as Patiño's hardware constraint. Phase-shifted modulation and the Solano reference are removed from the paper.

## Agreed paper structure

1. **Introduction** — local stabilization problem, literature gap, precise contribution.
2. **Problem formulation** — switched-affine plant, known reference periodic trajectory, anchor, switching-instant offsets, and assumptions.
3. **One-cycle linearization and stabilization** — exact map, fixed-period derivation, controller-ready model, and local Schur-stability result.
4. **Converter case study** — Patiño benchmark, exact-closure reconciliation, direct linearization validation, and normalized LQR illustration.
5. **Discussion** — scope, assumptions, limitations, and controller independence.
6. **Conclusion** — contribution and principal evidence.

Remove:

- robust-controller section and results;
- Monte Carlo comparison;
- guaranteed-cost and H-infinity LMIs;
- legacy schedule-repair narrative;
- extensive invariant-region and conditioned-loop analysis unless conditioning becomes an explicit contribution.

## Agreed presentation budget

Until a venue is selected, target a focused 8–10 page journal-style manuscript with at most four figures and two tables. The draft can later be compressed into a conference format.

## Interaction preferences

- Use the `shared-understanding` skill.
- Be concise and direct.
- Do not present raw LaTeX notation in chat; use readable prose and plain symbols.
- Challenge unsupported novelty or stability claims explicitly.
- Make no manuscript edits until the structure and scope are agreed.

## Workspace state

The focused implementation is complete:

- `article.tex` now follows the agreed 10-page method-first structure;
- `scripts/generate_results.m` uses the agreed closure-corrected Patiño benchmark and generates direct Jacobian, residual-scaling, and local-control evidence;
- the manuscript references only three focused figures and two tables;
- `task verify` regenerates the evidence and builds `article.pdf` successfully.

Legacy robust-control, conditioning, and invariant-region generated files remain in the working tree but are no longer generated or referenced. They were not deleted because they predate this focused rewrite. Do not overwrite or revert unrelated user changes.

## Suggested skills

- **shared-understanding** — primary skill for converging on goal, scope, evidence, and structure.
- **research** — use after the novelty question is precise, to compare the derivation against primary literature.
- **domain-modeling** — use only if the agreed terminology in `CONTEXT.md` needs further revision.
