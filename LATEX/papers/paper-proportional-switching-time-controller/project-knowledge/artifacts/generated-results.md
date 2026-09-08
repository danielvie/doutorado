# Generated results map

Status: descriptive output map
Source of truth: `scripts/generate_results.m`, `scripts/generate_feasible_regions.m`, `results/metrics.csv`, and the generated files themselves
Read when: tracing numerical values or choosing evidence for a rewrite

## Primary outputs

A full `generate_results.m` run writes these files. It calls `generate_feasible_regions.m`, which owns the three region vertex CSV files and can regenerate those files independently from `results/paper_results.mat`:

- `results/metrics.csv`: one-row numerical summary.
- `latex/metrics.tex`: selected metrics as LaTeX commands consumed by `latex/main.tex`.
- `results/reference_schedule_orbit.csv`: interval metadata, corrected and published boundaries, dwell durations, mode identifiers, and orbit states.
- `results/jacobian_checks.csv`: analytical and finite-difference entries for `Phi` and `Gamma` with absolute errors.
- `results/linearization_residual.csv`: perturbation sizes, exact-versus-linearized residuals, and fitted residual values.
- `results/conditioned_control_response.csv`: cycle-start errors, conditioning factors, offsets, dwell values, and state trajectories for the selected simulation.
- `results/invariant_raw_action_region_vertices.csv`: vertices of the certified region in physical cycle-start-error coordinates.
- `results/fixed_beta_0_2_feasible_region_vertices.csv` and `results/fixed_beta_0_5_feasible_region_vertices.csv`: vertices of the two fixed-factor comparison regions in the same coordinates.
- `results/paper_results.mat`: structured MATLAB record containing metrics, schedule, linearization, controller, invariant-region, and response data.
- `results/lyapunov_certificate.json` and `latex/lyapunov_metrics.tex`: adopted Julia common-P matrix, directly checked margins, and rate bound, verified against the article model and aggressive gain.
- `results/continuous_trajectories.csv`: dense controlled/open-loop physical states with separate sample times.
- `results/open_loop_convergence.csv`: selected long-horizon open-loop cycle starts, states, times, and error norms.
- `results/publication_trajectories.mat`: full dense paths, reference/final within-cycle trajectories, and all long-horizon open-loop cycle starts and errors.

## Main reported values

The current generated metrics record:

- 9 intervals and a 286 microsecond period;
- nominal closure error about `1.421e-14`;
- analytical/finite-difference relative errors of about `8.518e-12` for `Phi` and `8.344e-11` for `Gamma_tau`;
- residual slope about `2.000`;
- open-loop, conservative, and aggressive spectral radii of about `0.999850`, `0.941468`, and `0.568151`;
- a 7-facet, 10-vertex Raw-Action Admissible Region that is already positively invariant under the aggressive raw closed loop;
- physical-error volume about `4.5410 V²·A`, with ranges `[-2.358, 2.098] V`, `[-3.234, 1.911] V`, and `[-0.496, 0.222] A`;
- the fixed `β = 0.5` feasible region doubles every radial extent and has volume about `36.3282 V²·A`, eight times the raw-action region;
- the fixed `β = 0.2` feasible region multiplies every radial extent by five and has volume about `567.6277 V²·A`, 125 times the raw-action region;
- the large-error trajectory starts inside the `β = 0.2` region, enters the `β = 0.5` region at cycle 2, and enters the raw-action region at cycle 3;
- minimum raw and applied dwells of about `-43.045` and `3.000` microseconds;
- minimum conditioning factor about `0.293978`;
- conditioning active on 3 of 100 cycles;
- normalized-error threshold crossings at cycles 6 and 20 for the conditioned aggressive and conservative comparisons;
- persistent open-loop threshold crossing at cycle 22009;
- common-P verified minimum decrease about `2.911904317e-4`, minimum eigenvalue of P about `4.987946970e-3`, and worst-case per-cycle rate bound about `0.999938954110`.

Use `metrics.csv` for full precision. The values in this file are a readable summary and may become stale after regeneration.

## Legacy outputs

Earlier robust-controller gains, invariant-region vertices, local responses, and comparison data are preserved under `archive/legacy-experiments/results/`. They are no longer mixed with current paper outputs. The current aggressive gain is in `results.controller.K_aggressive_physical` within `results/paper_results.mat`.

The study retains its source common-P certificates under `studies/lyapunov/results/`. The article now adopts the Julia certificate through `paper.export_lyapunov`, which checks model/gain agreement before writing publication inputs. See `results/README.md` and `studies/lyapunov/README.md` for producers and commands.
