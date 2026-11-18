# Common-P gain synthesis under dwell conditioning

This separate study compares the unchanged current conditioned LQR and native MPC-5 with one offline gain design, **Common-P gain synthesis**, following Kawakami's suggestion in `_study_kawa/`. The report source is [report.tex](report.tex), and the compiled result is [report.pdf](report.pdf). The manuscript uses this study's saved Common-P gain, certificate, and comparison. The LQR gain and MPC ingredients remain unchanged as baselines.

The active optimization is [analysis.jl](analysis.jl), structured like [the Lyapunov study](../lyapunov/analysis.jl). Convex.jl and Clarabel jointly compute the gain and common-P certificate offline. MATLAB applies the exported gain and simulates the exact plant; Python checks and plots saved evidence. The editable [proposal helper](kawakami-implementation.excalidraw) shows only the added joint synthesis, rate search and evaluation of the new gain. The established model, conditioner and plant simulator appear only as reused components.

The report uses separate pages and larger labels rather than small multi-case grids. Its dedicated [convergence-speed comparison](figures/convergence_speed.pdf) shows sustained threshold times in cycles and milliseconds. Each initial-error case has its own full-page 3D path, full-width coordinate-plane projections, and physical-state histories. Convergence errors, accumulated cost, conditioning factors and applied dwells are also separated. Trajectory figures retain the existing first-twelve-cycle dense samples and actual cycle-start markers. Redrawing does not rerun synthesis, simulation, or timing measurements.

| Initial error | 3D paths | Coordinate-plane projections | Voltages/current |
| --- | --- | --- | --- |
| 1x | [Figure](figures/state_space_1x.pdf) | [Figure](figures/trajectory_projections_1x.pdf) | [Figure](figures/physical_states_1x.pdf) |
| 2x | [Figure](figures/state_space_2x.pdf) | [Figure](figures/trajectory_projections_2x.pdf) | [Figure](figures/physical_states_2x.pdf) |
| 3x | [Figure](figures/state_space_3x.pdf) | [Figure](figures/trajectory_projections_3x.pdf) | [Figure](figures/physical_states_3x.pdf) |

## Commands

From the paper root:

```sh
task kawa-synthesis:run         # Synthesis, 9 exact-plant trials, timings, checks, PDF
task kawa-synthesis:synthesize  # Run Common-P gain synthesis in Julia
task kawa-synthesis:results     # Regenerate study evidence and report inputs
task kawa-synthesis:replot      # Redraw saved evidence and regenerate LaTeX inputs
task kawa-synthesis:test        # Read-only saved-evidence checks, no SDP/MPC solve
task kawa-synthesis:test-synthesis # Real Julia solve and independent checks in temporary output
task kawa-synthesis:build       # Build saved report inputs without MATLAB/Python
task kawa-synthesis:clean       # Remove build intermediates, retain evidence and PDF
```

From this study directory, omit `kawa-synthesis:`. Julia reuses the Lyapunov study's pinned [Project.toml](../lyapunov/Project.toml) and [Manifest.toml](../lyapunov/Manifest.toml), with Julia 1.12.7, Convex.jl 0.16.7 and Clarabel 0.11.1. `task kawa-synthesis:setup` instantiates that environment without changing the fixed-gain Lyapunov analysis. Direct execution from this directory is `julia --project=../lyapunov analysis.jl`.

Python dependencies are pinned in [requirements.txt](requirements.txt). CVXPY remains a transitive import of the independent physical-model builder used by the saved-evidence verifier; that verifier does not solve an SDP. Active Kawakami optimization runs only in Julia. The other commands use `uv`, MATLAB R2025b with Control System Toolbox, Optimization Toolbox and MPT3, Go Task, and LaTeX with `latexmk`. The native converter and MPC packages remain in the sibling simulation project. MATLAB must already have MPT3 configured, as for the existing MPC comparison.

## Designs and fixed comparison contract

The normalized dynamics are `z_next = (A - beta B K) z`, with `z = inv(S) (x-anchor)`, `S = diag(10,20,1)`, timing scale 10 us, `Q = I3` and `R = 0.001 I8`. Every static gain uses the existing scalar dwell conditioner. MPC-5 retains its native horizon, zero initial plan, terminal cost, invariant terminal set, and direct QP solve. No failed solve is replaced by fallback feedback.

- **Common-P gain synthesis** (`kawa_decay`) is joint feedback-gain and Lyapunov-matrix synthesis via LMIs with a decay-rate objective. It follows the classical fixed-rate feasibility SDP in Kawakami's attached PDF inside bisection. `trace(X)=3`, `X >= 1e-7 I`, `Y=KX` and common endpoint contraction blocks determine a feasible gain. There is no secondary objective selecting timing effort or nonlinear performance. The returned CLARABEL point is saved in full precision. The optimum rate is limited by the open endpoint; a separately constructed zero-feedback certificate demonstrates gain nonuniqueness at the same returned rate.

Convex.jl PSD variables, block inequalities and feasibility objectives follow the [official types documentation](https://jump.dev/Convex.jl/stable/manual/types/). Clarabel options follow the [solver settings documentation](https://clarabel.org/stable/api_settings/). The Julia port retains the original `1e-9` solver tolerances, 500-iteration limit, `1e-6` bisection tolerance and independent eigenvalue acceptance checks. A numerical rejection is not a proof of infeasibility, so the returned bracket is not a rigorous optimality bound.

The candidate is evaluated with the same article converter, full-precision reconciled schedule, 286 us period, nine mode intervals and 3 us minimum applied dwell. Initial displacements are the existing 1x, 2x and 3x multiples of `[7.5143,20.8211,0.0314] - anchor`. Each run covers 100 cycles with exact switched-affine propagation. Julia loads the saved normalized model from the Lyapunov study. The exported synthesis model is checked against the independently constructed MATLAB article model before applying gains. Current LQR and MPC-5 trajectories are checked against their existing evidence for all three cases.

`J100` sums actual normalized cycle-start squared error plus weighted **applied** timing effort over 100 cycles. It excludes MPC's terminal penalty. First threshold crossing and sustained crossing of error below 0.01 are reported separately. Sustained means the rest of the saved horizon, not every future cycle.

## Files and evidence

| File | Responsibility |
| --- | --- |
| [analysis.jl](analysis.jl) | Active Julia decay-rate bisection, full-precision certificate checks, JSON/CSV exports and source/environment hashes |
| [test_analysis.jl](test_analysis.jl) | Fast Julia checks of matrix serialization, the zero-gain certificate and invalid-certificate rejection |
| [test_synthesis.py](test_synthesis.py) | Temporary Julia solve, independent certificate/export checks and rejection checks |
| [simulate_comparison.m](simulate_comparison.m) | Fresh exact simulations using existing model/controller helpers and baseline comparisons |
| [benchmark_timing.m](benchmark_timing.m) | Matched full-controller host timings on one common state pool |
| [export_report.py](export_report.py) | Figures, tables, macros and brief observations from saved evidence |
| [plot_trajectories.py](plot_trajectories.py) | Three-controller 3D paths and coordinate-plane projections with the periodic reference |
| [verify_results.py](verify_results.py) | Independent Python checks of matrices, all exact cycle transitions, conditioning, costs, summaries and timing statistics |
| [results/synthesis.json](results/synthesis.json) | Gains, certificates, optimization settings, bisection history, raw solver outputs and source hashes |
| [results/comparison.mat](results/comparison.mat) | All states, raw/applied eight-offset vectors, dwells, exact plant/model/controller inputs and metadata |
| [results/summary.csv](results/summary.csv) | Performance and sampled state-extrema summary, including retained historical runs |
| [results/history.csv](results/history.csv) | Cycle-start states, errors, beta, applied/raw minimum dwell, actual stage and accumulated costs |
| [results/commands.csv](results/commands.csv) | Every raw/applied dwell and start-boundary offset for all 100-cycle runs |
| [results/trajectories.csv](results/trajectories.csv) | First twelve cycles on each controller's own exact sampling grid and periodic reference |
| [results/timing.csv](results/timing.csv) | Matched median/p95 and separately labeled first benchmark observations |
| [results/timing_samples.csv](results/timing_samples.csv) | Individual timed calls, including retained historical measurements |
| [results/timing_states.csv](results/timing_states.csv) | Common timing workload and source labels |
| [results/validation.json](results/validation.json) | Focused-check outcomes and numerical source hashes |

The current result is exploratory: the rate-selected gain can be fast even though the rate objective itself does not reward that speed. The report distinguishes threshold time from accumulated cost and compares both against MPC. It makes no claim that this candidate optimizes the actual conditioned nonlinear response.

### Julia migration and retained evidence

The saved `results/synthesis.json`, trajectories and timings still come from the historical Python implementation, not the Julia port. A pure-feasibility gain is nonunique, even with the same solver. The migration checks the Julia rate and certificate in temporary output and does not silently replace the gain used by those saved simulations. `test-synthesis` leaves the production outputs untouched. `main(output_dir=...)` is also available after including `analysis.jl` for isolated checks.

`task kawa-synthesis:synthesize` writes the existing `synthesis.json` and `gains_normalized.csv` interface for MATLAB. After intentionally replacing a gain, use `task kawa-synthesis:run` to regenerate the matching trajectories, timings, validation and report. Do not combine a newly synthesized gain with the old simulated response.

Performance LMI is excluded from the active comparison, figures and tables. Its saved `kawa_cost` rows and synthesis records remain in the existing CSV/MAT/JSON evidence to preserve the original simulations and matched timing workload. The report exporter selects only `current`, `mpc5` and `kawa_decay`, plus the periodic reference. Removing the fourth controller from the report does not change any saved state, gain, command, cost or measured time. Future full regeneration uses only the three active controllers. The original four-controller source is retained unchanged in [archive/synthesize-four-controller.py](archive/synthesize-four-controller.py), and the last decay-only Python source is in [archive/synthesize-decay.py](archive/synthesize-decay.py). Historical provenance requires the exact producer's hash; new Julia exports record `analysis.jl` and the shared Julia environment instead. Standalone `test` checks are read-only; the full `run` explicitly refreshes `validation.json` with `verify_results.py --write-validation`.

## Timing protocol

The saved comparison retains the original common workload of 48 physical states, taken from the first twelve cycle starts of the four historical 1x responses. Duplicates are retained. Each reported method has 96 warmups and 960 measured calls in deterministically rotated, interleaved order. Removing the fourth controller does not resample this workload or retime the remaining methods. Future full regeneration builds the workload from the three active responses instead; workload and call counts are read from the saved evidence when reporting results. Measurements include physical error calculation, required normalization, control and schedule validation. Offline construction, input selection, plant propagation and file I/O are excluded. MPC retains its zero plan on every call.

The `cold_us` CSV column is the **first observation within the benchmark**, after the trajectory simulations and before its dedicated warmups. It is neither a process-cold nor cache-cold measurement. MATLAB `prctile` p95 is independently recomputed with NumPy's Hazen quantile convention. Timings are host observations, not worst-case execution or embedded deadline guarantees.

## Scientific limits

The common-P certificates cover the conditioned **linearized** family for arbitrary factors in [0,1]. Direct floating-point eigenvalue checks are not interval-arithmetic proofs. Exact-plant simulations do not establish a nonlinear region of attraction or global stability.

The 2x/3x trials start with negative inductor current. MPC-5 also produces negative first-capacitor voltage in the saved 3x trial. No controller imposes physical state limits. Sampled extrema combine all cycle-start states with dense samples over the first twelve cycles; they are not continuous-time extrema over the full run. This one error direction at three magnitudes is not uncertainty testing or a general controller ranking.
