# Julia synthesis migration

The offline gain synthesis moves from CVXPY to Convex.jl and Clarabel, following `studies/lyapunov/analysis.jl`. The endpoint LMIs, trace normalization, rate bisection, numerical acceptance thresholds and MATLAB JSON/CSV interface stay unchanged. MATLAB continues to own exact-plant simulation; Python continues independent checks and plotting.

The study reuses the pinned `studies/lyapunov/Project.toml` and `Manifest.toml`. Its Julia entry point is `analysis.jl`; `main(output_dir=...)` permits isolated validation. A different feasible gain is acceptable because the design is nonunique. Validation compares rate brackets and independently recomputed inequalities, not gain entries.

Existing numerical evidence and the compiled report are preserved. The old Python source is archived byte-for-byte, and provenance checks still require exact hashes. The default synthesis task writes the existing output interface for future full regeneration, but migration checks use a temporary directory and do not replace the historical gain or pair a new gain with old trajectories.

## Ordered work

1. Port synthesis and checks to `analysis.jl`, using the existing pinned Julia environment.
2. Wire task commands and provenance checks; update documentation, Python dependencies and the editable diagram.
3. Solve into temporary output, independently check JSON/CSV exports and certificates, exercise rejection checks, and verify the retained evidence read-only.

## Verification boundary

Run the real Julia SDP, focused numerical/export tests, task dry runs and the saved-evidence verifier. Do not rerun MATLAB trajectories, timings, publication generation or unrelated article tests. Confirm saved CSV/JSON/MAT hashes are unchanged.
