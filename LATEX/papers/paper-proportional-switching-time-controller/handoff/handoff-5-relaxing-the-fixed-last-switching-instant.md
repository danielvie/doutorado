# Handoff: removed terminal-delay conditioning variant

## Purpose and current status

Preserve the algorithm and numerical findings of **Daniel-with-last**, an experimental variable-period variant of the article's conditioner.

The variant was implemented, simulated, compared with Daniel and Marcolino, then **removed at the user's request**. The user chose to retain Daniel's fixed final cycle boundary. This handoff preserves knowledge; it does not authorize restoring the variant to the active study or manuscript.

**Evidence status:** the numbers below were recovered from MATLAB outputs and file contents shown earlier in this conversation, before removal. The current study CSVs, figures, report, and code were subsequently regenerated with only Daniel and Marcolino. They do **not** retain the variant's evidence. This handoff is a historical transcription, not a new execution or an independently revalidated dataset.

## Where to resume

Paths below are relative to the paper directory. Chat links should use absolute paths.

- `project-knowledge/README.md`: required orientation.
- `GOAL.md`, `CONTEXT.md`: fixed-period objective and canonical terminology.
- `scripts/README.md`: numerical pipeline and source ownership.
- `scripts/+paper/benchmark.m`: actual benchmark, scales, schedule, and initial state.
- `scripts/+paper/design_feedback.m`: shared aggressive LQR gain.
- `scripts/condition_dwell_times.m`: original fixed-period conditioner, unchanged by this experiment.
- `studies/marcolino-conditioning-comparison/run_comparison.m`: current two-policy simulation, error evaluation, trajectory sampling, and exports.
- `studies/marcolino-conditioning-comparison/sequential_dwell_condition.m`: current Marcolino adaptation.
- `studies/marcolino-conditioning-comparison/plot_article_response_comparison.m`: current two-policy early-response plot.
- `studies/marcolino-conditioning-comparison/README.md`: current study scope and commands.
- `studies/marcolino-conditioning-comparison/report/results-and-comments.tex`: current report uses the **3× case**, with only two methods.
- `studies/lyapunov/analysis.jl`: article's current fixed-period common-P certificate, not a certificate for the removed variant.

The removed helper was `studies/marcolino-conditioning-comparison/condition_with_last_dwell.m`. Its file was deleted; all calls, exported fields, curves, and documentation were removed. At the last check, the study folder was untracked in Git, so do not assume the variant can be recovered from a commit.

## Exact variant definition

Use the same cycle-start feedback command as Daniel:

```text
raw = -K * (actual cycle-start state - cycle anchor)
```

For nominal boundaries `r[0..N]`, with `r[0]=0` and `r[N]=T`, define nominal dwells, margins, and raw dwell changes:

```text
nominal_dwell = diff(r)
margin = nominal_dwell - minimum_dwell
q = diff([0, raw[1..N-1], 0])
```

Original Daniel chooses beta using **all N dwell constraints** and fixes `actual[N]=T`.

Daniel-with-last chooses beta using **only dwells 1 through N−1**. It scales every interior offset by that common factor, then repairs the last dwell by delaying the final boundary:

```text
beta = 1
for i = 1 to N-1:
    if q[i] < 0:
        beta = min(beta, margin[i] / (-q[i]))

actual[0] = 0
for i = 1 to N-1:
    actual[i] = r[i] + beta * raw[i]
actual[N] = max(T, actual[N-1] + minimum_dwell)

applied_dwell = diff(actual)
next cycle starts at this actual[N]
```

This is not the sequential Marcolino repair. Interior instants are not individually postponed; their offsets remain on the raw timing-command ray. The final boundary's additional displacement means that the **complete schedule** no longer preserves the original fixed-period direction or zero-sum dwell changes.

The variant uses the minimal terminal extension compatible with its selected beta. It does not optimize the extension, choose a larger beta beyond interior feasibility, redesign K, or cancel previous extensions in later cycles.

### Small checks used when implemented

Times here are arbitrary units; minimum dwell is 2:

- `r=[0,5,9,12]`, `raw=[3,2]`: beta 1, actual `[0,8,11,13]`. Interior dwells are feasible; the last boundary must extend.
- `r=[0,5,9,12]`, `raw=[0,-5]`: beta 0.4, actual `[0,5,7,12]`. An interior dwell restricts beta; no final extension is needed.

Both checks passed in MATLAB. Full runs also checked minimum dwell feasibility, finite states, common initial raw commands across methods, and dense-sampling agreement with exact cycle endpoints.

## Simulation configuration

The experiment reused the article benchmark and gain, without modifying publication inputs:

- Three-cell converter with nine mode intervals and eight interior offsets.
- Reconciled nominal schedule, nominal period **286 µs**.
- Applied minimum dwell **3 µs**. The separate **22 µs** nominal-design bound was not used as the applied bound.
- Cycle anchor `[9.9247; 19.2928; 0.9823]`.
- State normalization `Sx=diag(10,20,1)`; timing scale 10 µs.
- Aggressive LQR: normalized Q=I and R=0.001I, same physical K for every policy and initial condition.
- Exact switched-affine propagation using each run's actual dwells, not the linearized prediction in place of the plant.
- 100 completed cycles per policy; actual elapsed times differed if cycles extended.
- Feedback calculated at each actual cycle start against the unchanged cycle anchor.

Initial states were generated by `anchor + scale * (article_initial_state - anchor)`:

| Scale | Initial state | Initial normalized error |
| --- | --- | ---: |
| 1× | `[7.5143; 20.8211; 0.0314]` | 0.983946311454543 |
| 2× | `[5.1039; 22.3494; -0.9195]` | 1.96789262290909 |
| 3× | `[2.6935; 23.8777; -1.8704]` | 2.95183893436363 |

The negative starting currents in the 2× and 3× trials are physical-applicability caveats. These were mathematical-model stress tests, not hardware validation.

## Historical Daniel-with-last results

Threshold is normalized error 0.01. Anchor crossings were both first and sustained over the recorded horizon. Conditioning count meant **beta below one OR an active terminal extension**, whereas original Daniel's count meant beta below one. For the 3× variant, beta itself was below one in ten cycles.

| Metric | 1× | 2× | 3× |
| --- | ---: | ---: | ---: |
| Cycles with conditioning | 2 | 6 | 10 |
| Cycles with terminal extension | 2 | 3 | 3 |
| Maximum cycle duration, µs | 304.401806440967 | 304.401806440967 | 304.401806440967 |
| Final cycle duration, µs | 286 | 286 | 286 |
| Anchor-error threshold crossing, cycle | 5 | 8 | 12 |
| Elapsed time at anchor crossing, ms | 1.4553, rounded | 2.3139, rounded | 3.45777401230598 |
| Final anchor error | 1.6582e-15, rounded | 1.6582e-15, rounded | 2.06883142109012e-15 |
| Final fixed-clock error | 0.024521, rounded | 0.025083, rounded | 0.024994326618953 |
| Sustained fixed-clock threshold crossing | none in 100 cycles | none in 100 cycles | none in 100 cycles |
| Sum of squared cycle-sampled anchor errors | 1.2581, rounded | 6.8384, rounded | 19.4485500602921 |
| Total elapsed time after 100 cycles, ms | 28.625, rounded | 28.626, rounded | 28.625774012306 |
| Minimum applied dwell | 3 µs | 3 µs | 3 µs |

Do not invent full precision for entries marked rounded. The lower sampled-error sum is not a common-clock integral tracking cost.

### Detailed 3× transient

- Original Daniel beta at cycle zero: **0.0979927491805505**.
- Variant beta at cycle zero: **0.192046815252170**.
- Variant first three durations: **304.401806440967**, **292.994304441994**, **286.377901423019 µs**.
- Duration from cycle 4 onward: **286 µs**.
- Total uncanceled boundary displacement: **25.77401230598 µs**.
- Both Daniel variants had beta below one for cycles `k=0..9`, then beta 1 from `k=10`.
- Variant anchor error after cycle 1: **2.03559749383154**, versus original Daniel **2.17555147697882**.
- Variant anchor error at cycle 12: **0.0058920730604047**, versus Daniel **0.00760859887911357**.
- Variant fixed-clock error at its cycle-12 boundary: **0.0296802472693645**, above 0.01 despite the anchor crossing.

The first cycle's interior bottleneck moved from the last dwell under Daniel to **dwell 7** under the variant. The first-cycle variant dwells in µs were:

```text
[55.1356957617507, 9.62331096962922, 29.1366772344839,
 64.1544003774361, 20.6640913867761, 21.9921901555372,
 3, 97.695440555354, 3]
```

Removing the last-dwell restriction did not remove the other coupled dwell constraints.

### Comparison at 3×

| Metric | Daniel | Daniel-with-last | Marcolino |
| --- | ---: | ---: | ---: |
| Anchor crossing, cycle | 12 | 12 | 7 |
| Time at anchor crossing, ms | 3.432 | 3.457774 | 2.293038 |
| Cycles with conditioning | 10 | 10 | 5 |
| Extended cycles | 0 | 3 | 4 |
| First-cycle length, µs | 286 | 304.401806 | 462.478950 |
| Final fixed-clock error | about 2e-15 | 0.024994 | 0.004936 |

The variant slightly lowered anchor error at corresponding cycle numbers but did not improve the selected crossing cycle; its accumulated extension made that crossing later in physical time. No general performance ranking follows from these trials.

## Interpretation and theoretical limits

1. **Timing direction is not state steering speed.** Uniform scaling preserves the vector of interior timing offsets, not the complete state velocity. A tight interior dwell can still restrict all components.
2. **Two reference errors were retained.** Anchor error compares `x(s_k)` with the cycle anchor. Fixed-clock error compares `x(s_k)` with the original periodic reference at `s_k mod T`. These are different for any variable-period schedule. Both were sampled at actual cycle starts, not matched physical-time samples.
3. **Period recovery is not phase recovery.** Returning to 286 µs after early extensions does not remove their accumulated displacement. The user preferred a chart of individual cycle durations over a cumulative-delay chart; the latter remains only in supporting CSV fields.
4. **Periodic phase wrap matters.** Marcolino's 3× extensions total 291.038 µs, approximately one 286 µs period plus 5.038 µs. Its small fixed-clock error partly reflects that wrap. It does not imply it shortened later cycles or recovered the original switching schedule.
5. **No inherited common-P guarantee.** The manuscript fixes the final boundary to obtain zero-sum dwell changes and the family `A(beta)=Phi_x-beta*Gamma_tau*K`. Terminal extension adds state propagation not represented by that family. The saved certificate does not cover the variant while the delay is active. No new extended-cycle certificate was derived or solved.
6. **No LQR redesign occurred.** The experiment tested only a conditioner change with the current fixed-period gain. It did not establish that this gain is optimal for variable-period operation.

## Current workflow and restoration precautions

The current `run_comparison([],3)` regenerates **only Daniel and Marcolino**, not the removed variant. Its three PDF/PNG outputs are `comparison`, `article_response_with_marcolino`, and `state_trajectories`. The current report includes those two-policy 3× figures. There is no need to rerun anything for this knowledge handoff.

If the user explicitly requests further variant work:

- Keep it isolated from the article's `scripts/`, publication `results/`, `GOAL.md`, and adopted theorem.
- Reconstruct the helper using the exact rule and small checks above; reproduce results before citing this transcription as current evidence.
- Preserve original-state, 2×, and 3× evidence rather than mixing their figures. Earlier confusion arose because a compiled report still linked original-state figures while the new simulation was isolated under `error-scale-3x/`.
- Report beta-active cycles separately from terminal-extension cycles. Marcolino has no scalar beta; its delayed-switch count includes the final boundary and does not indicate whether feedback is active.
- Use the same gain and initial condition for a conditioner-only comparison. A gain redesign is a different experiment.
- Follow current project instructions: absolute chat links, study-local outputs, and a Taskfile for any new code project. Use `uv` for Python checks. MATLAB and `latexmk` were available during this session.

## Suggested skills

- `clear-explanations` and `unslop`: accurate distinctions between feasibility, convergence, clock phase, and guarantees.
- `shared-understanding`: if reconsidering whether fixed period is a hard requirement; read its linked guidance first.
- `mental-model`: explain timing-direction preservation versus state response, or interpret the two reference errors.
- `mado-html`: only if the user requests a new or revised interactive tutorial; not needed for restoring a MATLAB study.

Do not restore the removed variant merely because its implementation is described here. The latest user decision was to keep Daniel's final boundary fixed; this request is to preserve knowledge of the discarded experiment.
