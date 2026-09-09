# Current article evidence

Only the current article's outputs belong here. Run `task results` from the paper root to regenerate them. The [pipeline guide](../scripts/README.md) identifies each stage.

| Output | Producer and purpose |
| --- | --- |
| `metrics.csv` | `paper.collect_metrics` and `paper.write_outputs`, one-row scientific summary |
| `reference_schedule_orbit.csv` | `paper.write_outputs`, published/reconciled schedule and exact orbit states |
| `jacobian_checks.csv` | `paper.validate_model` and `paper.write_outputs`, analytical versus finite-difference entries |
| `linearization_residual.csv` | Same stages, perturbation sweep and quadratic residual fit |
| `conditioned_control_response.csv` | `paper.simulate_responses` and `paper.write_outputs`, 100-cycle states, actions, dwells, and factors |
| `invariant_raw_action_region_vertices.csv` | `generate_feasible_regions`, certified polyhedron vertices |
| `fixed_beta_0_25_feasible_region_vertices.csv` | Same producer, fixed-factor comparison |
| `fixed_beta_0_5_feasible_region_vertices.csv` | Same producer, fixed-factor comparison |
| `paper_results.mat` | `paper.write_outputs`, established structured numerical record, with its schema preserved |
| `lyapunov_certificate.json` | `paper.export_lyapunov`, full-precision Julia P checked against the article endpoints, eigenvalues, margin, rate bound, and solver metadata |
| `continuous_trajectories.csv` | `paper.export_trajectories`, dense controlled/open-loop physical states and their separate sample times |
| `open_loop_convergence.csv` | Same producer, selected long-horizon cycle starts, times, errors, and physical states |
| `publication_trajectories.mat` | Same producer, dense paths, reference/final cycles, and all 100001 long-horizon open-loop cycle starts and errors |
| `figures/first_cycle_conditioning.pdf` | `paper.export_figures`, auxiliary boundary/dwell view |
| `figures/conditioned_control_response.pdf` | `paper.plot_conditioned_response`, source copy of the main-text error/beta/dwell figure |
| `provenance.json` | `paper.write_provenance`, ignored per-run revision, working-tree status, MATLAB and toolbox information |

The MAT schema remains `metrics`, `schedule`, `linearization`, `controller`, `invariant_raw_action_region`, and `response`. The current aggressive gain is `results.controller.K_aggressive_physical` within that MAT record.

The same pipeline writes `../latex/metrics.tex`, `../latex/lyapunov_metrics.tex`, and four main-text figures under `../latex/figures/`. The timing figure combines `timing_coordinates.pdf`, `dwell_coupling.pdf`, and `inadmissible_request.pdf`; the other numerical figures are `trajectory_comparison.pdf`, `conditioned_control_response.pdf`, and `state_time_comparison.pdf`. The fifth main-text figure, `../latex/figures/common_p_geometry.tex`, is a schematic rendered directly by TikZ during the LaTeX build, not a numerical pipeline output. `reference_schedule_orbit.pdf` remains generated as a supporting view but is not included in the manuscript. `paper.export_timing_diagrams` also writes PNG previews of its three panels to `figures/`, using current numerical data rather than copied tutorial labels. The auxiliary `invariant_raw_action_region.pdf` remains generated but is not included in the manuscript. Appendix A uses `../latex/figures/appendix_raw_action_region.pdf`, rendered by `paper.plot_invariant_region` from the saved polyhedron and cycle-start errors. Its four panels compare the nested feasible regions for fixed beta 0.25, 0.5, and 1 in one 3D view and three coordinate-plane projections, with the state-dependent simulation overlaid. They do not show the raw region's one-cycle image. The compared volume ratios are 64, 8, and 1. Feasibility in a projection does not establish full-dimensional membership. These publication inputs remain tracked so LaTeX builds without MATLAB or Julia. Never edit their numerical values manually.

`task replot` refreshes all main-text numerical graphics and the Appendix A figure from saved MAT data without rewriting numerical evidence. The state-time comparison uses 12 complete cycles with the original controlled/open-loop timestamps and the repeated reference waveform. The old `../latex/figures/open_loop_convergence.pdf` remains as supporting material but is no longer regenerated.

Older gains, robustness outputs, and local-response files are preserved under [../archive/legacy-experiments/](../archive/legacy-experiments/README.md). The Lyapunov study retains its reconstruction and solver evidence in [../studies/lyapunov/results/](../studies/lyapunov/results/). The article now adopts its common-P result through the checked publication export in this directory.
