# Repository map

This repository is organized by workstream. Use this map as the first place to decide where to look.

For the migration rationale and old-to-new folder mapping, see [`REORG_PLAN.md`](REORG_PLAN.md).

## Main work areas

| Path | Purpose | Start here |
| --- | --- | --- |
| `LATEX/` | Thesis and paper LaTeX source. | `LATEX/thesis/`, `LATEX/papers/` |
| `research-material/` | Literature, planning, review feedback, and authored working notes. | `research-material/README.md` |
| `assets/` | Shared diagrams and writing assets. | `assets/` |
| `simulations/matlab-sim-sim/` | Current MATLAB simulation/control codebase. | `simulations/matlab-sim-sim/README.md`, `simulations/matlab-sim-sim/DOCS/GETTING_STARTED.md` |
| `simulations/legacy/` | Older MATLAB simulation package retained for reference. | `simulations/legacy/` |
| `simulations/projection/` | MATLAB projection/feasibility-region work. | `simulations/projection/docs/context_projection.md` |
| `simulations/backup/` | Simulation backup material. | Use only for recovery/history. |
| `embedded/` | Hardware/ESP32 work, datasheets, firmware, web UI, lab notes. | `embedded/README.md`, `embedded/esp32_idf/README.md` |
| `presentations/` | Presentation material and slide experiments. | `presentations/slides/README.md` |
| `vendor/` | Vendored/external dependencies and auxiliary external projects. | `vendor/dependencies/`, `vendor/qpoases/`, `vendor/kawa/` |
| `sandbox/` | Experiments and scratch work. | Treat as non-canonical unless a task points there. |
| `docs/` | Repository-level documentation, setup notes, and generated overview docs. | `docs/REORG_PLAN.md`, `docs/setup/` |

## Writing and research-material layout

| Path | Purpose |
| --- | --- |
| `LATEX/thesis/` | Main thesis LaTeX source. |
| `LATEX/papers/flying-capacitor-three-cell-converter/` | Hardware article LaTeX source. |
| `LATEX/papers/proportional-switching-time-controller/` | Proportional switching-time control article source and generated results. |
| `LATEX/papers/publication/` | Publication LaTeX drafts and templates. |
| `research-material/planning/` | TODOs, progress tracking, and qualification material. |
| `research-material/review-feedback/` | Reviewer comments and citation metadata. |
| `research-material/working-notes/` | Authored technical analysis and meeting material. |
| `research-material/literature/` | External sources grouped by type or topic. |
| `assets/` | Shared diagrams and writing assets. |

## Embedded layout

| Path | Purpose |
| --- | --- |
| `embedded/esp32_idf/` | Current ESP32-IDF firmware work. |
| `embedded/esp32_legacy/` | Older ESP32 material. |
| `embedded/hardware-docs/` | Datasheets, pinouts, wiring images, and hardware reference material. |

## Root files

| File | Purpose |
| --- | --- |
| `README.md` | Entry point and navigation index. |
| `CONTEXT.md` | Domain glossary. |
| `Taskfile.yml` | Common commands. Run `task --list`. |
| `tese.pdf` | Current thesis PDF copy. |

## Navigation rules

- Prefer area-specific `README.md` files and `docs/` folders when they exist.
- Prefer `simulations/matlab-sim-sim/` over `simulations/legacy/` for current simulation work.
- Prefer `embedded/esp32_idf/` for current ESP32 firmware work.
- Treat `vendor/`, `simulations/backup/`, and `sandbox/` as non-canonical unless a task explicitly points there.
- Keep new material in the closest workstream folder instead of adding new root-level files.
- Keep document navigation folders at most three levels deep; exempt self-contained source/build trees that require their internal structure.
