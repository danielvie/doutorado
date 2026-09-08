# Numerical pipeline

Status: descriptive summary
Source of truth: `Taskfile.yml`, `scripts/README.md`, and `scripts/+paper/`
Read when: regenerating or tracing numerical evidence

## Article tasks

Run from the paper root:

- `task results` runs the Julia certificate, then `scripts/generate_results.m`; `task figures` is a compatibility alias.
- `task test` checks the conditioner, model, and gains without exporting.
- `task test-regeneration` regenerates in a temporary directory and compares with current stored evidence.
- `task invariant-region` reconstructs region inputs from `results/paper_results.mat` and refreshes the figure and vertex CSVs.
- `task build` compiles `latex/main.tex` into `build/main.pdf` and copies it to `article.pdf`.
- `task verify` runs tests, local-link checks, numerical generation, and the LaTeX build.
- `task clean` removes LaTeX compilation intermediates.

## Stage flow

`scripts/generate_results.m` delegates to `paper.run_pipeline`. It no longer owns local numerical, plotting, or serialization helpers.

1. `paper.benchmark` loads the sibling converter model and sets the reconciled schedule, normalization, gains' weights, initial state, and cycle counts.
2. `paper.validate_model` obtains `Dynamics.linearize_cycle`, checks exact closure and central differences, and computes residual scaling and cycle averages.
3. `paper.design_feedback` designs the aggressive and conservative LQR gains and checks Schur stability.
4. `paper.simulate_responses` runs the exact nonlinear 100-cycle comparison and separate 100000-cycle convergence check. It returns response arrays, summary values, and the long-horizon open-loop states/errors.
5. `generate_feasible_regions` computes and verifies the raw-action certificate and fixed-beta regions, then exports its vertices and figure.
6. `paper.collect_metrics`, `paper.write_outputs`, and `paper.export_figures` produce the established metrics and figures. `paper.export_lyapunov` verifies the Julia certificate against the article model/gain and exports it. `paper.export_trajectories` samples exact continuous-time paths and exports long-horizon evidence. `paper.write_provenance` records per-run environment information separately.

Each stage consumes explicit structs. `scripts/README.md` documents the contracts and shows how to run stages without exporting. `paper.paths` owns source and output paths, including optional isolated output roots.

## Runtime controller

Each conditioned cycle computes raw timing offsets, calls `condition_dwell_times`, propagates every interval with an augmented matrix exponential, and records the applied action. The large-error study does not use the linearized model for plant propagation.

The online conditioner remains a separate 30-line implementation. The offline MPT3 region calculation adds no online computation.

## Dependencies and exports

Article generation requires Julia, MATLAB, the sibling simulation project, Control System Toolbox, and MPT3. The established CSV/MAT schema and LaTeX macro names are preserved; certificate and trajectory records are additive. `results/README.md` maps all outputs.

`task lyapunov` runs `studies/lyapunov/analysis.jl` independently. `task lyapunov:reproduce` rebuilds Python evidence before Julia. Root `task results` adopts the saved certificate only after checking agreement with the active MATLAB model. The standalone `trajectory-comparison` task still writes only its study outputs; the manuscript uses the new article-owned dense sampler.
