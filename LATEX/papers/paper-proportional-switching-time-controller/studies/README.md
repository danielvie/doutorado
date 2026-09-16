# Studies

**Current entry point:** [lyapunov/analysis.jl](lyapunov/analysis.jl), run with `task lyapunov` from the paper root. See the [study guide](lyapunov/README.md) for its adopted article scope and numerical limitations.

| Study | Status and entry point |
| --- | --- |
| [lyapunov](lyapunov/README.md) | Adopted common-P analysis, Julia solve with Python and MATLAB cross-checks |
| [signal-conditioning-stability](signal-conditioning-stability/tutorial.md) | Supporting endpoint and interval derivations; MATLAB scripts for beta 0, 1, and the interval |
| [trajectory-comparison](trajectory-comparison/README.md) | Separate continuous-time and long-horizon comparison, `task trajectory-comparison` |
| [beta-timing](beta-timing/README.md) | Host MATLAB/C++ conditioner timing, individual-call p95 and batched cross-checks, `task beta-timing`; not ESP32 timing |
| [lyapunov-background](lyapunov-background/README.md) | Earlier general convex-optimization tutorial; not the current certificate entry point |
| [lyapunov_focus](lyapunov_focus/computing-v-with-cvx.html) | Focused introductory oscillator/CVX example |
| [lyapunot_focus_fable](lyapunot_focus_fable/README.md) | Earlier two-example tutorial and laboratories; existing name retained to preserve its bundle |
| [matlab-test](matlab-test/cvx_example_explanation.html) | CVX installation examples, not article validation |

`cvx_paper.m` is an earlier MATLAB-only certificate exercise. The latest independent MATLAB comparison is `lyapunov/matlab/compare_certificate.m`.

Do not merge these studies solely because they all use Lyapunov functions. They ask different questions and some deliberately reconstruct the same model independently. Each maintained study should state its question, inputs, command, outputs, and scientific limitations.

The old `studies/Taskfile.yml` remains scoped to the CVX installation example. The paper-root Taskfile is the command index for current work. `handoff/` contains historical study sessions, not current instructions.
