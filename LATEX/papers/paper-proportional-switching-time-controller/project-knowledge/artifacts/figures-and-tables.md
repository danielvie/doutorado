# Figures and tables

Status: descriptive visual-artifact map
Source of truth: `latex/main.tex`, `scripts/generate_results.m`, and `scripts/generate_feasible_regions.m`
Read when: changing presentation or checking which visual evidence is active

## Figures referenced by the article

1. `reference_schedule_orbit.pdf` — corrected reference schedule, exact periodic trajectory, and cycle averages.
2. `invariant_raw_action_region.pdf` — overlays fixed-factor feasible regions at `β = 0.2`, `0.5`, and `1.0` in three dimensions and three orthogonal coordinate-plane projections, together with the first ten conditioned cycle-start errors. The `β = 1` region is the invariant Raw-Action Admissible Region.

The figure labels and captions are defined in `latex/main.tex`. `scripts/generate_feasible_regions.m` generates the region figure; `scripts/generate_results.m` generates the reference and auxiliary simulation figures.

## Tables in the article

- `tab:parameters` contains converter, schedule, normalization, and LQR parameters.
- `tab:results` contains Jacobian checks, residual scaling, spectral radii, invariant-region metrics, dwell-conditioning statistics, and settling results.

Both tables are written directly in `latex/main.tex`. Their numerical values use generated macros from `latex/metrics.tex` where applicable.

## Other visual files

`figures/first_cycle_conditioning.pdf` and `figures/conditioned_control_response.pdf` remain reproducible auxiliary simulation views but are not referenced by the article. `figures/` and `comparison/` also contain outputs from older or separate studies.
