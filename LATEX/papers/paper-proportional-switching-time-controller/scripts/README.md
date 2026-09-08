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
| 6 | [`paper.collect_metrics`](+paper/collect_metrics.m), [`paper.write_outputs`](+paper/write_outputs.m), [`paper.export_figures`](+paper/export_figures.m), [`paper.export_lyapunov`](+paper/export_lyapunov.m), [`paper.export_trajectories`](+paper/export_trajectories.m) | Existing metrics and record, checked Julia certificate, dense trajectories, long-horizon evidence, and publication figures |

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

## Separate studies

The latest Julia analysis remains [`../studies/lyapunov/analysis.jl`](../studies/lyapunov/analysis.jl). The root results task runs it before MATLAB; the MATLAB exporter validates and adopts its saved result. Python and MATLAB study reconstructions remain independent model cross-checks.

The earlier standalone comparison remains under [`../studies/trajectory-comparison/`](../studies/trajectory-comparison/README.md). The publication version uses the article's benchmark and response arrays directly. It overlays both dense 100-cycle paths in one 3D graph. The long-run figure pairs logarithmic-time physical-state histories with a 3D view that uses actual cycle-start samples after the dense early transient. Those samples are not continuous-time paths or cycle averages.

[`paper.plot_trajectories`](+paper/plot_trajectories.m) owns presentation separately from sampling/export. To revise only the two trajectory PDFs without rerunning the simulations, use the saved record with the matching benchmark:

```matlab
addpath('scripts');
paths = paper.paths();
addpath(paths.simulation);
benchmark = paper.benchmark();
saved = load(fullfile(paths.results, 'publication_trajectories.mat'));
paper.plot_trajectories(paths.article_figures, saved.trajectories, benchmark);
```

This plotting call does not rewrite numerical evidence. `task results` still regenerates the data and calls the same plotter.

`Taskfile.yml` in this directory retains the old Lyapunov task names as compatibility aliases. Prefer `task lyapunov` and `task lyapunov:python` from the paper root.
