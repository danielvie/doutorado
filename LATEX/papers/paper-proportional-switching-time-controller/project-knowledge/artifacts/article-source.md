# Article source map

Status: descriptive source map
Source of truth: `latex/main.tex`
Read when: navigating or rewriting the manuscript

## Entry point

`latex/main.tex` is the main Springer Nature manuscript source. It contains the complete main text, five main-text figures, two tables, and a supporting invariant-region appendix with a four-panel figure. Section labels are more stable navigation targets than line numbers.

| Label | Content |
| --- | --- |
| Introduction, no label | Author-owned text preserved during the common-P rewrite; its old summary and roadmap await revision |
| `sec:model` | Problem, exact cycle propagation, linearization, and raw feedback |
| `sec:conditioning` | Closed-form dwell conditioner and feasibility proof |
| `sec:stability` | Common-P theorem, endpoint SDP, post-solve checks, and brief linearized-model scope limitation |
| `sec:case-study` | Converter model, certificate, 3D and state-time comparisons, conditioning/dwell histories, and the exact error-map argument for eventual open-loop convergence |
| `app:invariant-region` | Fixed-factor feasible-region expansion and supporting linear invariance |

## External inputs

- `latex/metrics.tex`, generated benchmark and simulation values. The macro `PhiJacobianRelativeError` reports the physical Jacobian error, now labeled `Phi_x` in the manuscript. Numerical fields `Phi` and `Gamma` retain their names and correspond to the manuscript's `Phi_x` and `Gamma_tau`; they are not the manuscript's augmented `Phi` and `Gamma`.
- `latex/lyapunov_metrics.tex`, generated normalized-coordinate certificate matrix and margins, displayed as `P_n` and normalized margins in the application. Its rate-bound macro remains generated but is not displayed in the manuscript. Saved JSON field names `A0`, `A1`, and `P` still denote normalized quantities; the theorem now uses physical-coordinate endpoints and `P`.
- Six PDFs and `latex/figures/common_p_geometry.tex`, forming five main-text figures, listed in `figures-and-tables.md`. Three timing panels form one explanatory figure; the common-P schematic is rendered directly by TikZ during the LaTeX build.
- `latex/figures/appendix_raw_action_region.pdf`, comparing fixed-factor feasible regions for beta 0.25, 0.5, and 1 with the state-dependent simulation in Appendix A.
- Bibliography records from `latex/references.bib`.

The article builds from saved publication inputs without running numerical solvers. `task results` refreshes them through Julia and MATLAB; `task replot` redraws the numerical figures from saved MAT data only. Do not edit generated numbers by hand.

## Rewrite navigation

Trace existing metrics to `scripts/+paper/collect_metrics.m` and `write_outputs.m`. Trace Lyapunov values to `scripts/+paper/export_lyapunov.m` and `studies/lyapunov/analysis.jl`. Trace continuous-time and long-horizon plots to `scripts/+paper/export_trajectories.m`, `plot_trajectories.m`, and `sample_cycle.m`. Trace the timing-mechanism schematics to `scripts/+paper/export_timing_diagrams.m` and `timing_diagram_data.m`.
