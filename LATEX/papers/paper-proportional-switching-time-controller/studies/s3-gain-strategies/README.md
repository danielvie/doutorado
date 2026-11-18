# Gain strategies and Marcolino conditioning

This separate study tests five offline ways to choose a fixed switching-time gain while retaining a common-P certificate for every conditioning factor in [0,1]. It also includes `strategy-marcolino`, an unchanged-LQR sequential-delay reference that is not covered by that certificate. The manuscript, article gains and publication evidence are not changed.

The separate comparison document is [five-method-comparison.pdf](five-method-comparison.pdf), with [Markdown](five-method-comparison.md). It now contains only current LQR common-P, the original joint Common-P gain, Marcolino and MPC-5 on their three matching historical cases. The original filenames are retained so existing links still work.

The original approved experiment is [SPEC.md](SPEC.md); the added policy and timing contract are in [MARCOLINO.md](MARCOLINO.md). The comparison is [report.md](report.md), with a printable [report.pdf](report.pdf). Full-precision numerical evidence belongs in [results/](results/). The five optimized gains remain unchanged by this addition.

## Strategies

| Name | Design | Certificate |
| --- | --- | --- |
| [strategy-1](strategy-1.jl) | LQR weight grid and coordinate refinement | New fixed-gain common-P SDP per candidate |
| [strategy-2](strategy-2.jl) | Joint full-feedback state/timing cost synthesis | Shared open/full-feedback P, with a separate full-feedback cost bound |
| [strategy-3](strategy-3.jl) | Separate endpoint contraction targets, timing effort and dwell-demand penalties | Joint endpoint LMIs with common X=P^-1 |
| [strategy-4](strategy-4.jl) | Timing redistribution, K=K0+NZ with BN=0 | Preserves the saved Common-P matrix family |
| [strategy-5](strategy-5.jl) | Direct local search over gain entries using the exact conditioned cost | Current fixed-P endpoint inequalities retained with a positive margin |
| [strategy-marcolino](strategy-marcolino.jl) | Current LQR with sequential-delay conditioning | No common-P coverage for the variable-period rule |

All gains remain constant 8-by-3 matrices. The five optimized controllers use the existing scalar dwell conditioner. Marcolino instead postpones individual boundaries and can extend the final boundary. Neither policy uses an online optimization solver.

## Commands

From the paper root:

```sh
task --dir studies/s3-gain-strategies --list
task --dir studies/s3-gain-strategies run
```

From this directory:

```sh
task setup          # Check the already pinned Julia environment
task check-common   # Model, LQR, certificate and saved MATLAB baseline checks
task check-marcolino # Sequential schedule, phase and saved MATLAB history checks
task strategy-marcolino # Generate the unchanged-gain sequential-delay reference
task optimize       # All five Julia strategies in parallel
task strategy-1     # Or strategy-2 through strategy-5 individually
task evaluate       # Add Marcolino, then evaluate all eight policies
task validate       # Independent checks, rejection tests and validation record
task test           # Read-only saved-evidence and rejection checks
task report         # Full comparison from saved evidence only
task five-method-report # Separate four-method document, retaining its original task name
task clean          # Compilation/cache cleanup, retain results and report
```

`run` executes shared and Marcolino checks, parallel optimization of the five gains, Marcolino reference generation, final evaluation, independent validation and report generation in that order. Direct execution is `julia --startup-file=no --project=../s1-lyapunov strategy-1.jl`. Parallel workers write disjoint result files. The root paper Taskfile still contains older unprefixed study paths; this study's own Taskfile uses the current directory names and does not depend on those stale includes.

## Dependencies

Julia reuses [the pinned Lyapunov environment](../s1-lyapunov/Project.toml): Julia 1.12.7, Convex.jl 0.16.7, Clarabel 0.11.1 and JSON3 1.14.3. No Julia packages are added. Linear algebra, exact matrix exponentials, Riccati iteration and deterministic search use Julia's standard libraries.

Python uses the existing pinned [comparison requirements](../s2-kawa-synthesis/requirements.txt) through `uv --offline`. Python does no gain optimization. It independently reconstructs and checks the physical model and exact saved cycles, and renders the report figures. PDF compilation uses `latexmk` and the existing TeX installation.

Official API references:

- [Convex.jl PSD variables and constraints](https://jump.dev/Convex.jl/stable/manual/types/)
- [Convex.jl supported operations](https://jump.dev/Convex.jl/stable/manual/operations/)
- [Clarabel solver settings](https://clarabel.org/stable/api_settings/)
- [Julia linear algebra](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/)

## Evidence contract

[common.jl](common.jl) independently reconstructs the converter, nominal cycle model and timing sensitivity, then checks the model against the full-precision [saved synthesis inputs](../s2-kawa-synthesis/results/synthesis.json). [test_common.jl](test_common.jl) reproduces current LQR and saved Common-P state histories and costs at 1x/2x/3x before searches start. A checked Riccati solve reproduces the current LQR gain.

Six predeclared training cases select gains using the mean ratio of exact-plant J100 to current-LQR J100. Evaluation weights always remain Q=I and R=0.001, and charge applied timing changes. Twelve additional initial conditions are withheld from optimization. The historical 2x/3x cases are reported separately. Every trajectory has 100 exact cycles; sustained threshold crossing means error stays below 0.01 for the rest of that saved horizon.

[evaluate.jl](evaluate.jl) checks frozen result provenance, then writes [comparison.json](results/comparison.json), [metrics.csv](results/metrics.csv) and [summary.csv](results/summary.csv). [verify_results.py](verify_results.py) independently checks the final saved evidence. [test_verifier.py](test_verifier.py) rejects corrupted inputs. Source/model hashes prevent silently combining new code or gains with old trajectories. [CONTRACT.md](CONTRACT.md) records the worker interface.

## Marcolino and the clock

[strategy-marcolino.jl](strategy-marcolino.jl) implements the exact sequential rule from the older [conditioning study](../s1-marcolino-conditioning-comparison/README.md), using current LQR without gain redesign or phase compensation. [test_marcolino.jl](test_marcolino.jl) reproduces its saved 1x/2x/3x MATLAB cycle times and both anchor/reference errors. [comparison_timing.jl](comparison_timing.jl) performs exact partial propagation to sample every policy at the same nominal clock times j*T.

Two scores are deliberately separate. The original J100 is sampled at each policy's actual cycle starts, so Marcolino's anchor score covers different physical times and is not a common-clock tracking cost. The added clocked error sum compares tracking alone on the identical 101-point nominal grid through 28.6 ms; it charges no input effort and is not J100 or physical energy. This sampling is not a continuous-time tracking bound.

Reference errors at Marcolino's actual cycle boundaries can differ from errors on the common grid, even after its period returns to nominal. Earlier extensions are not canceled. The report shows both, along with actual elapsed threshold times, terminal extensions and explicit missing threshold crossings. Marcolino has no scalar beta and no applicable common-P certificate; it is excluded from certified-strategy selection.

The existing Common-P comparison was generated by historical Python synthesis. It remains a frozen baseline, not a claim that Julia's nonunique pure-feasibility solve returns the same gain. Saved MPC-5 is imported only on the three matching historical cases. No new MPC solves or cross-language matched timing study is performed.

## Limits

For the seven fixed-period methods, a positive common-P endpoint check certifies the conditioned linearized matrix family for arbitrary factors in [0,1]. This check does not apply to strategy-marcolino's variable-period conditioning. These are floating-point checks, not interval proofs. Exact nonlinear simulations do not establish global stability or a nonlinear region of attraction. The full-feedback cost bound in strategy-2 is not a bound on conditioned nonlinear cost.

The historical 2x/3x starts have negative current. New cases start with positive physical states, but no hardware operating envelope or physical-state constraints are assumed. Saved state minima use cycle-start samples, not continuous-time extrema. No uncertainty, quantization, delay, experiments or embedded deadline measurements are included.

Search bounds and evaluation caps are explicit. A numerical rejection is not proof of instability or infeasibility. An unchanged seed is retained and labeled rather than presented as an improvement. The report discloses withheld regressions and does not claim a globally optimal or generally superior controller.
