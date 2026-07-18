# Thesis findings: unresolved domain decisions

## Scope and source authority

Primary source: `LATEX/thesis/tese.tex`. Its active chapter graph was traced from `tese.tex:346-358` through every active `\input` in Chapters 1–5, including the nested Chapter 2 trajectory files, all Chapter 3 MPC files, and all Chapter 4 linearization/application files. No active `\include{...}` was found; `\includegraphics` occurrences are not source includes. The MATLAB project and `CONTEXT.md` are compared below, but do not override the thesis.

## Decisions

### 1. Cycle-boundary regulation target

**Finding — regulate the cycle-boundary deviation to the nominal target periodic trajectory, hence to its cycle-start fixed point at the selected boundary; do not regulate directly to the separate desired operating point. Confidence: high.**

The thesis has two distinct layers:

1. **Trajectory design objective.** Chapter 2 searches for an optimal periodic/cyclic trajectory. The desired operation point is the average reference value `\bar{x}^\infty` in
   `J = \int_0^{T_p}(x(t)-\bar{x}^\infty)^TQ(x(t)-\bar{x}^\infty)dt`; the resulting trajectory is constrained by `x(0)=x(T_p)` (`LATEX/thesis/tex/chapters/cap2/cap2.tex:11-37`, label `eq:cap2:trajectory-optimization`). Application sections call this separate quantity `\bar{x}_{ref}` or “reference state vector” (`cap4_application_examples_integrador.tex:87-90`; `cap4_application_examples_patino_1.tex:33-40`; `cap4_application_examples_patino_2.tex:64-71`). It is a desired operating/average point used to select the orbit, not generally a point on that orbit.
2. **Cycle controller objective.** Chapter 4 assumes the nominal periodic switching signal `\bar{\sigma}(t)` and associated periodic/reference trajectory `\bar{x}(t)`, then perturbs switching instants so `x(t)` converges to `\bar{x}(t)` (`LATEX/thesis/tex/chapters/cap4/cap4_statement_problem.tex:12-15`). It defines
   `e(t)=x(t)-\bar{x}(\bar t)` and the cycle model
   `e(t_{j,N})=\Phi e(t_{j,0})+\Gamma\delta t[j]`
   (`cap4_linearization_instanteN.tex:81-115`, labels `eq:cap4:linearization-phi`, `eq:cap4:linearization-gamma`, `eq:cap4:linearization-final-error-result`, `eq:cap4:linearization-error-result-j`). Chapter 4 substitutes generic MPC state `x` with error `e` and input `u` with switching-time perturbation `\delta t` (`cap4_mpc_problem.tex:3-23`). Thus the regulated origin is zero **orbit deviation**, not the physical desired operating point.

At a fixed cycle-start section, periodicity makes `\bar{x}(t_{j,0})` the same nominal cycle-start state each cycle. The thesis computes this state from the one-cycle affine map:

`x(0)=(I-F_{N-1}\cdots F_0)^{-1}c`, with `x(t_N)=x(0)`

(`LATEX/thesis/tex/chapters/cap2/cap2_otim_get_x0.tex:47-78`, label `eq:cap2:x0-inverse-matrix`). In domain language this is the **nominal orbit anchor** or one-cycle-map fixed point, although the thesis itself calls it the “initial condition/state of the [nominal] target cyclic trajectory.”

Term mapping:

| Symbol/name | Thesis meaning |
|---|---|
| `x_0`, `x(0)` in Chapter 2 | Periodicity-derived initial state of the target periodic trajectory; mathematically the cycle-map fixed point/orbit anchor. |
| `\bar{x}(t)` | Nominal target periodic trajectory; also called reference trajectory. |
| `\bar{x}_0` in results | Initial position/condition of the target cyclic trajectory, i.e. orbit anchor. |
| `\bar{x}^\infty`, `\bar{x}_{ref}` | Desired average operating/reference point used in trajectory optimization; not necessarily the anchor. |
| `x_ref`/`xref` | MATLAB spelling corresponding to the trajectory-design reference above; no literal `xref` thesis symbol. |
| `x_target` | Current-code term, not a thesis symbol. For thesis-faithful cycle control it must equal the cycle-start nominal orbit state, not default to `xref`. |
| equilibrium | Explicitly rejected as the general objective: with dwell-time constraints, design should achieve a suitable limit cycle rather than an equilibrium (`cap1_introduction.tex:9-25`). No separate equilibrium is mathematically defined. |
| error | `e(t)=x(t)-\bar{x}(\bar t)`: actual state minus corresponding nominal-trajectory state (`cap4_linearization_instanteN.tex:81-96`). At the cycle start this is actual cycle input minus orbit anchor. |

**Project comparison.** `CONTEXT.md:55-91` correctly distinguishes desired operating point, orbit anchor, simulation initial state, tracking error, and model deviation. Current code does not preserve that distinction:

- `@Simulation/set_mpc.m:84-90` defaults `control.x_target` to `config.xref`.
- `+Controllers/MpcController.m:95-103` computes `ek = x - x_target` and feeds it to the orbit-deviation MPC.
- Therefore the default runtime controller targets the desired operating point, while the thesis model requires the nominal orbit anchor at the cycle boundary.

Recommended representation: retain `desired_operating_point`/`xref` only for nominal-trajectory design; retain an explicit immutable `orbit_anchor`; pass the orbit anchor as the cycle-boundary controller target, or pass the already computed orbit deviation directly.

### 2. Meaning and timing of `N_d`

**Finding — thesis prose defines `N_d` primarily as both the control hold length and lifted block length: one input remains constant for `N_d` consecutive cycles and one lifted transition spans those `N_d` cycles. It is not explicitly defined as processor/computation/physical actuation delay. Confidence: high for hold/block meaning; medium for application timing because the augmented equations conflict with the prose and standard MPC section.**

Authoritative prose and lifted model:

- “the control input will remain constant for `N_d` consecutive cycles” and the prediction is expanded over those steps (`LATEX/thesis/tex/chapters/cap3/cap3_augmented_states.tex:1-16`, section `sec:cap3:augmented-states`);
- `A_b=A^{N_d}` and `B_b=(A^{N_d-1}+\cdots+A^0)B` (`cap3_augmented_states.tex:19-32`; the source has subscript typos `N_{d-1}`);
- one new block-index transition corresponds to `N_d` original cycles (`cap3_augmented_states.tex:34-58`).

No active thesis text calls `N_d` a computation time, communication delay, processor delay, or physical actuation delay. Processor clock quantization is only proposed as future work (`LATEX/thesis/tex/chapters/cap5/cap5_conclusion.tex:32-40`).

**Timing contradiction:**

- Standard MPC says the first optimal input is applied to the plant (`cap3_custo.tex:49-58`). The cycle model places `\delta t[j]` in the same cycle transition from `e(t_{j,0})` to `e(t_{j,N})` (`cap4_linearization_instanteN.tex:103-115`). Together with the hold prose, this implies a newly computed `\delta t` applies immediately to the upcoming/current cycle and remains held for `N_d` cycles.
- The augmented equations instead define `X_a[k']=[x[k'];z[k'-1]]`, `z[k'-1]=u[k']`, and the new decision `z[k']=u[k'+1]`; the top block of `B_a` is zero (`cap3_augmented_states.tex:59-89`). Read literally, the newly optimized `z[k']` does not affect the current `N_d`-cycle block; it becomes the input of the next block, i.e. an **additional one-block (`N_d`-cycle) delay**.

Therefore the thesis does not support one unqualified timing answer. The least contradictory domain decision is:

- define `N_d` as **control update/hold period = lifted block length**;
- apply the newly computed action immediately and hold it for `N_d` cycles in the baseline model;
- if the augmented `z` indexing is intentional, model its one-block actuation delay as a separate explicit concept/parameter rather than silently folding it into `N_d`.

**Project comparison.** Runtime behavior is immediate sample-and-hold:

- `+Controllers/MpcController.m:59-89,121-124` computes on the first call, then returns the cached action until the next `N_d`-cycle update.
- `@Simulation/run.m:10-30` computes an action, applies it to the nominal switching instants, and only then propagates that same cycle. A newly computed `dtk` therefore applies immediately and is held for `N_d` cycles.

However, augmented prediction and runtime disagree:

- `+Mpc/build_augmented_model.m:25-38,45-69` implements the thesis block lift plus `z[k']=u[k'+1]`, explicitly describing command delay.
- `@Simulation/set_mpc.m:30-35,73-75` uses the same `options.Nd` for that delayed augmented model and for controller downsampling.
- `+Controllers/MpcController.m:98-123` includes the prior action in the augmented state but immediately returns and stores the newly optimized action; `run.m` applies it in the same cycle. Thus the predictor assumes next-block actuation while the plant simulation performs immediate actuation.

`CONTEXT.md:107-117` correctly describes held action and control update period, but omits that the thesis also uses the same `N_d` as the lifted block length and that its augmented equations imply a one-block delay.

### 3. Nominal orbit anchor versus simulation/disturbed state

**Finding — the thesis conceptually distinguishes them, but overloads `x_0` and is numerically inconsistent in examples. Represent them as separate fields. Confidence: high for the conceptual distinction; medium for exact example values/notation.**

Evidence:

- The periodic-trajectory `x(0)` is solved from periodicity (`cap2_otim_get_x0.tex:47-78`).
- Application setup calls `x_0` the “initial state of the nominal target trajectory” (`cap4_application_examples_integrador.tex:87-90`; `cap4_application_examples_patino_1.tex:33-40`; `cap4_application_examples_patino_2.tex:64-71`).
- Result sections separately start simulations from another `x_0` and identify `\bar{x}_0` as the target cyclic trajectory’s initial condition/position (`cap4_application_examples_integrador.tex:164-179`; `cap4_application_examples_patino_1.tex:105-115`; `cap4_application_examples_patino_2.tex:162-182`). The multilevel example explicitly says convergence to `\bar{x}_0` is equivalent to convergence to the desired limit cycle (`cap4_application_examples_patino_2.tex:168-170`).

Recommended representation:

- `orbit_anchor`: fixed point of the nominal one-cycle map; immutable with respect to a chosen nominal schedule;
- `simulation_initial_state`: actual state at the start of a run;
- `initial_state_disturbance = simulation_initial_state - orbit_anchor` when the run is initialized by perturbing the anchor;
- `cycle_input_state`: actual state at the start of each later cycle;
- `nominal_orbit_states`: `\bar{x}(\bar t_i)` at nominal switching instants.

Avoid using one mutable `x0` for all of these.

**Project comparison.** `CONTEXT.md:61-91` already recommends this separation. Current code still overloads `config.x0`:

- `+Dynamics/linearize.m:7-23` and `+Utils/get_xr.m:38-55` use it as the orbit anchor from which the nominal orbit is propagated.
- `@Simulation/run.m:4-12,64-67,76-101` also uses it as the simulation initial/cycle input state.
- `+Trajectory/Planner.m:77-100` computes the anchor, while `@Simulation/set_traj_phase_with_alpha.m:11-17` and `set_traj_phase_with_iref.m:11-17` store it into the same `config.x0` later used for simulation.

This makes an initial disturbance overwrite the nominal anchor used by subsequent linearization/reference-orbit calculations.

## Authoritative terminology

| Concept | Thesis terminology and notation | Comparison to `CONTEXT.md` / code |
|---|---|---|
| Switching mode | “switching state” or “operation mode,” `\sigma(t)`; dynamics are `A_{\sigma(t)},b_{\sigma(t)}` (`cap1_introduction.tex:3-7`; `listasimbolos.tex:13-14`). | Thesis does not cleanly distinguish physical switch state from dynamics index. `CONTEXT.md:15-29` is more precise but intentionally departs from thesis wording. |
| Mode sequence | “modes sequence,” “sequence of modes,” or “mode sequence,” `\Omega^\infty=[\sigma_1,\ldots,\sigma_{s^\infty}]` (`cap2.tex:18-31,47-53`). | `CONTEXT.md` says avoid “mode sequence” in favor of nominal switching schedule; clearer aggregate term, but not thesis terminology. Code uses `Omega` as a dynamics-index sequence. |
| Switching schedule/signal | “periodic switching signal” `\bar\sigma(t)`; target trajectory has optimal time sequence `\tau^\infty` plus mode sequence `\Omega^\infty` (`cap2.tex:18-31`; `cap4_statement_problem.tex:12-26`). | “Nominal switching schedule” in `CONTEXT.md:5-13` is a useful project term, absent verbatim from the thesis. |
| Switching instants/times | Both “switching instants” and “switching times.” `\bar t_{j,i}` is nominal/reference; `t_{j,i}` is perturbed (`cap4_statement_problem.tex:24-32`). | `CONTEXT.md:31-41` narrows “switching instant” to interior state-changing boundaries; thesis is less restrictive. |
| Dwell duration | “dwell time,” “switching time duration,” or minimum duration/time between switches; `t_i-t_{i-1}\ge\Delta t_{i,min}` (`cap2.tex:55-77`; `cap4_mpc_problem.tex:34-59`). | `CONTEXT.md:43-49` gives the clean elapsed-time definition. |
| `\delta t` | “perturbation” or difference/deviation of switching times: `t_{j,i}=\bar t_{j,i}+\delta t_{j,i}` and `\delta t[j]=t_j-\bar t_j` (`cap4_statement_problem.tex:24-32`; `cap4_mpc_problem.tex:26-32`). It shifts instants; it is not itself a dwell-duration change. | Aligns with `CONTEXT.md:51-53` and `compute_ts_from_dtk.m:1-13`. |
| `alpha` | No definition or occurrence in the active thesis TeX. | Code uses `alpha` as nominal duty ratio (`+Trajectory/Planner.m:28-48`); `CONTEXT.md:103-105` is code-authoritative, not thesis-authoritative, here. |
| Trajectory/orbit | “target periodic trajectory,” “target cyclic trajectory,” “cyclic trajectory,” “reference trajectory,” and “limit cycle”; `\bar x(t)` is the nominal/reference trajectory (`cap1_introduction.tex:37-46,57-66`; `cap4_statement_problem.tex:12-15`). “Orbit anchor” is not used. | `CONTEXT.md:55-63` introduces “nominal periodic orbit/orbit anchor” as precise project language. It faithfully names the mathematics but is not verbatim thesis terminology. |
| Feasibility | “feasibility region” `\mathcal D`: current states for which at least one predicted input sequence satisfies all state/input constraints over the selected finite horizon (`cap3_feasibility.tex:1-20,67-72`, section `sec:cap3:feasibility-region`). After Chapter 4’s `x\mapsto e` substitution, application feasibility regions are regions of cycle error. | `CONTEXT.md:119-121` calls this the finite-horizon feasible set and correctly avoids claiming recursive feasibility/recoverability. |

## Unresolved contradictions and source defects

1. **`N_d` timing:** hold/block prose and standard MPC imply immediate use; augmented `z` equations imply next-block use. Chapter 5 also calls augmented-state reimplementation future work despite Chapter 3 already containing an augmented-state section (`cap5_conclusion.tex:26-30`). This lowers confidence in treating the augmented section as settled implementation semantics.
2. **`x_0` notation and values:** `x_0` denotes both target-orbit initial state and disturbed simulation initial state. Example values also conflict: double-integrator setup gives nominal `x_0=[1.5,-1]` but results cite target `\bar x_0=[-0.5,-1]` (`cap4_application_examples_integrador.tex:87-90,164-168`); buck-boost setup gives `[1.8708,-1.1198]` but results cite `[1.8493,-1.1108]` (`cap4_application_examples_patino_1.tex:33-40,105-110`). These are likely draft/typographical defects; the conceptual distinction is clearer than the numbers.
3. **Reference notation:** Chapter 2 uses `\bar x^\infty` for the average desired point, examples use `\bar x_{ref}`, and Chapter 4 uses `\bar x(t)` for the entire reference trajectory. “Reference state” is therefore ambiguous unless qualified as desired operating point versus nominal-orbit state.
4. **`\delta t` dimension/endpoints:** `cap4_mpc_problem.tex:26-32` defines only `N-1` interior offsets, while `cap4_linearization_instanteN.tex:84-97` and later dwell matrices include `\delta t_N`. Current code consistently controls only interior boundaries (`p=numel(Omega)-1`). The thesis does not resolve whether the cycle-end instant is a decision variable or fixed to preserve the period.
5. **Linearization wording typo:** `cap4_statement_problem.tex:34-35` says deviation from `\hat x(t)`, but the derivation and formal error definition use `\bar x(t)`. The latter is mathematically consistent and should govern.
