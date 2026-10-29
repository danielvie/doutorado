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

## Manuscript language and style

The target is clear, direct scientific prose.

- Use declarative, affirmative sentences: "The matrix removes..." rather than "Define..." or "Consider...".
- State the purpose before presenting the mathematics.
- Connect equations with short transitions, without narrating every algebraic step.
- Introduce symbols visibly before use. Give important definitions their own display rather than burying them in sentences.
- Prefer plain wording over dense jargon or stacked hyphenated terms such as "zero-last-coordinate".
- Preserve enough explanation to follow the reasoning. Concision must not hide definitions or skip necessary connections.
- Include literature comparisons only where they support the immediate point.

Identify the intended message first. Then draft a connected argument, combining closely related ideas and varying sentence length. The preliminary statements are a content checklist, not a template for the paragraph.
