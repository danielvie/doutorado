The `doutorado.git/` root folder is located at:
`$env:USERPROFILE\Documents\doutorado.git`

All paths below are relative to this root folder.

- MATLAB simulation is located at:
  `simulations/matlab-sim/`

- Embedded ESP code is located at:
  `embedded/esp32_idf/`

- LaTeX projects are located at:
  `LATEX/`

- This paper is located at:
  `LATEX/papers/paper-proportional-switching-time-controller/`

- Thesis is located at:
  `LATEX/thesis/`

- The linearization procedure is located at:
  `research-material/working-notes/linearization/linearization_v2_augmented.tex`

For project orientation and navigation, read `project-knowledge/README.md` relative to this paper directory before inspecting project files. The paper-root `README.md` is the command index.

- Latest Lyapunov analysis: `studies/lyapunov/analysis.jl`, run with `task lyapunov` from the paper root. The manuscript adopts its common-P result for the conditioned linearized family. Keep this separate from local nonlinear stability and large-error simulation evidence.
- Article numerical pipeline: `scripts/generate_results.m` delegates to `scripts/+paper/run_pipeline.m`. Read `scripts/README.md` before changing numerical stages.
- Current evidence belongs in `results/`; study evidence belongs with its study. Historical files in `archive/` do not override current source files.
