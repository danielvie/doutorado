# Replace Lyapunov certificate with a constraint-admissible invariant region

## Next-session objective

Assess and, only after confirmation, change the paper from a common-Lyapunov certificate to a set-based analysis centered on the admissible region of the static switching-time controller.

Do not edit the article immediately. First confirm which set the paper should claim and compute.

For the propagation-notation work and current repository state, read `handoff/handoff-10-propagation-notation-and-stability.md` rather than repeating that history here.

## Assessment verdict

Replacing the common-Lyapunov section with the thesis finite-horizon feasibility projection is not recommended.

The thesis projection answers whether some freely chosen switching-offset sequence over a prediction horizon can satisfy the constraints and reach a terminal maximal admissible set. It is an MPC feasible set. It depends on future decision variables, a horizon, a terminal LQR law, and polytope projection.

The paper instead studies a fixed static law followed by a scalar conditioner. Once the cycle-start error is given, the raw action direction is fixed. There is no future control sequence to project out. Importing the thesis feasible set would reintroduce an optimization-based controller and weaken the paper's solver-free focus.

A better replacement is the maximal positively invariant subset of the paper's existing Raw-Action Admissible Region under the raw closed-loop matrix. This is the same terminal-set construction used inside the simulation MPC builder, but applied as the paper's primary set result rather than as an MPC terminal ingredient.

## Q1: Which region should replace the common-Lyapunov certificate?

Recommended answer: the maximal invariant raw-action admissible set, not the thesis finite-horizon MPC feasible set.

Rationale:

- It belongs to the static controller actually studied by the paper.
- It gives a nontrivial certified region where the raw feedback remains dwell-feasible at every future cycle.
- If the raw closed-loop matrix is Schur, every linearized trajectory starting in this set stays feasible and converges to the cycle anchor.
- It requires no online solver. The polytope is computed offline.
- It avoids claiming that feasibility alone proves stability.

This recommendation is not yet a settled project decision. Do not update `GOAL.md` until the user confirms it.

## Important distinction between candidate sets

### Raw-Action Admissible Region

Already defined in `article.tex` by `eq:admissible-region`.

It contains cycle-start errors for which the unconditioned static action satisfies every minimum dwell-duration constraint in the current cycle. It is a direct polyhedron because the action is fixed by the feedback gain.

This set alone is not invariant and is not a stability proof.

### Conditioned-action feasible set

Under the current assumptions, the conditioner can always shrink the raw action to zero. Since the nominal schedule has strict dwell margin, the applied schedule is feasible for every error for which the linear feedback is defined.

Therefore, a plain "feasibility region of the conditioned controller" is effectively the whole state-error space and is not an informative figure or contribution.

### Maximal invariant raw-action admissible set

This is the largest subset of the Raw-Action Admissible Region that remains inside that region under repeated application of the raw closed-loop matrix.

Inside this set:

- the conditioning factor remains one;
- the dwell constraints hold at every cycle;
- the raw closed-loop linear model applies without switching between conditioned matrices;
- Schur stability of the raw closed-loop matrix gives convergence.

This is the recommended set-based certificate.

### Thesis finite-horizon feasible set

This set contains states from which there exists an admissible sequence of future switching offsets that reaches a terminal invariant set in a chosen number of prediction steps.

It is appropriate for MPC, not for the paper's fixed proportional switching-time law. Use it only if the paper is intentionally changed into an MPC-feasibility paper, which is not recommended.

## Evidence from the simulation and thesis

### Active simulation

- `../../../simulations/matlab-sim/@Simulation/project_feasibility_region.m` is currently a stub. It retrieves `Phi` and `Gamma` but does not perform the projection.
- `../../../simulations/matlab-sim/+Runner/+Experiments/z_projection_patino2.m` contains the working MPT3 reconstruction.
- `../../../simulations/matlab-sim/+Mpc/build_problem.m` computes:
  - an LQR gain;
  - the raw closed-loop matrix;
  - the input-admissible state polyhedron;
  - a terminal invariant set through `LTISystem.invariantSet`;
  - lifted finite-horizon QP constraints.
- `../../../simulations/matlab-sim/DOCS/THEORY.md` explicitly says the projected set is current finite-horizon QP feasibility and is not by itself recursive feasibility.
- `../../../simulations/matlab-sim/python/project_patino2.py` reconstructs the same process through a terminal maximal admissible set followed by backward reachability.

The Python implementation adds numerical noise and has a bounding-box fallback that may inflate a region. It is useful for comparison but should not provide a certification figure for the paper.

### Historical thesis projection project

- `../../../simulations/projection/create_projection.m` builds a lifted polyhedron in future input and initial-state coordinates, then calls MPT3 projection to eliminate the future inputs.
- `../../../simulations/projection/determina_oinf.m` computes the terminal maximal admissible set under LQR.
- `../../../simulations/projection/projecao_patino2.m` uses older rounded matrices, older dwell bounds, and a five-input model that does not match the current paper's eight independent switching instants.
- `../../../simulations/projection/docs/context_projection.md` confirms that this is dual-mode MPC feasibility.

Do not reuse the historical numerical matrices or figures in the paper. Recompute any region from the current paper data.

### Thesis text

- `thesis/tex/chapters/cap4/cap4_application_examples_patino_2.tex` presents feasibility regions for prediction horizons one, two, and four.
- The thesis description is an MPC result and does not establish a region for the paper's scalar-conditioned proportional law.

## Proposed computation if Q1 is accepted

Use the current paper's normalized physical coordinates and matrices from `scripts/generate_results.m`.

1. Reuse the current nominal cycle matrix, timing Jacobian, state scaling, timing scaling, aggressive LQR gain, incidence matrix, nominal dwell vector, and applied minimum dwell duration.
2. Construct the Raw-Action Admissible Region directly from the dwell inequalities under the aggressive raw feedback law.
3. Form the aggressive raw closed-loop matrix.
4. Compute the maximal positively invariant subset of the Raw-Action Admissible Region.
   - Preferred implementation: MPT3 `LTISystem.invariantSet`, matching `+Mpc/build_problem.m`.
   - Acceptable fallback: explicit preimage intersection with redundancy removal until convergence.
5. Validate:
   - the origin lies in the strict interior;
   - every vertex satisfies the raw dwell constraints;
   - the image of every vertex lies in the invariant set;
   - the set computation converges;
   - the aggressive raw closed-loop matrix is Schur;
   - the paper's large-error initial state is classified correctly.
6. Plot in physical cycle-start-error coordinates.
   - Show the Raw-Action Admissible Region and its maximal invariant subset.
   - Overlay the large-error initial condition and the conditioned trajectory if readable.
   - State clearly whether the plot uses errors or absolute states.
7. Export deterministic metrics and a publication figure through the existing result-generation pipeline.

The three-state converter makes the set directly plottable. No state-space projection is required unless future input variables are introduced. Calling the direct three-dimensional set a "projection" would be misleading.

## Scientific claim available from the recommended set

For the linearized raw closed loop, an initial error inside the maximal invariant raw-action admissible set remains raw-action feasible for all future cycles. The conditioner stays inactive, and Schur stability of the raw closed-loop matrix gives convergence to the cycle anchor.

This is narrower than the current common-Lyapunov claim:

- It does not certify arbitrary conditioning-factor sequences.
- It does not certify the conditioned linear model outside the invariant raw-feasible set.
- It does not prove global nonlinear stability.
- Outside the set, the conditioner still guarantees the current schedule's dwell feasibility, but convergence remains simulation evidence.

For the exact nonlinear one-cycle map, the existing local argument can remain: strict nominal dwell margin makes conditioning inactive near the anchor, and a Schur Jacobian gives local exponential stability while mode order is preserved.

## Consequences for the paper

Replacing the common-Lyapunov result changes a stated central contribution in `GOAL.md`. If Q1 is accepted, update the goal and manuscript together.

Likely article changes:

1. Abstract:
   - remove the common-quadratic-Lyapunov claim;
   - add the constraint-admissible invariant-region result;
   - retain the solver-free conditioner and local nonlinear limitation.
2. Introduction:
   - replace the arbitrary-conditioning stability contribution with the set-based contribution.
3. Conditioning section:
   - retain the Raw-Action Admissible Region and conditioner feasibility/maximality proposition;
   - remove `prop:common-lyapunov` and the endpoint norm argument;
   - add the invariant raw-feasible set definition and proposition.
4. Case study:
   - replace the SDP certificate subsection with the computed polyhedral region and validation;
   - replace contraction-bound metrics with region facets, vertices, volume, ranges, invariance residual, and initial-state membership.
5. Figures and tables:
   - add one region figure;
   - preserve the current page and figure limits by replacing, not adding beside, Lyapunov-specific material.
6. Discussion and conclusion:
   - remove arbitrary-conditioning stability claims;
   - distinguish instantaneous conditioner feasibility from invariant raw-law feasibility;
   - state that conditioned behavior outside the invariant region is simulation evidence.
7. References:
   - reconsider citations used only for the common-Lyapunov argument;
   - add an authoritative maximal-admissible-set or invariant-set reference if the current bibliography lacks one.
8. Generated results:
   - remove common-`P` metrics only after the article no longer references them;
   - add region metrics and a reproducible computation task.

## Implementation locations

Preferred paper-side implementation:

- Add the region computation to `scripts/generate_results.m` only if it remains understandable there.
- Otherwise create one focused MATLAB script under `scripts/` and invoke it from `generate_results.m` or `Taskfile.yml`.
- Reuse existing dependencies and MPT3 patterns. Do not copy the historical projection project wholesale.
- Add or update a Taskfile task that reproduces the region figure and metrics.

Do not modify files in `../../../simulations/projection/` as part of the paper change. They are evidence and historical implementation, not the paper's source of truth.

## Risks

- The recommended result is a constraint-admissible region, not a replacement proof for all conditioned trajectories.
- The invariant region may be small because it requires the aggressive raw action to remain feasible forever.
- The current large-error initial state is likely outside the raw-action region because the first aggressive raw schedule contains a negative dwell. That is expected and should be shown rather than hidden.
- MPT3 polytope computations require numerical scaling and independent checks. A visually plausible plot is not enough.
- If the invariant set is unbounded, empty, lower-dimensional, or numerically unstable, reassess the gain, coordinates, or claimed set before changing the article.
- The historical thesis projection uses incompatible matrices and must not be treated as current evidence.

## No implementation performed

This session only assessed the strategy and created this handoff. It did not change:

- `article.tex`;
- `GOAL.md`;
- `CONTEXT.md`;
- MATLAB scripts;
- generated figures or metrics.

## Suggested skills

- `shared-understanding`: resolve Q1 before changing the scientific claim.
- `domain-modeling`: update the distinction among Raw-Action Admissible Region, maximal invariant raw-action admissible set, and MPC finite-horizon feasible set.
- `research`: find and verify a primary reference for maximal admissible and positively invariant sets if needed.
- `how`: trace the MPT3 invariant-set computation and result-generation pipeline.
- `mado-html`: create any equation-heavy strategy explanation as a new standalone HTML document.
- `unslop`: keep the manuscript precise and avoid presenting feasibility as stability.
