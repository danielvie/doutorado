# Figures and tables

Status: descriptive visual-artifact map
Source of truth: `article.tex` and `scripts/generate_results.m`
Read when: changing presentation or checking which visual evidence is active

## Figures referenced by the article

1. `reference_schedule_orbit.pdf` — corrected reference schedule, exact periodic trajectory, and cycle averages.
2. `first_cycle_conditioning.pdf` — nominal, raw, and applied boundaries plus dwell durations for the first conditioned cycle.
3. `conditioned_control_response.pdf` — first part of the exact transient with errors, conditioning factor, offsets, and dwell values.
4. `conditioned_trajectory.png` — exact trajectory and long-horizon open-loop comparison.

The figure labels and captions are defined in `article.tex`. The generation code is in `scripts/generate_results.m`.

## Tables in the article

- `tab:parameters` contains converter, schedule, normalization, and LQR parameters.
- `tab:results` contains Jacobian checks, residual scaling, spectral radii, certificate values, dwell-conditioning statistics, and settling results.

Both tables are written directly in `article.tex`. Their numerical values use generated macros from `results/metrics.tex` where applicable.

## Other visual files

`figures/` and `comparison/` contain additional outputs from older or separate studies. They may be useful for research history or future comparisons but are not automatically part of the current article.
