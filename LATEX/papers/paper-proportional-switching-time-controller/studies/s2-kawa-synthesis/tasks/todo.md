# Julia synthesis migration tasks

- [x] Port the unchanged decay-rate SDP, bisection and certificate checks to `analysis.jl`, retaining the MATLAB-compatible output schema.
- [x] Switch task commands to Julia, preserve strict historical provenance, and update documentation and diagram. Python requirements remain necessary for the verifier's transitive physical-model imports.
- [x] Validate a real Julia solve in temporary output, independent export/certificate checks, rejection checks and retained saved evidence; confirm numerical hashes unchanged.

Verification: `task kawa-synthesis:test-synthesis` passed 9 Julia assertions and 4 independent Python tests. `task kawa-synthesis:test` passed for the retained 12 historical trajectories, 1200 exact cycles and 3840 timing samples. The Julia rate bracket matched the saved bracket; gain entries differed, as allowed by feasibility nonuniqueness. SHA256 checks passed for all 12 saved CSV/JSON/MAT evidence files. No MATLAB simulations, timings, article tests or report rebuild were run.

The author requested reducing the diagram to the proposal's extra work. It now has three new-work panels, a compact reused-components strip and a scope note, with no expanded model/conditioner/plant loop.
