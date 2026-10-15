# MPC integration plan

Status: implemented and verified; awaiting author review. The current PDF has 15 total pages. This scope supersedes the earlier four-panel/cumulative-cost proposal.

## Purpose

Show a solver-free alternative when online predictive optimization is computationally impractical. The article's contribution remains maximal dwell-feasible radial conditioning and a common-P certificate for the conditioned linearized family. MPC-5 provides a limited performance/computation reference, not another contribution or a claim of general dominance.

## Protected material

The Introduction must remain byte-for-byte unchanged. Its byte interval starts at `\section{Introduction}` and ends immediately before `\section{Problem formulation and one-cycle model}`. SHA256:

`00b49c6f8b5d992168c44272c0e194aa57f9d06f48313cff831dab582d9343f9`

Preserve the benchmark, gains, Lyapunov certificate, ordered derivation, theorem and its scope. Keep open-loop eventual convergence visible. The completed integration preserves the Introduction's raw bytes; the automatic build guard permits only Git checkout line-ending normalization. Declarations were merged verbatim from the author-authorized Overleaf commit `11d3e48`, including its remaining TODOs. Do not alter title, abstract, keywords, global fonts, margins, or class to force pagination.

## Approved integration

- Original 1x initial state only; retain 2x/3x and MPC-2/MPC-10 evidence in the separate study/archive.
- MPC-5 uses the same normalized model, Q/R, schedule, period, dwell bound, and initial state. Retain its existing terminal cost/set and zero-plan QP initialization.
- Evaluation cost uses actual states/applied inputs over 100 cycles, without the MPC terminal penalty.
- Extend the existing three-panel response figure with MPC error and applied minimum dwell. Keep proposed-controller beta, raw requests, forbidden-dwell shading, and open loop. Display the first 12 cycles against elapsed time, with actual threshold samples.
- Keep scalar cost and matched median/p95 computation in a two-controller block within the existing results table. No extra main-text figures/tables or cumulative-cost panels.
- Add a short application comparison and at most two Discussion sentences. Describe dwell feasibility and linearized stability precisely, not unrestricted hardware safety.

## Matched timing

Time the complete physical-state-to-validated-schedule path for both controllers on the same MATLAB host and identical saved states. Separate first calls from warmed samples; retain the native zero-plan policy; interleave method ordering. Save raw samples, per-state labels, summaries, environment, and source hashes. Do not compare C++ beta-only timing with MATLAB MPC or claim embedded deadlines.

## Publication and validation

The study owns solving/timing. Publication imports must check model, gain, schedule, weights, normalization, initial state, horizon, completion, cost, dwell and source consistency. Export a separate article comparison record/macros. `task build` remains solver-free and uses cached publication inputs; replot only reads saved data. Add negative stale-evidence tests and compare new publication outputs during regeneration.

## Length target

Aim for 15 total compiled PDF pages including appendix and references. The starting PDF has 18 pages. Tighten repetitive exposition and improve figure placement outside the Introduction, without dropping the mathematical derivation or stability qualifications, shrinking fonts, or changing the Introduction. Preserve readable 160 mm figures and approximately 9-10 pt labels.

Implementation and verification progress are recorded in `tasks/todo.md`.
