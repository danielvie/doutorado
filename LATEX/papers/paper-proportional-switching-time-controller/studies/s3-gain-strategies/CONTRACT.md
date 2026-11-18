# Strategy worker contract

The shared `common.jl` is implemented and has reproduced current LQR and saved Common-P trajectories at 1x/2x/3x against the saved MATLAB evidence. Its fixed-gain SDP was exercised successfully. Do not edit shared files.

Each worker owns only `strategy-i.jl`, `results/strategy-i.json` and optional uniquely named strategy-i logs. Use the approved SPEC.md. No changes to old studies or publication inputs.

## Julia entry point

    using LinearAlgebra, Convex, Clarabel
    include("common.jl")
    using .GainStudy

Guard execution with an `if abspath(PROGRAM_FILE) == @__FILE__` block, not an unparenthesized macro followed by &&.

Run from this study directory:

    julia --startup-file=no --project=../s1-lyapunov strategy-i.jl

## Shared inputs

`m=load_model()` returns Model fields `A`, `B`, `S`, `ts`, `anchor`, `dwell`, `D`, `F`, `Kcurrent`, `Pcurrent`, `Kdecay`, `Pdecay`. A is 3x3, B is 3x8, gains are 8x3. All gains are normalized. Do not use an affine feedforward term.

`training_cases(m)` returns six named tuples with `name`, `split`, `z`. Do not select using `all_cases`, withheld or historical-stress results. Training case 1 is the article 1x state.

## Shared functions

- `baseline_costs(m)`: six current-LQR cost denominators. Compute once per worker.
- `training_score(m,K,denominators)`: named tuple `mean_ratio`, `worst_ratio`, `gain_norm`, `costs`, `settling`. Evaluates the exact plant for all six training cases with the actual conditioner and fixed Q/R evaluation weights.
- `better(score,best_score)`: deterministic comparison specified in SPEC.md.
- `certificate(m,K,P; margin=1e-9)`: symmetrizes and trace-normalizes P to 3, checks floor and both endpoint decreases; throws ErrorException on rejection. Returns `(P,check)` where check includes endpoint_decreases, min_eigenvalue_P, trace_P, condition_number_P, raw_radius.
- `fixed_gain_certificate(m,K)`: Julia SDP, returns `(P,check,status,eta)` or `nothing` if numerically rejected. Unexpected exceptions should be recorded separately, not called infeasible.
- `solver_factory()`: Clarabel optimizer with common tolerances.
- `symmetric(A)`: symmetric part wrapped in Symmetric.
- `contraction_block(X,G,r)`: `[r^2 X G'; G X]`.
- `checked_lqr(A,B,Q,R)`: checked DARE iteration, no new dependency.
- `write_result(name,m,K,P,score,logs; description,parameters=Dict(),elapsed_seconds=0.0,extra=Dict())`: rechecks final certificate and writes complete row-oriented JSON with K/P/physical gain, training score, candidate log and source hashes. `name` must be strategy-i. Include candidate/evaluation/solver/rejection counts, termination reason, and clear improved/unchanged status in extra.
- `write_json`, `read_json`, `json_matrix`, `json_value`, `source_hashes`, `file_hash` are exported.

`simulate(m,K,z0)` returns a string-keyed Dict with cost, states, errors, raw_offsets, applied_offsets, dwells, beta, stage_cost, first_cycle, sustained_cycle, final_error and scalar summaries. Missing threshold is `nothing`. The certificate must be checked before treating any gain as accepted.

## Numerical requirements

Always include an accepted seed in the search and record it in candidate logs. Strategies 1/2/3/5 may retain current LQR if no synthesized candidate improves it; strategy-4 starts at saved Common-P. Do not hide unchanged seeds. Save failed parameter settings and rejection reasons too.

Strategies 2/3 must independently check their additional claimed cost/rate/effort LMIs and save residuals and raw synthesis variables in extra; normalized stability P is separate from an unnormalized cost P. Never claim a conditioned nonlinear cost bound.

No source edits after writing final result hashes. If a worker source changes, regenerate its result. Source references for the installed API are listed in SPEC.md.
