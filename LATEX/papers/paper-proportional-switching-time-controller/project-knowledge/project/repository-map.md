# Repository map

Status: descriptive summary
Source of truth: `AGENTS.md`, the repository tree, and the files named below
Read when: deciding where to inspect a project question

## Repository scope

The paper is part of a larger repository rooted at `doutorado.git`. The project rules identify these related areas:

```text
LATEX/papers/paper-proportional-switching-time-controller/
    latex/
        article.tex
        linearization-reference.tex
    references.bib
    Taskfile.yml
    scripts/
    results/
    figures/
    comparison/
    research/
    handoff/
    docs/
    templates/

simulations/matlab-sim/
LATEX/thesis/
research-material/working-notes/linearization/
embedded/esp32_idf/
```

## Paper directory

### Manuscript and formatting

- `latex/article.tex` is the complete manuscript and the LaTeX entry point.
- `references.bib` contains the bibliography records.
- `sn-jnl.cls` and `sn-mathphys-ay.bst` are local Springer formatting files.
- `article.pdf` is the root-level PDF copied by the build task.
- Root-level `.aux`, `.bbl`, `.blg`, `.log`, `.fls`, `.fdb_latexmk`, `.out`, and `.synctex.gz` files are build products.

### Source scripts

- `scripts/generate_results.m` generates the main numerical outputs, the reference manuscript figure, and two auxiliary simulation figures. It calls the dedicated feasible-region generator during a full run.
- `scripts/generate_feasible_regions.m` computes the fixed-`β` regions, writes their vertex files, and generates the four-panel feasible-region figure. It can also run independently from `results/paper_results.mat`.
- `scripts/condition_dwell_times.m` implements the scalar dwell conditioner.
- `scripts/generate_trajectory_comparison.m` generates additional comparison PDFs.
- `scripts/design_robust_controllers.m` contains older robust-control work and is not part of the current article pipeline.

### Generated evidence

- `results/metrics.csv` contains the numerical metrics.
- `results/metrics.tex` converts selected metrics into LaTeX commands consumed by `latex/article.tex`.
- Several CSV and MAT files contain schedules, Jacobian checks, residual sweeps, controller data, and simulation responses.
- Some result files are legacy outputs from earlier robust-control, invariant-region, or comparison studies.

### Visual outputs

- `figures/` contains the figures used by the current article and older unused figures.
- `comparison/` contains separate trajectory-comparison outputs that are not included by `latex/article.tex`.

### Knowledge and process notes

- `CONTEXT.md` defines the project's terminology.
- `GOAL.md` defines the scientific goal, success criteria, non-goals, constraints, and accepted limitations.
- `study-guide.md` explains the article section by section.
- `research/` contains literature and novelty notes.
- `handoff/` contains historical session handoffs. It may describe earlier states and should not override current source files.
- `article-review.html` is a visual review companion, not manuscript source.

## External relationships

The paper-specific MATLAB scripts add `simulations/matlab-sim/` to the MATLAB path and instantiate the `PATINO_2` simulation model. The thesis and linearization notes provide provenance and broader derivations but are not direct LaTeX inputs to the article. The embedded ESP project provides implementation context; the current paper does not use it for hardware validation.

## Navigation rule

Start from the artifact that owns the fact:

- wording or equations: `latex/article.tex`;
- terminology or scope: `CONTEXT.md` and `GOAL.md`;
- generated number: `scripts/generate_results.m`, `scripts/generate_feasible_regions.m`, and `results/metrics.csv`;
- build behavior: `Taskfile.yml`;
- prior-art interpretation: `research/novelty-review.md`.
