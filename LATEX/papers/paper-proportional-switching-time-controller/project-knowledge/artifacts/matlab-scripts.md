# MATLAB script map

Status: descriptive script map
Source of truth: `scripts/README.md` and the named source files
Read when: deciding which function owns a numerical operation

## Article generation

`scripts/generate_results.m` only calls `paper.run_pipeline`. The package directory `scripts/+paper/` contains:

- `benchmark.m`: benchmark data and experiment settings.
- `validate_model.m`: cycle closure, analytical and finite-difference Jacobians, residual scaling.
- `design_feedback.m`: normalized LQR and physical gain conversion.
- `simulate_responses.m`: exact nonlinear comparisons and long-horizon convergence check.
- `collect_metrics.m`: publication metric names and units.
- `write_outputs.m`: stable CSV, MAT, and LaTeX macro schemas.
- `export_figures.m`: reference and response figures, plus the first-cycle diagnostic.
- `export_lyapunov.m`: checks the Julia certificate against the article model/gain and writes publication certificate data and macros.
- `verify_common_lyapunov.m`: solver-independent endpoint eigenvalue and normalization checks.
- `export_trajectories.m`: dense trajectory and long-horizon CSV/MAT evidence, then calls the plotter.
- `plot_trajectories.m`: shared-axis 3D comparison, logarithmic-time cycle-start state histories, and the long-run 3D cycle-start view. Can replot saved data without resimulating.
- `exact_cycle.m`, `cycle_boundaries.m`, and `sample_cycle.m`: shared exact propagation at cycle ends, switching boundaries, and dense within-interval times.
- `paths.m`, `write_provenance.m`, and `print_summary.m`: paths and run reporting.

See `scripts/README.md` for inputs and return values. Functions do not communicate through a shared script workspace.

## Standalone functions

`scripts/generate_feasible_regions.m` computes fixed-factor feasible regions and their invariant subsets, checks the certificate and volume scaling, and exports three vertex CSVs and the region figure. Without input, it reconstructs its inputs from `results/paper_results.mat`.

`scripts/condition_dwell_times.m` implements the online scalar conditioner. It preserves its existing interface and numerical implementation.

## Studies and historical work

- `studies/lyapunov/analysis.jl` is the latest Lyapunov entry point. Its independent MATLAB comparison is `studies/lyapunov/matlab/compare_certificate.m`.
- `studies/trajectory-comparison/generate_comparison.m` generates separate continuous-time and long-horizon plots in that study's `results/` folder.
- `archive/legacy-experiments/design_robust_controllers.m` preserves earlier robust-control synthesis. The current article does not call it.

Change generated article numbers at their owning numerical stage and regenerate. Do not edit output values directly.
