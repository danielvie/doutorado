# Repository map

Status: descriptive summary
Source of truth: `README.md`, `Taskfile.yml`, and the files named below
Read when: deciding where to inspect a project question

## Paper workspace

Start at the paper-root `README.md`. The latest Julia analysis is `studies/lyapunov/analysis.jl`; run it with `task lyapunov`.

- `latex/` contains the manuscript, bibliography, publisher files, generated metrics, and only the article figures.
- `scripts/generate_results.m` is a thin entry point to the six-stage `scripts/+paper/run_pipeline.m`. Read `scripts/README.md` for numerical ownership.
- `results/` contains only current paper data and diagnostic figures. `results/README.md` maps every producer.
- `studies/` groups active investigations and earlier teaching examples. `studies/README.md` identifies the latest analysis and distinguishes older work.
- `docs/study-guide.md` explains the article; `docs/tutorials/` contains conceptual HTML documents. `docs/lyapunov/` is an earlier document-building workspace, not the latest analysis.
- `research/articles/` stores the external PDFs; `research/reviews/` stores literature and novelty analysis.
- `reviews/article-review.html` is a visual manuscript review, not manuscript source.
- `archive/handoffs/`, `archive/drafts/`, and `archive/legacy-experiments/` preserve historical work. `archive/README.md` records the main former locations.
- `templates/` preserves the original publisher distribution.
- `build/` contains ignored compilation output. The Taskfile copies `build/main.pdf` to root-level `article.pdf`.

`GOAL.md` owns scientific scope. `CONTEXT.md` owns terminology. Project-knowledge files summarize those sources rather than replacing them.

## Wider repository

The paper is under `LATEX/papers/paper-proportional-switching-time-controller/` in `doutorado.git`.

The paper scripts depend directly on `simulations/matlab-sim/`, instantiate `PATINO_2`, and use its physical dynamics and `Dynamics.linearize_cycle`. The path is resolved in `scripts/+paper/paths.m`.

`LATEX/thesis/` and `research-material/working-notes/linearization/linearization_v2_augmented.tex` provide context and derivations but are not direct article LaTeX inputs. `embedded/esp32_idf/` provides implementation context; the paper does not use it for hardware validation.

## Study boundary

`studies/lyapunov/` owns its Julia environment, Python and MATLAB comparisons, certificate JSON files, and tutorial. The common-P study is not part of `task results` or `task verify`, and its conclusions have not been incorporated into the article. Earlier standalone gain files are archived and are not valid inputs to the latest study.
