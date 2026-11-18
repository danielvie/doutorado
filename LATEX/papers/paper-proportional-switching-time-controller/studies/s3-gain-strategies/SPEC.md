# Five Julia gain strategies

Status: approved by the author for implementation and execution. The user approved the five-strategy experiment and asked to implement it.

## Objective

Find better fixed switching-time gains without giving up the existing common-P guarantee for every conditioning factor in [0, 1]. Julia performs all gain optimization. Five independent strategy workers run in parallel after the shared model, objective and certificate checks are validated. A separate report compares every strategy, including unsuccessful searches, with the current LQR and the saved Common-P gain. Saved MPC-5 provides an additional reference only on matched historical cases.

This is one separate numerical study. It does not replace the article controller, manuscript, or publication evidence. Better performance is an experimental question, not a promised outcome.

## Fixed comparison contract

- Reuse the current full-precision converter, anchor, nine-interval sequence, 286 us period, state scale diag(10,20,1), 10 us timing scale, and 3 us applied dwell bound.
- Every candidate remains a constant 8-by-3 gain followed by the existing maximal-feasible scalar conditioner. No online optimizer, gain switching, fallback policy or change of nominal schedule is introduced.
- Evaluate the exact switched-affine plant for 100 cycles. The objective uses actual cycle-start errors and applied offsets, not the unconditioned linearized prediction.
- Keep evaluation weights Q=I3 and R=0.001 I8 for every method, even when synthesis weights vary.
- J100 excludes terminal penalties. Report both first and sustained crossings of normalized error below 0.01. Sustained means the rest of the saved 100-cycle horizon.
- Reconstruct the physical model in Julia and compare its matrices and baseline trajectories against the saved MATLAB/Python evidence before optimizing.
- Use current directories `studies/s1-lyapunov`, `studies/s1-mpc-comparison`, and `studies/s2-kawa-synthesis`. Do not rely on the stale unprefixed task/import paths.

## Strategy definitions

| Name | What changes | How stability is retained | Initial search budget |
| --- | --- | --- | --- |
| strategy-1 | Tune diagonal LQR state weights and scalar timing weight. Search Q=diag(10^a,10^b,1), R=0.001*10^c I. | Solve the fixed-gain common-P SDP for each candidate and independently check the returned certificate. | 27 coarse grid points, then up to 18 coordinate refinements; cache duplicates. |
| strategy-2 | Joint gain/certificate synthesis minimizing a full-feedback quadratic cost bound. Sweep synthesis timing weights and an acceptable open-endpoint contraction bound. | One P must certify the open endpoint and full-feedback endpoint. The cost bound itself applies only to full feedback. | Nine SDP settings: timing weight in {0.0001,0.001,0.01}, open rate in {0.9999,0.99995,0.99999}. |
| strategy-3 | Use separate open/full-feedback contraction targets and minimize timing effort plus margin-normalized dwell demand. | Fixed endpoint-rate LMIs use a shared X=P^-1 and Y=KX. Full-feedback rate must exclude zero feedback. | Twelve SDP settings: open rate in {0.9999,0.99999}, full-feedback rate in {0.25,0.5,0.8}, dwell penalty in {0.01,0.1}. |
| strategy-4 | Redistribute timing corrections with K=K0+N Z, BN=0, starting from the saved Common-P gain. Use bounded deterministic search against the actual conditioned response. | BK stays unchanged, preserving the entire linearized matrix family and its existing certificate. Check numerical residuals independently. | At most 200 training-objective evaluations, including the seed. All bounds, search directions and termination reasons are saved. |
| strategy-5 | Directly tune all gain entries against the actual conditioned response, starting from current LQR. Use scaled coordinate steps and backtracking. | Hold the current P fixed. Accept only gains whose endpoint decrease margins exceed 10% of the seed's verified minimum margin, plus numerical tolerance. | At most 200 training-objective evaluations, including the seed. Record certificate rejections separately. |

The finite budgets make this an exploratory comparison, not a global optimization claim. Different strategies need not use their entire budgets. Record solver calls, candidate counts, objective evaluations and elapsed time separately.

## Common performance objective

Let z=S^-1(x-anchor), and let v_applied be applied offsets divided by the timing scale. Each trajectory has

    J100 = sum(k=0:99, dot(z_k,z_k) + 0.001*dot(v_applied_k,v_applied_k)).

Select each strategy's final gain using the mean of J100(candidate)/J100(current LQR) over the training cases. Ratios prevent the largest initial error from dominating solely by magnitude. Set the deterministic tie-break order to lower worst training cost ratio, lower gain norm, then earlier candidate.

Retain the seed as a comparison, and label an unchanged seed honestly. Never call a numerically rejected certificate proof of instability. Do not select gains using withheld outcomes. Report settling-time regressions even when average cost improves.

## Training and withheld cases

All new cases are specified in normalized error coordinates. Actual initial states are anchor+S*z.

Training cases:

1. Existing article 1x initial state [7.5143,20.8211,0.0314].
2. The opposite normalized error of case 1.
3. z=[-0.20,-0.10,-0.40].
4. z=[0.20,0.10,0.40].
5. z=[-0.10,0.15,0.20].
6. z=[0.10,-0.15,-0.20].

Withheld cases:

- Six signed axes: z=[+/-0.15,0,0], [0,+/-0.15,0], [0,0,+/-0.50].
- Six mixed directions: [0.15,0.15,0.30], [-0.15,-0.15,-0.30], [0.15,-0.15,0.30], [-0.15,0.15,-0.30], [0.15,0.15,-0.30], [-0.15,-0.15,0.30].

The new cases start with positive physical states. This is not a validated hardware operating envelope. Report sampled negative excursions rather than claiming state safety.

Also evaluate the historical 2x and 3x article-error cases separately. Their negative initial currents make them mathematical stress tests. Together with 1x, these permit matched comparisons with saved MPC-5 evidence. Do not imply that MPC was rerun on the additional cases.

## Certificate acceptance

Every reported gain must have a matching P. Normalize the stability-check matrix to trace(P)=3 and directly recompute:

- symmetry and trace residuals;
- positive definiteness, with minimum eigenvalue at least 1e-7 within the stated numerical tolerance;
- minimum eigenvalues of P-A'PA and P-(A-BK)'P(A-BK), both strictly above 1e-9;
- normalized/physical gain conversion and gain recovery where applicable.

For strategy-2, save the unnormalized cost certificate and its cost residual separately from the normalized stability certificate. For strategy-3, also check the claimed contraction, effort and dwell-demand blocks. For strategy-4, check BN and B(K-K0). Every certificate check uses full precision, not displayed rounded matrices.

The endpoint theorem covers arbitrary conditioning-factor sequences for the linearized family. Exact-plant simulations do not establish a nonlinear region of attraction, global nonlinear stability, robustness to model uncertainty, or physical state safety. Checks are floating-point checks, not interval-arithmetic proofs.

## Software and source ownership

Use the installed pinned environment without adding Julia packages:

- Julia 1.12.7;
- Convex.jl 0.16.7;
- Clarabel 0.11.1;
- JSON3 1.14.3;
- Julia standard-library linear algebra, exact matrix exponentials, deterministic search and checked Riccati iteration.

Model, objective, certificate checking, evaluation and final integration have one coordinator. Each strategy worker owns only its own implementation, candidate log and result files. Workers cannot edit shared numerical helpers or another strategy's files. A common output contract is established before strategy implementation starts.

All new work stays under `studies/s3-gain-strategies/`:

- `common.jl`: shared model, conditioner, exact simulation, objective and certificate functions;
- `strategy-1.jl` through `strategy-5.jl`: independent optimizations;
- `evaluate.jl`: final training/withheld/historical evaluation;
- `verify_results.py`: independent saved-evidence checks, no gain optimization;
- `results/`: gains, certificates, candidate logs, trajectories, metrics and provenance;
- `report.md`, report PDF source and `report.pdf`: comparison and conclusions;
- `Taskfile.yml`: setup, run, individual strategies, test, report and clean commands;
- study-local implementation plan and task checklist, leaving the existing paper-root MPC review tasks untouched.

## Proposed commands

These commands are requirements for implementation, not currently available tasks:

    task --dir studies/s3-gain-strategies --list
    task --dir studies/s3-gain-strategies run
    task --dir studies/s3-gain-strategies strategy-1
    task --dir studies/s3-gain-strategies strategy-2
    task --dir studies/s3-gain-strategies strategy-3
    task --dir studies/s3-gain-strategies strategy-4
    task --dir studies/s3-gain-strategies strategy-5
    task --dir studies/s3-gain-strategies test
    task --dir studies/s3-gain-strategies report

The default task lists commands. The run task executes all five strategies concurrently after shared checks, then evaluates, verifies and builds the report. Direct Julia execution uses `--project=../s1-lyapunov` from the study directory. Rebuilding the report must not rerun optimization or simulation.

## Code style and official API references

Follow the existing Julia study style: explicit inputs, row-oriented JSON matrices, symmetrized numerical checks, linear solves rather than avoidable inverses, and a guarded main entry point. For example:

    function endpoint_margin(A, P)
        Q = P - A' * P * A
        return eigmin(Symmetric((Q + Q') / 2))
    end

Official API references retrieved for this work:

- https://jump.dev/Convex.jl/stable/manual/types/
- https://jump.dev/Convex.jl/stable/manual/operations/
- https://clarabel.org/stable/api_settings/
- https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/

## Verification and report acceptance

- Reproduce the saved current LQR and Common-P baseline trajectories and costs before searches start.
- Independently reconstruct the physical model and check every final saved exact cycle, conditioner result, dwell, period, cost and threshold.
- Independently check every final certificate and all source/model hashes. Include rejection tests for invalid certificates, altered gains and stale evidence.
- Test only the new study and directly reused numerical contracts. Do not regenerate the article or run unrelated full suites.
- Save the best accepted candidate and an honest status for every strategy, even if no improvement is found.
- Report per-case J100, training and withheld cost ratios, first/sustained settling time, final error, minimum raw/applied dwell, minimum beta, number of conditioned cycles, gain norm, certificate margins, offline effort and failure counts.
- Compare all five strategies with current LQR and saved Common-P on identical new cases. Compare MPC only on its identical historical cases. Historical MATLAB timing must not be presented as a matched benchmark against newly measured Julia timings.
- Include readable error/cost/conditioning comparisons and a concise recommendation based on withheld results, not the best training case.
- Keep the manuscript, existing gains, certificates and publication outputs unchanged.

## Approval

The author approved this setup and requested implementation. Run status, results and any implementation refinements are recorded in the study-local tasks and final report.
