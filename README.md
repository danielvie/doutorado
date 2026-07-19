# Doutorado

Repository for thesis writing, simulations, embedded experiments, presentations, publications, and supporting research material.

## Quick links

- Current thesis PDF: [`tese.pdf`](tese.pdf)
- Repository map: [`docs/REPO_MAP.md`](docs/REPO_MAP.md)
- Domain glossary: [`CONTEXT.md`](CONTEXT.md)
- Archived old root README notes: [`docs/README_NOTES_ARCHIVE.md`](docs/README_NOTES_ARCHIVE.md)
- Current working TODO/history: [`TODO`](TODO)

## Where to go

| Need | Go to |
| --- | --- |
| Thesis and paper LaTeX sources | [`LATEX/`](LATEX/) |
| Plans, TODOs, and qualification material | [`research-material/planning/`](research-material/planning/) |
| Reviewer comments | [`research-material/review-feedback/`](research-material/review-feedback/) |
| Authored analysis and meeting notes | [`research-material/working-notes/`](research-material/working-notes/) |
| Shared diagrams and writing assets | [`assets/`](assets/) |
| Current MATLAB simulations/control code | [`simulations/matlab-sim-sim/`](simulations/matlab-sim-sim/) |
| Older MATLAB simulations | [`simulations/legacy/`](simulations/legacy/) |
| Projection/feasibility-region MATLAB work | [`simulations/projection/`](simulations/projection/) |
| ESP32 firmware, hardware docs, and web UI | [`embedded/`](embedded/) |
| External papers, books, theses, and course material | [`research-material/literature/`](research-material/literature/) |
| Presentations and slides | [`presentations/`](presentations/) |
| External/vendor material | [`vendor/`](vendor/) |

## Common commands

This repository uses [`Taskfile.yml`](Taskfile.yml):

```sh
task --list
```

Important tasks:

- `task run` opens generated overview documentation.
- `task test` validates generated overview documentation.
- `task clean` removes generated overview documentation.
- `task update-tese` copies `LATEX/thesis/build/tese.pdf` to the repository root.

## Navigation conventions

- Start from this README, then use [`docs/REPO_MAP.md`](docs/REPO_MAP.md) for locations and [`CONTEXT.md`](CONTEXT.md) for terminology.
- Prefer area-specific READMEs/docs when they exist.
- Treat `vendor/` and `simulations/backup/` as backup, vendored, or auxiliary material unless a task explicitly points there.
- Prefer `simulations/matlab-sim-sim/` over `simulations/legacy/` for current simulation work.
- Prefer `embedded/esp32_idf/` for current ESP32 firmware work.
- Avoid adding new loose files at the repository root; put new material in the closest project area.
- Keep document navigation folders at most three levels deep. Self-contained source/build trees are exempt when flattening would break them.
