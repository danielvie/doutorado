# Article source map

Status: descriptive source map
Source of truth: `article.tex`
Read when: navigating or rewriting the manuscript

## Entry point

`article.tex` is a single-file Springer Nature manuscript. It loads the local class and bibliography style, includes the generated `results/metrics.tex` file, defines a few vector and timing macros, and contains the complete article.

There are no section-level `.tex` files included by the manuscript.

## Source regions

- Lines 1–24: document class, packages, generated metrics, macros, and document start.
- Lines 26–37: title, authors, affiliation, abstract, keywords, and title page.
- Lines 39–48: Introduction.
- Lines 49–207: fixed-period one-cycle model.
- Lines 208–278: dwell conditioning and common-Lyapunov certificate.
- Lines 280–410: converter case study, tables, figures, and simulation discussion.
- Lines 411–418: Discussion.
- Lines 419–421: Conclusion.
- Lines 423–437: declarations, currently containing author-dependent TODOs.
- Lines 439–441: bibliography and document end.

## External inputs

The manuscript directly includes:

- `results/metrics.tex` for generated numerical macros;
- four figure files from `figures/`;
- bibliography records from `references.bib`.

The tables are written directly in `article.tex`.

## Current figures

The current source references:

- `figures/reference_schedule_orbit.pdf`;
- `figures/first_cycle_conditioning.pdf`;
- `figures/conditioned_control_response.pdf`;
- `figures/conditioned_trajectory.png`.

## Rewrite navigation

For prose and narrative, inspect the Introduction, section openings, Discussion, and Conclusion first. For factual numerical changes, trace the metric macro to `results/metrics.csv` and then to `scripts/generate_results.m`. For derivation changes, inspect Section 2 and the linearization notes before editing equations.
