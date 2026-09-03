# Numerical pipeline

Status: descriptive summary
Source of truth: `Taskfile.yml`, `scripts/`, `results/metrics.csv`, and the sibling MATLAB project
Read when: regenerating or tracing numerical evidence

## Build tasks

Run from the paper project root:

- `task figures` runs `matlab -batch "run('scripts/generate_results.m')"`.
- `task trajectory-comparison` runs `scripts/generate_trajectory_comparison.m`.
- `task invariant-region` calls `generate_feasible_regions.m` without input. It requires an existing `results/paper_results.mat` and regenerates only the feasible-region figure and vertex CSV files.
- `task build` runs `latexmk` into `build/` and copies `build/article.pdf` to root-level `article.pdf`.
- `task run` depends on `build`.
- `task verify` regenerates results and then builds the article.
- `task clean` removes the LaTeX build directory.

## Numerical inputs

`scripts/generate_results.m`:

1. Adds the sibling `simulations/matlab-sim/` directory to the MATLAB path.
2. Instantiates `Simulation(Enums.SimName.PATINO_2)`.
3. Replaces the model schedule with the paper's nine-interval dynamics-index sequence and corrected boundaries.
4. Uses the reported cycle anchor as both the orbit anchor and the initial reference state.
5. Computes exact cycle propagation and the analytical one-cycle linearization.
6. Verifies the state and timing Jacobians by central finite differences.
7. Sweeps a combined normalized perturbation direction to measure residual scaling.
8. Designs aggressive and conservative normalized discrete LQR gains.
9. Runs exact cycle simulations.
10. Passes the linear model, controller, schedule limits, and nonlinear trajectory to `generate_feasible_regions.m`.
11. Writes the remaining metrics, tables, figures, and MAT data.

`generate_feasible_regions.m` uses MPT3 to construct the fixed-`β` feasible regions and their maximal invariant subsets. It verifies the raw-action region's vertices and closed-loop images against the dwell constraints, checks the expected `β^{-3}` volume scaling, writes the region vertices, and generates the four-panel region figure.

## Controller path

For each conditioned cycle:

1. Compute the raw timing offset from the cycle-start error.
2. Convert the offset to dwell changes.
3. Scan the dwell changes and compute the largest feasible conditioning factor.
4. Scale the complete raw offset vector.
5. Propagate every interval with an augmented matrix exponential.
6. Store cycle-start states, boundary states, offsets, dwells, and the factor.

The simulation uses exact interval propagation. It does not propagate the linearized model for the large-error response.

## LaTeX data path

`generate_results.m` writes `results/metrics.tex`. `latex/article.tex` includes that file near the preamble and uses its generated commands for numerical values in the abstract, tables, captions, and text.

The underlying CSV and MAT files remain the detailed numerical record. A manually edited value in `metrics.tex` would be overwritten by the next figures or verification task.

## Dependencies

The normal numerical verification path requires:

- MATLAB;
- the sibling MATLAB simulation project;
- Control System Toolbox functionality such as `dlqr`;
- MPT3.

The LaTeX build requires a TeX installation with `latexmk` and the local Springer class/style files.
