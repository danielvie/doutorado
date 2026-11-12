# Daniel versus MPC

The working article section compares LQR-Daniel with five-cycle MPC using time-resolved error, cost, conditioning, and physical trajectories. The short report covers the same controllers. Earlier MPC-2 evidence is preserved under `archive/pre-mpc10/results/`; the completed MPC-10 comparison is preserved under `archive/with-mpc10/results/`.

## Commands

From the paper root:

```sh
task mpc-comparison:run   # Checks, fresh Daniel/MPC-5 simulations, both documents
task mpc-comparison:build # Rebuild report and timing table from saved evidence
task mpc-comparison:matched-timing # Matched state-to-schedule host benchmark, no propagation
task mpc-comparison:draft-figures # Check saved CSVs and redraw draft figures, no simulation
task mpc-comparison:draft # Build the separate article-section draft from saved figures, no MATLAB
task mpc-comparison:test  # Model, cost, and constraint checks
task mpc-comparison:clean # Remove compilation intermediates only
```

Requires MATLAB, Control System Toolbox, Optimization Toolbox, MPT3, and LaTeX. From this directory, omit the `mpc-comparison:` prefix.

## Comparison-section draft and agreed scope

`article-section.tex` is the separate working section for eventual article integration. `task mpc-comparison:draft` builds `build/article-section.pdf` without MATLAB. It does not modify or compile the main manuscript, and it does not replace the existing short evidence report in `report.tex`.

- D1: Accumulated tracking-and-timing cost is the primary performance measure. Report settling time, state excursions, failures, and computation separately.
- D2: First isolate the nominal-model tradeoff on the linearized cycle model, then repeat identical cases with exact switched-affine propagation. Add uncertainty and hardware effects later.
- D3: Develop the comparison section here before article integration. This staging step is complete; the approved compact integration is described in D9.
- D4: Support comparison claims with figures and refer to them in the text. Distinguish saved numerical evidence from conceptual illustrations and proposed experiments.
- D5: Previously use MPC-5 as the sole MPC comparator and preserve historical MPC-2 evidence. Superseded by D7.
- D6: Prefer time histories to sparse cost/settling bars and timing-summary plots. Retain scalar performance and timing values in a compact generated table.
- D7: Previously compare LQR-Daniel, MPC-5, and MPC-10 under matched conditions. Superseded by D8.
- D8: Return to LQR-Daniel versus MPC-5 only. Remove MPC-10 from the active runner, tests, figures, tables, and text; retain its completed evidence under `archive/with-mpc10/results/`.
- D9: Integrate only the original 1x case and matched full-controller timings into the article's existing figure/table, keeping the conditioner/certificate central, protecting the Introduction verbatim, and targeting 15 total pages. Keep broader cases and the standalone draft here.

`plot_article_figures.m` generates three PDF/PNG figures and `summary.tex` in `results/article-figures/`:

- `error-cost-histories`: error and cumulative cost over elapsed time at 1x/2x/3x; circles identify sustained threshold crossings.
- `conditioning-3x`: aligned error, Daniel's conditioning factor, and raw/applied minimum dwells over the first 25 periods. MPC-5 has no conditioning factor.
- `physical-trajectories-3x`: the state-space paths and all three physical states over the same twelve-period window, with a periodic reference and each response's original sample times.
- `summary.tex`: 100-cycle cost, sustained threshold time, median and p95 host computation time for both controllers.

The generator reads existing CSVs and `study.mat`. It checks saved error histories, sustained crossings, dwell feasibility, conditioning arithmetic, cumulative-cost reconstruction, and timing summaries before export. It neither simulates nor solves a control problem. The runner and short report use Daniel and MPC-5; `draft-figures` and `draft` build the same two-method section. Earlier comparisons remain in the study archive.

The draft distinguishes existing preliminary results from the proposed expanded validation and timing protocol. The expanded initial-condition set and physically admissible voltage/current envelope remain unresolved. Current evidence covers 100-cycle runs for the six Daniel/MPC-5 and initial-error-scale combinations. Medians and p95 values come from ordered host runs, including first-call overhead; this remains preliminary timing evidence.

## Shared setup

- Article converter and reconciled orbit, fixed 286 us period, and minimum applied dwell of 3 us.
- Same normalized LQR weights, Q = I and R = 0.001 I. The native MPC builder fixes R = I, so Q = 1000 I gives the same relative weights and terminal gain.
- `daniel` uses scalar dwell conditioning. `mpc-5` solves the native constrained QP every cycle with a five-cycle horizon and its invariant terminal set.
- Initial displacements are 1x, 2x, and 3x the article's initial displacement. Runs last 100 cycles unless a QP fails. Failed solves stop the trajectory without applying fallback LQR.

The model follows thesis Chapters 3 and 4. Physical dynamics and MPC remain in `simulations/matlab-sim/`. Article helpers provide the benchmark, verified switching-time Jacobians, gain, and exact switched-affine propagation. Historical thesis schedules and printed matrices are not mixed with the article orbit.

`test_comparison.m` checks condensed-cost equivalence, normalization, the negative final dwell-change row, inactive-constraint LQR recovery, and initial QP feasibility.

## Evidence

All outputs stay under this study's `results/`:

- `comparison-report.pdf`: short report, built from `report.tex`.
- `metrics.csv`: settling, sampled cost, dwell limits, failures, and timing summaries.
- `computation-time.tex`: generated timing table from `export_timing.m`.
- `error-scale-1x/`, `error-scale-2x/`, `error-scale-3x/`: response/state figures, cycle and dwell CSVs, dense trajectory samples, and `study.mat` with model, controller, QP data, MATLAB version, and host architecture.

Error is the article's normalized cycle-start error. Settling means error below 0.01 for every remaining simulated boundary. Sampled stage cost sums normalized squared state error plus weighted timing effort over 100 cycles. Incomplete runs have no full-run cost or final error. Dense trajectories retain thirty exact samples per mode interval, without resampling.

## Computation times

The report gives median and 95th-percentile times in microseconds. Daniel times the LQR command plus dwell conditioning; MPC times the QP solve. Summaries use successful applied calls. All current trials complete 100 cycles.

Measurements include first-call overhead and exclude offline design, state normalization, plant propagation, and plotting. They are recorded desktop MATLAB timings, not embedded or worst-case execution bounds. `task mpc-comparison:build` checks the summaries against saved cycle timings without rerunning simulations.

## Matched full-controller timing

`task mpc-comparison:matched-timing` runs `benchmark_matched_timing.m` without propagation or offline controller design. It measures complete physical-state-to-validated-schedule calls for both methods on the same 24 saved early-transient states, with 1008 warmups and 5760 interleaved samples per method. Error calculation, required normalization, gain/conditioning or native QP/offset conversion, and common feasibility checks are included. Input selection, output checksum, file I/O, and plant propagation are excluded. Timer overhead remains included; first-call observations are separate. Each MPC call retains the native all-zero initial plan.

`results/matched-timing/` contains raw samples, per-state labels/summaries, aggregate and cold observations, timer-only measurements, source snapshot, and environment/source hashes. The article's checked exporter recomputes medians/p95 from raw samples and rejects changes to the measured project sources or source study. These measurements, not the preliminary trajectory-loop times in `metrics.csv`, supply the main-article timing block. They establish neither worst-case execution time nor embedded deadline feasibility.

## Limits

MPC-5 reaches the sampled threshold earlier than Daniel, but produces negative capacitor voltage at 3x. The 2x/3x trials also start with negative current. Neither method enforces physical state limits. These simulations establish neither validated hardware operation nor global nonlinear stability. The article's common-P certificate does not cover MPC.

The Marcolino study remains unchanged. The article imports checked 1x performance and matched timing evidence into separate publication records without altering the existing model, gains, Lyapunov certificate, or original response data.
