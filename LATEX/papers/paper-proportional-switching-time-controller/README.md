# Dwell-conditioned switching-time feedback

This workspace contains the paper, its reproducible numerical evidence, and supporting studies. The common-P Lyapunov proof is the main stability result; invariant raw-action feasibility is supporting appendix material.

## Start here

- [Common-P gain synthesis](studies/s2-kawa-synthesis/README.md) is the source of the manuscript's gain, certificate, and controller comparison.
- [Fixed-gain Lyapunov analysis](studies/s1-lyapunov/README.md) and the [baseline numerical pipeline](scripts/README.md) document the earlier LQR design and supporting evidence.
- [Manuscript](latex/main.tex), [current PDF](article.pdf), and [current section map](project-knowledge/project/manuscript-description.md). The older [teaching guide](docs/study-guide.md) is background reading.
- [Project knowledge](project-knowledge/README.md) provides the wider research map.

## Commands

Run these from the paper directory. `task --list` lists paper and study tasks together.

| Command | What it does |
| --- | --- |
| `task build` | Compile existing manuscript inputs without MATLAB |
| `task results` | Export manuscript tables and certificate values from the saved Common-P study |
| `task figures` | Alias for `task replot` |
| `task replot` | Redraw Common-P comparison figures and export values from saved data |
| `task baseline-results` | Run the legacy LQR numerical pipeline for supporting evidence |
| `task test` | Check the conditioner, linearization, and controller without writing outputs |
| `task test-regeneration` | Regenerate into a temporary directory and compare with stored evidence |
| `task invariant-region` | Regenerate region figures and vertices from `results/paper_results.mat` |
| `task lyapunov` | Run the latest Julia SDP against the saved Python certificate |
| `task lyapunov:reproduce` | Reconstruct Python evidence and tutorial, then run Julia |
| `task lyapunov:matlab` | Independent MATLAB CVX/SDPT3 reconstruction and solve |
| `task trajectory-comparison` | Regenerate the separate continuous-time comparison study |
| `task conditioning-comparison:run` | Compare Daniel, relaxed-terminal Daniel, and Marcolino at 1x/2x/3x and build the study report |
| `task mpc-comparison:run` | Compare fixed-period feedback with five-cycle MPC at 1x/2x/3x and build the study documents |
| `task kawa-synthesis:test` | Verify the saved gain, certificate, exact trajectories, dwells, costs, and timing samples |
| `task beta-timing` | Benchmark host MATLAB/C++ beta computation and record p95 timings |
| `task check-introduction` | Verify the protected Introduction is unchanged |
| `task check-links` | Check maintained local Markdown and HTML links |
| `task verify` | Run unit checks, link checks, article results, and LaTeX build |
| `task clean` | Remove LaTeX compilation intermediates |

`task build` checks the manuscript export against the saved Common-P results and compiles the PDF without MATLAB or Julia. The published comparison uses the saved CVXPY/Clarabel gain and its matching MATLAB trajectories and timings. The Julia port was checked separately and can return a different gain. Do not mix a new gain with the original comparison.

## Folder ownership

| Folder | Contents |
| --- | --- |
| `latex/` | Manuscript, bibliography, publisher files, generated macros, and article figures |
| `scripts/` | Current article pipeline and project checks |
| `results/` | Current article data and auxiliary figures, with an [output inventory](results/README.md) |
| `studies/` | Named investigations, indexed in [studies/README.md](studies/README.md) |
| `docs/` | Explanations and teaching documents, indexed in [docs/README.md](docs/README.md) |
| `research/` | External articles and literature reviews |
| `project-knowledge/` | Descriptive navigation, concepts, and reference summaries |
| `reviews/` | Manuscript reviews, not manuscript source |
| `archive/` | Historical drafts, handoffs, and superseded numerical evidence |
| `templates/` | Original publisher distribution |
| `build/` | Ignored compilation output; `article.pdf` is the convenient root preview |

Keep [GOAL.md](GOAL.md) authoritative for scientific scope and [CONTEXT.md](CONTEXT.md) for terminology. Historical notes do not override either file or the manuscript.

## Dependencies and evidence policy

- Article numerics require MATLAB, Control System Toolbox, MPT3, and the sibling `simulations/matlab-sim/` project. Configure MPT3 on the MATLAB path before running the tasks.
- LaTeX requires `latexmk` and a TeX installation; the protected-Introduction check uses Python through `uv`. Project-local compile inputs remain under `latex/`.
- The Lyapunov study records its Julia environment and Python versions alongside its code. MATLAB CVX is needed only for its optional MATLAB comparison.
- Shell tasks use Go Task and POSIX commands, as in the existing Windows/Git Bash workflow. Link checks require Python 3.

Track publication CSV/MAT data, LaTeX metrics, and figures so the article builds without running MATLAB. Do not manually edit generated numbers. `results/provenance.json` records the latest run's environment and source revision and is ignored because it includes machine-specific paths. Caches and compilation intermediates are ignored too.

Earlier output locations are recorded in [archive/README.md](archive/README.md). The Introduction remains unchanged and is protected by `task check-introduction`. Conditioned LQR and MPC-5 are comparison baselines; the appendix retains the original LQR region example.
