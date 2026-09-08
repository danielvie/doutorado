# Article numerical pipeline

[`generate_results.m`](generate_results.m) is the entry script. It adds the script directory to the MATLAB path and calls [`paper.run_pipeline`](+paper/run_pipeline.m). All computation receives explicit inputs and returns named structs; stages do not share a script workspace.

From the paper root:

```sh
task results
```

## Follow the computation

| Stage | Function | Output and responsibility |
| --- | --- | --- |
| 1 | [`paper.benchmark`](+paper/benchmark.m) | `benchmark`: converter configuration, reconciled schedule, dwell bounds, scales, LQR weights, initial state, and cycle counts |
| 2 | [`paper.validate_model`](+paper/validate_model.m) | `model`: analytical linearization, exact closure and cycle averages, central-difference Jacobians, and residual sweep |
| 3 | [`paper.design_feedback`](+paper/design_feedback.m) | `controller`: aggressive and conservative LQR gains in normalized and physical units; checks Schur stability |
| 4 | [`paper.simulate_responses`](+paper/simulate_responses.m) | `response`, `summary`, and `long_response`: exact nonlinear 100-cycle comparison, dwell checks, and 100000-cycle open-loop convergence evidence |
| 5 | [`generate_feasible_regions`](generate_feasible_regions.m) | `region`: invariant raw-action certificate and fixed-factor comparisons; also exports region vertices and figure |
| 6 | [`paper.collect_metrics`](+paper/collect_metrics.m), [`paper.write_outputs`](+paper/write_outputs.m), [`paper.export_figures`](+paper/export_figures.m), [`paper.export_timing_diagrams`](+paper/export_timing_diagrams.m), [`paper.export_lyapunov`](+paper/export_lyapunov.m), [`paper.export_trajectories`](+paper/export_trajectories.m) | Existing metrics and record, checked Julia certificate, dense trajectories, long-horizon evidence, and publication figures |

[`paper.print_summary`](+paper/print_summary.m) reports the results. [`paper.write_provenance`](+paper/write_provenance.m) records the environment separately from the scientific metrics.

The main runner prints each stage as it starts. The expensive long-horizon simulation is explicit in stage 4; it is not needed for the fast unit tests. `task results` first reruns the Julia SDP. A direct `paper.run_pipeline` call uses the saved study certificate but still checks it against the current MATLAB model and gain before exporting it.

## Shared numerical functions

- [`condition_dwell_times.m`](condition_dwell_times.m) implements the online scalar conditioner. Its numerical implementation is unchanged.
- [`paper.exact_cycle`](+paper/exact_cycle.m), [`paper.cycle_boundaries`](+paper/cycle_boundaries.m), and [`paper.sample_cycle`](+paper/sample_cycle.m) propagate the exact switched-affine dynamics. The dense sampler includes 30 samples per interval and checks against the existing boundary propagation.
- [`paper.verify_common_lyapunov`](+paper/verify_common_lyapunov.m) checks symmetry, positive definiteness, trace normalization, and both endpoint decrease matrices without an SDP solver.
- [`paper.paths`](+paper/paths.m) owns file locations. It resolves the source project from its own file, not the current directory.
- `Dynamics.linearize_cycle` and the physical converter model remain in the sibling MATLAB simulation project. They have not been copied into this paper.

## Run a stage without exporting

```matlab
addpath('scripts');
paths = paper.paths();
addpath(paths.simulation);
benchmark = paper.benchmark();
model = paper.validate_model(benchmark);
controller = paper.design_feedback(benchmark, model);
```

Change experiment settings in `benchmark.m`, not in plot or serialization code. Python and MATLAB reconstructions in the Lyapunov study are intentionally independent cross-checks, so benchmark changes must be reconciled there explicitly.

## Output contract and regression checks

The refactor preserves the existing `paper_results.mat` fields, CSV headers and values, and `latex/metrics.tex` macros. See the [output inventory](../results/README.md).

```matlab
addpath('scripts');
results = paper.run_pipeline(fullfile(tempdir, 'paper-check'));
```

An alternate output root receives its own `results/` and `latex/` folders. Source inputs still come from this repository. This permits full validation without overwriting publication evidence.

`task test-regeneration` uses this path to compare ten CSV files, the publication certificate, both LaTeX macro files, both MAT records, and invariant regions against the stored outputs. It checks that figures were generated but does not compare PDF bytes, which contain creation metadata. For deliberate scientific changes, review and refresh the stored baseline rather than weakening the comparison.

## Explanatory timing panels

[`paper.export_timing_diagrams`](+paper/export_timing_diagrams.m) renders three vector PDFs, grouped as one main-text figure: `timing_coordinates.pdf`, `dwell_coupling.pdf`, and `inadmissible_request.pdf`. PNG previews go to `results/figures/`.

[`paper.timing_diagram_data`](+paper/timing_diagram_data.m) derives the labels from the active benchmark and recorded first-cycle raw action. The middle panel deliberately applies only an illustrative `+12 µs` offset to instant 8; it is not the LQR action. It checks dwell feasibility and unchanged endpoints. The failure panel checks its raw dwell durations against the simulation record. The tutorial HTML is only a visual reference, not a source of rounded numerical labels.

## Separate studies

The latest Julia analysis remains [`../studies/lyapunov/analysis.jl`](../studies/lyapunov/analysis.jl). The root results task runs it before MATLAB; the MATLAB exporter validates and adopts its saved result. Python and MATLAB study reconstructions remain independent model cross-checks.

The earlier standalone comparison remains under [`../studies/trajectory-comparison/`](../studies/trajectory-comparison/README.md). The publication version uses the article's benchmark and response arrays directly. The comparison figure pairs both dense 100-cycle paths in one 3D graph with a logarithmic normalized cycle-start error plot. The error plot shades the first 100 cycles, shows the saved 100000-cycle open-loop response, and marks the actual samples used for the selected 0.01 comparison threshold. Feedback cycle-start errors are recovered from the dense 100-cycle record; they are not extrapolated, and values below the displayed range are not clamped. The state-time figure shows the first 12 complete cycles of all three physical states, comparing closed loop, open loop, and the repeated nominal waveform. `paper.state_history_data` selects saved samples without interpolating onto a common grid: controlled and open-loop switching instants differ. The older `open_loop_convergence.pdf` is retained as supporting material, but is no longer regenerated or included in the manuscript.

[`paper.plot_trajectories`](+paper/plot_trajectories.m) owns presentation separately from sampling/export. It writes `trajectory_comparison.pdf` and `state_time_comparison.pdf`. To revise only these two PDFs without rerunning the simulations, use the saved record with the matching benchmark:

```matlab
addpath('scripts');
paths = paper.paths();
addpath(paths.simulation);
benchmark = paper.benchmark();
saved = load(fullfile(paths.results, 'publication_trajectories.mat'));
paper.plot_trajectories(paths.article_figures, saved.trajectories, benchmark);
```

This plotting call does not rewrite numerical evidence. `task results` still regenerates the data and calls the same plotter.

## Replot and printed typography

Run `task replot` to redraw all main-text numerical figures from `paper_results.mat` and `publication_trajectories.mat`, without simulation, solver calls, or numerical output writes. `paper.replot_figures(output_root)` also supports an isolated output directory. It checks the saved schedule and state scales against the benchmark.

`paper.plot_conditioned_response` draws aligned error, applied-fraction, and minimum-dwell panels from the saved response. The first two panels shade the actual cycles with beta below one; the third shades forbidden dwell values. Conservative tuning stays in the table and text rather than this figure.

`paper.publication_figure` and `paper.export_publication_figure` set the final 160 mm manuscript width and export exact-size vector PDF pages. Labels are about 10 pt, legends and ticks 9 pt; timing labels use an 8–10 pt hierarchy. Include these PDFs at `\textwidth`, not a reduced width, to preserve those sizes. The common-P schematic is TikZ and is rebuilt by `task build`.

`Taskfile.yml` in this directory retains the old Lyapunov task names as compatibility aliases. Prefer `task lyapunov` and `task lyapunov:python` from the paper root.
