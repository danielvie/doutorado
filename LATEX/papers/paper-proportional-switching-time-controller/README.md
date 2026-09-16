# Dwell-conditioned switching-time feedback

This workspace contains the paper, its reproducible numerical evidence, and supporting studies. The common-P Lyapunov proof is the main stability result; invariant raw-action feasibility is supporting appendix material.

## Start here

- **Latest Lyapunov analysis:** [studies/lyapunov/analysis.jl](studies/lyapunov/analysis.jl). Run `task lyapunov` from this directory.
- [Lyapunov study guide](studies/lyapunov/README.md) explains the Python model reconstruction, Julia solve, MATLAB comparison, and limits of the certificate.
- [Article numerical pipeline](scripts/README.md) explains the six stages behind `scripts/generate_results.m`.
- [Manuscript](latex/main.tex), [current PDF](article.pdf), and [current section map](project-knowledge/project/manuscript-description.md). The older [teaching guide](docs/study-guide.md) is background reading.
- [Project knowledge](project-knowledge/README.md) provides the wider research map.

## Commands

Run these from the paper directory. `task --list` lists paper and study tasks together.

| Command | What it does |
| --- | --- |
| `task build` | Compile existing manuscript inputs without MATLAB |
| `task results` | Solve the Julia certificate, then run the article numerical pipeline |
| `task figures` | Compatibility alias for `task results` |
| `task replot` | Redraw main-text numerical figures from saved data, without simulation or solvers |
| `task test` | Check the conditioner, linearization, and controller without writing outputs |
| `task test-regeneration` | Regenerate into a temporary directory and compare with stored evidence |
| `task invariant-region` | Regenerate region figures and vertices from `results/paper_results.mat` |
| `task lyapunov` | Run the latest Julia SDP against the saved Python certificate |
| `task lyapunov:reproduce` | Reconstruct Python evidence and tutorial, then run Julia |
| `task lyapunov:matlab` | Independent MATLAB CVX/SDPT3 reconstruction and solve |
| `task trajectory-comparison` | Regenerate the separate continuous-time comparison study |
| `task beta-timing` | Benchmark host MATLAB/C++ beta computation and record p95 timings |
| `task check-links` | Check maintained local Markdown and HTML links |
| `task verify` | Run unit checks, link checks, article results, and LaTeX build |
| `task clean` | Remove LaTeX compilation intermediates |

`task results` and `task verify` rerun the Julia certificate before article generation. The article pipeline checks the certificate against its MATLAB model and exports the reported values. `task build` uses the saved publication inputs without MATLAB or Julia.

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
- LaTeX requires `latexmk` and a TeX installation. Project-local compile inputs remain under `latex/`.
- The Lyapunov study records its Julia environment and Python versions alongside its code. MATLAB CVX is needed only for its optional MATLAB comparison.
- Shell tasks use Go Task and POSIX commands, as in the existing Windows/Git Bash workflow. Link checks require Python 3.

Track publication CSV/MAT data, LaTeX metrics, and figures so the article builds without running MATLAB. Do not manually edit generated numbers. `results/provenance.json` records the latest run's environment and source revision and is ignored because it includes machine-specific paths. Caches and compilation intermediates are ignored too.

Earlier output locations are recorded in [archive/README.md](archive/README.md). The current rewrite leaves the Introduction unchanged for the author to revise later; its old contribution summary and roadmap do not yet describe the new stability section.
