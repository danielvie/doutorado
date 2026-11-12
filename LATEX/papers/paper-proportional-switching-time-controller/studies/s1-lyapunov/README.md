# Latest Lyapunov analysis

**Start with [analysis.jl](analysis.jl).** This is the current Julia common-P SDP for the paper's aggressive controller.

From the paper root:

```sh
task lyapunov
```

Or from this directory:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. analysis.jl
```

The saved Python certificate is included, so the Julia solve can run without MATLAB or Python. `Project.toml` and `Manifest.toml` preserve the Julia environment. The tested runtime is Julia 1.12.7 with Convex.jl 0.16.7 and Clarabel 0.11.1.

## What the Julia file does

1. Load the normalized endpoint matrices `A0` and `A1` from [results/certificate.json](results/certificate.json).
2. Maximize the shared decrease margin `eta` subject to `trace(P) = 3`, positive definiteness, and the two endpoint Lyapunov inequalities.
3. Recompute eigenvalues and verify positive definiteness, endpoint decrease, and trace normalization.
4. Compare the objective with Python, without requiring identical optimizer entries.
5. Write [results/lyapunov_analysis_julia_certificate.json](results/lyapunov_analysis_julia_certificate.json).

Julia does not independently reconstruct the converter. It isolates the optimization formulation by solving with the matrices produced by Python's physical reconstruction.

The reproduced Julia result is `OPTIMAL`, with `eta = 0.000291190431493879`, minimum endpoint decrease `0.0002911904317037103`, and relative objective difference from Python about `3.17e-9`.

## Evidence and supporting implementations

| File | Role |
| --- | --- |
| [analysis.jl](analysis.jl) | Main Julia analysis and certificate checks |
| [python/build_tutorial.py](python/build_tutorial.py) | Reconstruct circuit modes, exact cycle model, physical projection, timing map, and aggressive LQR; validate against paper data |
| [python/optimization.py](python/optimization.py) | Standalone CVXPY/CLARABEL SDP |
| [python/requirements.txt](python/requirements.txt) | Recorded Python package versions |
| [matlab/compare_certificate.m](matlab/compare_certificate.m) | Independent physical reconstruction and CVX/SDPT3 solve |
| [results/certificate.json](results/certificate.json) | Full-precision Python model, certificate, validation, and laboratory data |
| [results/lyapunov_analysis_matlab_comparison.json](results/lyapunov_analysis_matlab_comparison.json) | Saved MATLAB comparison |
| [lyapunov_analysis_solver_comparison.md](lyapunov_analysis_solver_comparison.md) | Solver-comparison notes |
| [tutorial/index.html](tutorial/index.html) | Generated offline tutorial with five interactive laboratories |
| [tutorial/template.html](tutorial/template.html) | Editable tutorial source; generated index must not be edited directly |
| [tutorial/mado.html](tutorial/mado.html) | Preserved alternate presentation, not the template builder's output |

The tutorial covers circuit equations, augmented propagation, dwell derivatives, physical-error projection, LQR, the SDP, endpoint proof, and nonlinear limitations. It uses native MathML and embedded SVG, with no network dependencies.

The Python builder checks `Phi`, `Gamma`, and the aggressive physical gain against `../../results/paper_results.mat`. These numerical field names denote the physical matrices called `Phi_x` and `Gamma_tau` in the manuscript, not its unadorned augmented matrices `Phi` and `Gamma`. It constructs them from physical parameters first; the MAT file is a validation reference, not the source of its model. Older `gain_matrix.csv` data are archived and must not be substituted for the current aggressive gain.

## Reproduce or compare

```sh
# Commands from the paper root
task lyapunov:python       # Reconstruct, solve, check, regenerate tutorial
task lyapunov             # Solve in Julia using the saved Python matrices
task lyapunov:reproduce   # Python then Julia, sequentially
task lyapunov:matlab      # Optional independent MATLAB CVX/SDPT3 check
```

Python uses `uv` and the recorded requirements. MATLAB needs Control System Toolbox and CVX with SDPT3 on its path. The MATLAB task writes its own comparison JSON and does not overwrite the Python or Julia certificates.

## Adopted article result and scope

[The current article](../../latex/main.tex) adopts the common-P endpoint-to-interval proof as its main stability result. [GOAL.md](../../GOAL.md) records the scope. The invariant raw-action analysis is supporting appendix material. The article separates the linearized guarantee from nonlinear simulation evidence without presenting a separate local nonlinear stability result.

The article states the proof in physical error coordinates, with `A0 = Phi_x`, `A1 = Acl`, and `V(e) = e'Pe`. It applies the Schur complement to the negative-definite block matrix `[-P, A(beta)'; A(beta), -inv(P)]` and uses its affine dependence on `beta` for a fixed `P`. The proof concludes with the common quadratic Lyapunov criterion, without an explicit rate calculation.

The Julia script still solves the inverse-free endpoint inequalities `P-Ai'*P*Ai >= eta*I` in normalized coordinates. In the application text, hatted endpoint matrices and `P_n` denote these normalized quantities. The physical-coordinate certificate is `P = inv(Sx)' * P_n * inv(Sx)`. This congruence preserves positive definiteness and endpoint decrease, but the numerical trace and margins are coordinate-dependent. Saved JSON fields `A0`, `A1`, and `P` retain their normalized meaning; neither the solver formulation nor the reported numerical values changed.

The common-P argument concerns the conditioned **linearized** matrix family for all `beta` in `[0, 1]`. The solver checks are floating-point checks, not interval-arithmetic certification. The large-error exact nonlinear trajectories remain simulation evidence; the common-P result does not prove global nonlinear stability.

`task results` first reruns Julia, then the MATLAB article pipeline. [`paper.export_lyapunov`](../../scripts/+paper/export_lyapunov.m) compares the saved study endpoints against the article's independently reconstructed model and aggressive gain. It recomputes the inequalities on that model, rejects mismatches or nonpositive margins, and writes `results/lyapunov_certificate.json` and `latex/lyapunov_metrics.tex` at the paper root. The full-precision certificate controls all reported values; the displayed rounded matrix is checked separately.

The study still owns model reconstruction, the SDP implementation, and cross-checks. The article owns its publication exports. If model or gain settings change, reconstruct and solve the study again before refreshing article evidence. Do not copy rounded tutorial values into the manuscript.

Earlier teaching work is indexed in [../README.md](../README.md); it is not the entry point for this analysis.
