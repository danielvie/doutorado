# Handoff: reference locations for the PATINO_2 Lyapunov certificate

## Next-session focus

Locate and use the reference artifacts for the paper's `PATINO_2` Lyapunov/CVX formulation.

## Current state

- Created `studies/cvx_paper.m`.
- The file loads `results/paper_results.mat`, reconstructs the normalized nominal cycle matrix `Phi` and aggressive raw closed-loop matrix `Acl`, then solves the common quadratic Lyapunov SDP with CVX.
- The SDP maximizes `t` subject to `P >= 1e-8 I`, `trace(P) = 1`, and strict decrease constraints for both endpoints.
- MATLAB validation succeeded with CVX status `Solved`, positive-definite `P`, positive endpoint margins, and contraction bound `0.999938941`.
- The file uses generated paper results rather than instantiating `Simulation(Enums.SimName.PATINO_2)` directly.

## Reference locations

Paths are relative to the paper project root unless noted otherwise:

- `project-knowledge/references/patino-2010.md` — source summary for Patiño, Riedinger, and Ruiz (2010), including the three-cell converter benchmark provenance.
- `references.bib` — bibliography entry with key `patino2010`.
- `article.tex` — current manuscript formulation and case-study discussion.
- `scripts/generate_results.m` — numerical source of truth; instantiates `PATINO_2`, builds the paper schedule and linearization, computes the controller, and solves the original YALMIP certificate.
- `results/paper_results.mat` — generated matrices, controller gains, and stored common-Lyapunov certificate consumed by `studies/cvx_paper.m`.
- `studies/lyapunov/paper_certificate.m` — existing YALMIP-based verification of the same paper certificate.
- `studies/lyapunov/parts/50-paper.html` — study exposition of the paper's common-`P` SDP and contraction argument.
- `simulations/matlab-sim/+Data/patino_2.m` — sibling simulation project's `PATINO_2` plant configuration.
- `simulations/matlab-sim/+Enums/SimName.m` — enum containing `PATINO_2`.

## Suggested skills

- `research` — verify the published Patiño reference against primary-source material.
- `how` — trace how the generated `PATINO_2` data reaches the CVX certificate.
- `shared-understanding` — clarify whether the CVX script should keep using cached paper results or rebuild the model directly.
