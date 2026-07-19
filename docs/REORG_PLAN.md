# Repository reorganization plan

This document records the implemented target structure for making the repository easier to navigate. It also keeps the old-to-new folder mapping for future reference.

## Principle

Keep LaTeX source at the repository root under `LATEX/`. Consolidate supporting research artifacts under `research-material/`, using purpose-specific folders no more than three levels deep. Reserve `docs/` for repository documentation.

The main work areas are:

1. LaTeX source
2. Supporting research material
3. Shared assets
4. Simulations and analysis
5. Embedded experiments
6. Presentations
7. External/vendor material
8. Sandbox experiments

## Current top-level structure

```text
doutorado.git/
├── README.md
├── CONTEXT.md
├── Taskfile.yml
├── tese.pdf
│
├── LATEX/
├── research-material/
├── assets/
├── simulations/
├── embedded/
├── presentations/
├── vendor/
├── sandbox/
└── docs/
```

## Folder mapping

### Writing, research material, and shared assets

Keep authored LaTeX source in root-level `LATEX/`. Keep plans, reviewer feedback, authored analysis, and external literature together under `research-material/`. Put reusable diagrams and images in `assets/`; reserve `docs/` for repository documentation.

```text
LATEX/
├── thesis/
└── papers/
    ├── flying-capacitor-three-cell-converter/
    ├── proportional-switching-time-controller/
    └── publication/

research-material/
├── literature/
├── planning/
│   └── qualification/
├── review-feedback/
│   └── comments/
└── working-notes/
    ├── linearization/
    ├── meetings/
    └── optimization/

assets/
```

| Previous path | Current path | Notes |
| --- | --- | --- |
| `manuscripts/thesis/latex/` | `LATEX/thesis/` | Main thesis source. |
| `manuscripts/papers/artigo/` | `LATEX/papers/flying-capacitor-three-cell-converter/` | Hardware article source. |
| `manuscripts/papers/proportional-switching-time-controller/` | `LATEX/papers/proportional-switching-time-controller/` | Proportional controller article source. |
| `manuscripts/papers/publication/` | `LATEX/papers/publication/` | Publication LaTeX drafts and templates. |
| `manuscripts/planning/` | `research-material/planning/` | Qualification and planning material. |
| `manuscripts/feedback/` | `research-material/review-feedback/` | Review/comments material. |
| `manuscripts/notes/` | `research-material/working-notes/` | Authored analysis and meeting material. |
| `manuscripts/assets/` | `assets/` | Shared diagrams and images. |

### Simulations and analysis

```text
simulations/
├── current/
├── legacy/
├── projection/
└── backup/
```

| Current path | Proposed path | Notes |
| --- | --- | --- |
| `simu2/` | `simulations/matlab-sim-sim/` | Preferred active simulation codebase. |
| `simulacoes/` | `simulations/legacy/` | Older MATLAB simulation code. |
| `projecao/` | `simulations/projection/` | Projection/feasibility-region work. |
| `z_backup_simulacoes/` | `simulations/backup/` | Backup material. |

### Embedded experiments

Keep `embedded/` as the top-level workstream.

Possible internal cleanup:

```text
embedded/
├── esp32_idf/
├── esp32_legacy/
├── hardware-docs/
└── lab-notes/
```

| Current path | Proposed path | Notes |
| --- | --- | --- |
| `embedded/esp32_idf/` | `embedded/esp32_idf/` | Current ESP32-IDF firmware work. |
| `embedded/esp32/` | `embedded/esp32_legacy/` | Rename only if confirmed legacy. |
| `embedded/doc/` | `embedded/hardware-docs/` | Datasheets, pinouts, wiring docs. |

### Literature and tutorial experiments

```text
research-material/literature/
├── articles-control/
├── articles-converters/
├── articles-dwell-time/
├── articles-switched-systems/
├── books/
├── course-material/
├── prior-work/
└── theses/
```

| Previous path | Current path | Notes |
| --- | --- | --- |
| `references/papers/artigos/` | `research-material/literature/articles-*/` | External articles grouped by topic. |
| `references/papers/livros/` | `research-material/literature/books/` | External books. |
| `references/papers/teses/` | `research-material/literature/theses/` | External theses. |
| `references/papers/aulas/` | `research-material/literature/course-material/` | Course handouts. |
| `references/papers/trabalhos_anteriores/` | `research-material/literature/prior-work/` | Prior project work. |
| `references/tutorials/matlab_coder/` | `sandbox/matlab-coder/` | Self-contained code experiments; internal build layout retained. |

### Presentations

```text
presentations/
├── slides/
├── manim/
└── revealjs/
```

| Current path | Proposed path |
| --- | --- |
| `apresentacao/` | `presentations/` |

### Vendor and auxiliary material

```text
vendor/
├── dependencies/
├── kawa/
└── qpoases/
```

| Current path | Proposed path | Notes |
| --- | --- | --- |
| `z_dependencies/` | `vendor/dependencies/` | External dependencies. |
| `z_kawa/` | `vendor/kawa/` | Kawa-related material. |
| `z_qpoases/` | `vendor/qpoases/` | qpOASES-related material. |

### Administrative/support docs

| Current path | Proposed path |
| --- | --- |
| `VPN ITA/` | `docs/setup/vpn-ita/` |

## Migration notes

The main folder moves have been applied. If a moved workstream has its own build scripts, check those scripts before running old commands from memory.

High-risk path-sensitive areas after the move:

- LaTeX source folders and figures.
- MATLAB package folders using `+package` names.
- ESP32 firmware build directories.
- Generated docs or presentation build output.
