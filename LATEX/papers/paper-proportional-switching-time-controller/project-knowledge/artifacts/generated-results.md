# Generated results map

Status: descriptive output map
Source of truth: `scripts/generate_results.m`, `results/metrics.csv`, and the generated files themselves
Read when: tracing numerical values or choosing evidence for a rewrite

## Primary outputs

`generate_results.m` writes:

- `results/metrics.csv`: one-row numerical summary.
- `results/metrics.tex`: selected metrics as LaTeX commands consumed by `article.tex`.
- `results/reference_schedule_orbit.csv`: interval metadata, corrected and published boundaries, dwell durations, mode identifiers, and orbit states.
- `results/jacobian_checks.csv`: analytical and finite-difference entries for `Phi` and `Gamma` with absolute errors.
- `results/linearization_residual.csv`: perturbation sizes, exact-versus-linearized residuals, and fitted residual values.
- `results/conditioned_control_response.csv`: cycle-start errors, conditioning factors, offsets, dwell values, and state trajectories for the selected simulation.
- `results/paper_results.mat`: structured MATLAB record containing metrics, schedule, linearization, controller, certificate, and response data.

## Main reported values

The current generated metrics record:

- 9 intervals and a 286 microsecond period;
- nominal closure error about `1.421e-14`;
- analytical/finite-difference relative errors of about `8.518e-12` for `Phi` and `8.344e-11` for `Gamma_tau`;
- residual slope about `2.000`;
- open-loop, conservative, and aggressive spectral radii of about `0.999850`, `0.941468`, and `0.568151`;
- common-P endpoint norms of about `0.999939` and `0.979743`, with a segment bound of `0.999939`;
- minimum raw and applied dwells of about `-43.045` and `3.000` microseconds;
- minimum conditioning factor about `0.293978`;
- conditioning active on 3 of 100 cycles;
- normalized-error threshold crossings at cycles 6 and 20 for the conditioned aggressive and conservative comparisons;
- open-loop threshold crossing at the long-horizon cycle recorded in `metrics.csv`.

Use `metrics.csv` for full precision. The values in this file are a readable summary and may become stale after regeneration.

## Legacy outputs

The same directory also contains robust-controller gains, invariant-region vertices, older local responses, and other comparison data. Their presence does not mean that the current manuscript uses them. Check `article.tex` and `Taskfile.yml` before treating an output as active evidence.
