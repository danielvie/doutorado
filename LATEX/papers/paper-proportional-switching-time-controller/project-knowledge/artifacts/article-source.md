# Article source map

Status: descriptive source map
Source of truth: `latex/main.tex`
Read when: navigating or rewriting the manuscript

## Entry point

`latex/main.tex` is the main Springer Nature manuscript source. It contains the complete main text, five figures, two tables, and a supporting invariant-region appendix. Section labels are more stable navigation targets than line numbers.

| Label | Content |
| --- | --- |
| Introduction, no label | Author-owned text preserved during the common-P rewrite; its old summary and roadmap await revision |
| `sec:model` | Problem, exact cycle propagation, linearization, and raw feedback |
| `sec:conditioning` | Closed-form dwell conditioner and feasibility proof |
| `sec:stability` | Common-P theorem, endpoint SDP, post-solve checks, and nonlinear boundary |
| `sec:case-study` | Converter model, certificate, 3D and state-time comparisons, conditioning/dwell histories, and eventual open-loop convergence |
| `app:invariant-region` | Supporting raw-action invariant-set calculation |

## External inputs

- `latex/metrics.tex`, generated benchmark and simulation values.
- `latex/lyapunov_metrics.tex`, generated certificate matrix, margins, and rate bound.
- Six PDFs and `latex/figures/common_p_geometry.tex`, forming five main-text figures, listed in `figures-and-tables.md`. Three timing panels form one explanatory figure; the common-P schematic is rendered directly by TikZ during the LaTeX build.
- Bibliography records from `latex/references.bib`.

The article builds from saved publication inputs without running numerical solvers. `task results` refreshes them through Julia and MATLAB; `task replot` redraws the numerical figures from saved MAT data only. Do not edit generated numbers by hand.

## Rewrite navigation

Trace existing metrics to `scripts/+paper/collect_metrics.m` and `write_outputs.m`. Trace Lyapunov values to `scripts/+paper/export_lyapunov.m` and `studies/lyapunov/analysis.jl`. Trace continuous-time and long-horizon plots to `scripts/+paper/export_trajectories.m`, `plot_trajectories.m`, and `sample_cycle.m`. Trace the timing-mechanism schematics to `scripts/+paper/export_timing_diagrams.m` and `timing_diagram_data.m`.
