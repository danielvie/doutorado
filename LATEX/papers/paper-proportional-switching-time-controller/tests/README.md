# Validation

Run commands from the paper root.

- `task test` checks zero and feasible actions, maximality/direction/period on 100 seeded random actions, rejection of an infeasible nominal schedule, stored model and gain agreement, exact cycle closure, and path isolation. It also checks the common-P Schur-complement equivalence, block congruence, convex endpoint interpolation, an independent expansion identity, state-dependent linearized decrease, rejection of invalid certificates and stale models, and dense-sample agreement with every switching boundary. Timing-schematic tests also check unchanged endpoints, equal-and-opposite dwell changes, feasibility of the illustrative offset, raw-action agreement, stale-data rejection, and vector/PNG exports. Publication-figure tests check the exact early state/time slices, the repeated periodic reference, rejection of stale or invalid samples, physical figure width and font defaults, and a replot-only export that writes no CSV/MAT/metric files. Export tests use temporary directories only.
- `task test-regeneration` runs the complete pipeline into a temporary directory and removes that directory afterward. It compares ten CSV files, both LaTeX macro files, the publication certificate, both MAT records, invariant-region data, and polyhedron equality against saved article evidence. It also checks all ten exported PDF paths, including the three timing panels and the new `state_time_comparison.pdf` in place of the old long-run state/3D plot.
- `task check-links` checks local file targets in maintained Markdown and HTML. It excludes historical archives, handoffs, and tool/build artifacts; it does not check network URLs or fragment identifiers.
- `task verify` runs unit checks, link checks, article generation, and LaTeX compilation.

The full regeneration comparison is intentionally exact. Use the recorded MATLAB/MPT environment when auditing a refactor. Solver or scientific changes may require reviewing differences and deliberately updating the stored baseline. Do not silently replace the baseline before running this check.

## Organization-pass evidence

A full pre-change workspace snapshot and a fresh run of the original generator were saved outside the repository before refactoring. The extracted pipeline passed `check_regeneration` against both the original stored evidence and the freshly generated baseline.

Validation also completed for:

- `task verify`, including the final LaTeX pass with resolved citations and references;
- `task lyapunov:reproduce`, Python reconstruction followed by Julia;
- `task lyapunov:matlab`, independent MATLAB reconstruction and CVX/SDPT3 comparison;
- `task trajectory-comparison`, after moving its script and outputs together.

The organization pass did not change manuscript claims. The subsequent common-P rewrite adopts the Julia certificate, adds publication trajectory exports, and moves invariant-region analysis to an appendix. Before these changes, the original eight-CSV regression passed. The established metrics, gains, schedules, and response schema remain unchanged; the new evidence is additive. The Introduction is preserved for the author's later revision. PDF/MAT byte hashes can change on regeneration because of export metadata; the numerical comparison checks scientific data rather than binary hashes.
