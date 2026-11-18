# Addition: strategy-marcolino

The author requested adding `strategy-marcolino` to the existing comparison. This is a conditioning-policy reference, not a sixth certified gain optimization. It uses the unchanged current LQR gain and the exact sequential-delay rule in `../s1-marcolino-conditioning-comparison/sequential_dwell_condition.m`.

The five optimized gains, their original SPEC.md, common.jl and source-hashed result records remain frozen. Do not rerun their optimization or rewrite their provenance for this addition. New Julia code belongs in `strategy-marcolino.jl` and `comparison_timing.jl`; final comparison/evidence/report are regenerated.

## Policy

At each actual cycle start, raw offsets are `-timing_scale*Kcurrent*z`. Each interior boundary is the later of its requested time and the preceding realized boundary plus 3 us. The final boundary is the later of the nominal period and the last interior boundary plus 3 us. The next cycle begins at that actual end.

There is no scalar beta, no post-scaling, no compensation for accumulated clock displacement and no gain redesign. Exact propagation uses all nine realized durations. The extra terminal-boundary motion is stored separately rather than hidden in the eight interior offsets.

The article's common-P certificate does not cover this policy. Its result and method records have `P=null`, `certificate=null`, `certificate_status="not-covered-variable-period"` and `policy="marcolino"`. The existing seven certified methods have `policy="uniform"` and remain the only entries in certificate-based strategy rankings.

## Shared final-evaluation contract

The comparison contains eight methods in order: current-lqr, saved-common-p, strategy-1 through strategy-5, strategy-marcolino. There are still 20 cases, yielding 160 trajectories and 16,000 exact cycles.

All original response fields remain. Marcolino has `beta=null`, `minimum_beta=null`; `conditioned_cycles` counts cycles where any actual boundary differs from the raw requested boundary. `applied_offsets` contains only the eight realized interior offsets relative to nominal boundaries. The last dwell also contains the terminal extension.

Every response additionally contains:

- `cycle_times`: 101 actual start/end times in seconds, starting at zero;
- `cycle_durations`: 100 realized durations;
- `terminal_extensions`: 100 extensions beyond the nominal period;
- `extended_cycles`, `total_boundary_delay_us`, `maximum_cycle_duration_us`;
- `anchor_sustained_time_ms`: actual elapsed time of sustained anchor crossing, or null;
- `reference_errors`: 101 errors against the original periodic reference at that method's actual cycle-start times;
- `reference_sustained_cycle`, `reference_sustained_time_ms`, `final_reference_error`;
- `clocked_times`: the identical 101-point grid j*T, j=0,...,100, for every method;
- `clocked_states`, `clocked_errors`: exact state and tracking error on that common grid, with no interpolation;
- `clocked_first_sample`, `clocked_sustained_sample`, `clocked_sustained_time_ms`, `final_clocked_error`;
- `clocked_error_sum`: sum of squared common-grid tracking errors for j=0,...,99;
- `clocked_error_ratio_lqr`: common-grid tracking-only sum divided by current LQR's value in the same case.

A common-grid state is obtained by exact partial propagation through its actual mode schedule. At j*T the nominal reference is the cycle anchor. `reference_errors` at actual method boundaries instead use exact nominal within-cycle propagation at t mod T. These two sampling conventions must not be confused.

The existing `cost`, errors, first/sustained cycles and `cost_ratio_lqr` remain anchor-sampled J100 quantities over 100 actual cycles. For Marcolino these are not a common-time tracking cost and are reported explicitly as such, not used to select a certified strategy. The common-clock tracking sum charges no input effort and must not be presented as the original J100 objective or as a physical energy measure.

Existing summary fields remain. Add `mean_clocked_error_ratio_lqr`, `worst_clocked_error_ratio_lqr`, `clocked_error_regressions`, `mean_clocked_sustained_time_ms`, `worst_clocked_sustained_time_ms`, `clocked_unsettled_cases`, and `maximum_final_reference_error`. A mean or worst sustained time is null if any case has no sustained crossing.

## Verification and reporting

Independently check the sequential schedule, terminal extension, all exact cycles and both reference/time-grid computations. Compare historical Marcolino cycle-start times and both error histories with the saved 1x/2x/3x MATLAB CSVs in the older conditioning study. Add rejection tests for silent period truncation, forged common-P coverage, fake beta, incorrect phase reset, changed common-clock samples and altered gain.

Keep original certified-gain tables/rankings scoped to the five optimization strategies. Show strategy-marcolino clearly as an uncertified variable-period reference. Include physical elapsed-time and common-clock tracking comparisons; do not interpret faster anchor convergence as faster fixed-clock tracking. No article or old-study evidence is changed.
