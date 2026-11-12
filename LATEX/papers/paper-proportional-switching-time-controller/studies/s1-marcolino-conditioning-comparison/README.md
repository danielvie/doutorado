# Comparison of fixed and relaxed final cycle boundaries

The active study compares `daniel`, `daniel-relaxed`, and `marcolino` using the article's same aggressive LQR gain. `daniel-relaxed` restores the handoff's rule: maximize common interior-offset scaling without the last dwell constraint, then minimally extend the final boundary. The next cycle starts at that actual end. No gain redesign or phase compensation occurs.

## Saved reference reports

Both PDF comparisons are preserved in [studies/report/](../report/README.md), with the shared filename prefix `conditioning-comparison-`: the Daniel/Marcolino results-and-comments report and the shortened three-method relaxed comparison. These copies are not overwritten by study tasks. Sources and numerical evidence remain in `report/` and `results/`.

## New three-policy report

From this study directory:

```sh
task run    # Tests, fresh 1x/2x/3x evidence, and PDF build
task test   # Small and randomized relaxed-conditioner checks
task build  # PDF from saved evidence only
task clean  # Compilation intermediates only
```

From the paper directory, numerical generation alone is:

```sh
matlab -batch "addpath('studies/marcolino-conditioning-comparison'); run_relaxed_comparison;"
```

The new [report source](report/relaxed-last-switch-results.tex) compiles to [relaxed-last-switch-results.pdf](report/relaxed-last-switch-results.pdf). The PDF contains the three 3x comparison figures, each with one short descriptive paragraph. Full numerical evidence for 1x, 2x, and 3x initial displacement remains in the results folders. All fresh outputs are isolated under `results/relaxed-last-switch/error-scale-1x/`, `error-scale-2x/`, and `error-scale-3x/`. Each case exports CSV evidence, `study.mat`, generated report tables, and PDF/PNG comparisons, early responses, and state trajectories. The field `daniel_relaxed` in MATLAB and CSV prefixes identifies `daniel-relaxed`.

At 1x the relaxed policy crosses the anchor threshold at cycle 5 versus Daniel's cycle 6. At 2x and 3x it retains Daniel's crossing cycles, 8 and 12, but reaches them later in physical time. Its final fixed-clock error stays near 0.025 in all three cases. Conditioning, beta-active, and terminal-extension counts are separate. Marcolino has no scalar beta. Returning to 286 µs durations does not cancel earlier clock displacement.

`relaxed_dwell_condition.m` contains the restored algorithm. `test_relaxed_dwell_condition.m` checks feasibility, maximal interior scaling, and minimal extension. `run_comparison.m` now simulates all three policies; the wrapper also checks the full-precision 3x handoff values. The article's fixed-period common-P certificate does not cover active terminal extensions. Publication scripts, data, and manuscript remain unchanged.

## Previous two-policy evidence

The following sections describe the retained Daniel/Marcolino runs and the previous `results-and-comments.tex` report. They are historical two-policy evidence, not the new three-policy dataset. The new wrapper does not overwrite them. Calling `run_comparison` directly now produces three-policy outputs in its selected folder; use the wrapper above to keep the new evidence isolated.

### Previous reproduction

From the paper directory, with MATLAB and Control System Toolbox available:

```sh
matlab -batch "addpath('studies/marcolino-conditioning-comparison'); run_comparison;"
```

The command writes `results/metrics.csv`, `results/cycle_history.csv`, [per-cycle durations](results/cycle_duration.csv), `results/first_cycle_dwell.csv`, `results/comparison.pdf` and `.png`, an [article-style comparison with Marcolino added](results/article_response_with_marcolino.pdf), and the [state-trajectory figure](results/state_trajectories.pdf) with [PNG preview](results/state_trajectories.png) and [exact dense samples](results/trajectory_samples.csv). The standalone [TeX report](report/results-and-comments.tex) now presents the **3× initial-error trial**, using only figures in `results/error-scale-3x/`. Build it from `report/` with `latexmk -pdf -outdir=build results-and-comments.tex` after running `run_comparison([],3)`. The unchanged article-state data and figures remain in `results/`. `run_comparison.m` uses the article's `paper.benchmark`, `paper.validate_model`, `paper.design_feedback`, physical initial state, and exact switched-affine propagation. It checks the uniform response against `results/conditioned_control_response.csv` when that publication file is present. `sequential_dwell_condition.m` implements the other actuator rule independently.

## Setup and interpretation

Both runs use the published nine-interval reconciled schedule, nominal period 286 µs, 3 µs applied minimum dwell, 100 cycles, the same initial state `[7.5143; 20.8211; 0.0314]`, the same cycle anchor, and the aggressive physical LQR gain designed with normalized input weight 0.001. At each *actual* cycle start, the controller computes the raw eight-offset vector `-K(x - orbit_anchor)`.

- **Daniel (uniform scaling):** apply the largest feasible common factor `beta` to all eight raw offsets. The cycle ends at exactly 286 µs. This is the article's policy.
- **Marcolino (sequential delay):** starting at the current cycle boundary, each interior switch occurs at `max(requested switch, preceding actual switch + 3 µs)`. The final switch occurs at `max(nominal end, last actual switch + 3 µs)`. It can extend the cycle. The next cycle starts at that delayed end. This adapts Marcolino et al.'s Algorithm 1 to this converter; their paper treats a switched actuator of an LTI plant, not this mode-dependent switched-affine converter.

Each run propagates the **same exact mode-dependent plant** for its own realized dwell durations. The LQR gain is not redesigned after cycle extension. The article's fixed-period common-`P` certificate applies to Daniel's conditioned linearized family, not Marcolino's delay rule. This is a controlled comparison of actuator rules, not a claim that Marcolino et al. analyzed this converter.

Two different targets matter. The *moving-anchor error* (called `phase_reset_error` in the CSV) compares the state at each actual cycle start with the nominal orbit anchor, as if a desired orbit restarted whenever that method begins a cycle. The *fixed-clock tracking error* (called `global_phase_error` in the CSV) compares that state at its actual elapsed time with the original fixed-period orbit `x_ref(t mod 286 µs)`. They coincide for Daniel, but not necessarily for Marcolino. **Reaching the moving anchor sooner does not mean tracking the original clocked trajectory sooner.** The chart shows both errors.

The middle panel plots **the length of each realized cycle**, rather than cumulative schedule delay. It shows the first 12 cycles so the transient is legible. The exact values for all 100 cycles are in [cycle_duration.csv](results/cycle_duration.csv). Returning to 286 µs means that each *subsequent* cycle has its nominal length. It does not undo the additional elapsed time from earlier extended cycles. `cycle_history.csv` retains the cumulative boundary offset for interpreting the original-clock error, but it is not the main figure's timing metric.

## Article Figure 4 and the study remake

The [clipboard image of the article's Figure 4](reference/article-figure-4-conditioned-response.png) is kept unchanged as reference material. It shows **Daniel versus open loop** for the article's original initial state, not Marcolino, and is not an output of this study. The article's underlying vector source is `latex/figures/conditioned_control_response.pdf` at the paper root.

The separate [study remake](results/article_response_with_marcolino.pdf) shows the first 25 cycles with **Daniel, Marcolino, and open loop** on the error panel. It also shows Marcolino's error against the original clock. Panel (b) gives Daniel's beta on the left axis and the **number of switches postponed** by Marcolino on the right. Marcolino has no common scaling factor, so these are distinct quantities, not competing estimates of beta. Panel (c) compares both policies' raw requested and actual minimum dwells. This figure is regenerated by `run_comparison.m`; it does not edit or replace the article's original figure.

## Article initial state

| Metric over 100 cycles | Daniel | Marcolino |
| --- | ---: | ---: |
| Minimum realized dwell | 3 µs | 3 µs |
| Cycles requiring conditioning | 3 | 2 |
| Cycles extended past 286 µs | 0 | 2 |
| Longest cycle | 286 µs | 332.0447 µs |
| Cycle length after the transient | 286 µs | 286 µs |
| First sustained moving-anchor error below 0.01 | cycle 6, 1.716 ms | cycle 4, 1.1968 ms |
| Moving-anchor error at cycle 100 | below 2e-15 | below 2e-15 |
| Original-clock error at cycle 100 | below 2e-15 | 0.050544 |
| Sustained original-clock error below 0.01 | cycle 6 | not in 100 cycles |

In the first cycle the raw requested final dwell is **−43.0447 µs**, and several other requested dwells are negative. Daniel's rule applies `beta = 0.293978` and keeps every period at 286 µs. Marcolino's first two cycles last 332.0447 and 292.7815 µs; cycles 3 onward last 286 µs. At Marcolino's fourth cycle boundary, 1.1968 ms after the start, the state is 0.00753 from the **anchor** and 0.04660 from the original reference at that **same instant**. Only the anchor error is below 0.01. Although the period has returned to 286 µs, the earlier extensions have not been canceled, so its anchor error can approach zero while its fixed-clock tracking error remains near 0.05054. Daniel's fixed-clock error first stays below 0.01 at its sixth boundary, 1.716 ms. Moving-anchor crossings do not establish faster tracking of the original fixed-clock reference by Marcolino.

The state-trajectory figure overlays both exact converter responses with the original fixed-clock reference for the first 12 nominal periods, 3.432 ms. The upper-left panel shows the three-dimensional state-space paths; the other panels show $v_{C1}$, $v_{C2}$, and $i_L$ against physical time. Each mode interval has 30 exact samples. The response time grids differ and are not interpolated onto each other. The CSV retains every sample through each method's twelfth complete cycle, while the figure restricts both to the common 3.432 ms time window. Blue denotes Daniel and orange Marcolino.

The cycle-sampled squared-error sum in `metrics.csv` compares phase-reset errors at different physical times; it is not a common-clock tracking cost. The article's common-`P` result covers the uniform-scaling linearized family, **not** the sequential-delay map. These numerical trajectories establish no general stability or performance ranking between the two policies.

## Doubled initial-error trial

Run `run_comparison([],2)` to double the article's initial displacement from the orbit anchor without changing the gain, model, or publication data. It writes to an isolated [error-scale-2x/](results/error-scale-2x/README.md) subfolder, including separate [metrics](results/error-scale-2x/metrics.csv), [comparison figure](results/error-scale-2x/comparison.pdf), [article-style comparison](results/error-scale-2x/article_response_with_marcolino.pdf), and [state trajectories](results/error-scale-2x/state_trajectories.pdf). The trial begins at `[5.1039; 22.3494; -0.9195]`, so its negative inductor current is a physical-applicability caveat. Read the case's README before interpreting its convergence or fixed-clock phase shift.

## Tripled initial-error trial

Run `run_comparison([],3)` to triple the displacement from the **article** initial state, not from the 2× case. Outputs for both methods are isolated under [error-scale-3x/](results/error-scale-3x/README.md). The [duration figure](results/error-scale-3x/comparison.pdf) shows Marcolino's cycle length returning to 286 µs after four extended cycles; its [per-cycle data](results/error-scale-3x/cycle_duration.csv) records every cycle. This initial state also has negative current. The accumulated extensions are close to a whole 286 µs period, so the small original-clock error in [the metrics](results/error-scale-3x/metrics.csv) must not be interpreted as recovery of the original schedule. The separate case README explains this phase-wrap effect.
