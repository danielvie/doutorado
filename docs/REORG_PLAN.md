# Repository reorganization plan

This document records the implemented target structure for making the repository easier to navigate. It also keeps the old-to-new folder mapping for future reference.

## Principle

Keep LaTeX source, research notes, and shared assets separate so each has an obvious home.

The main work areas are:

1. LaTeX source
2. Research notes
3. Shared assets
4. Simulations and analysis
5. Embedded experiments
6. References
7. Presentations
8. External/vendor material
9. Sandbox experiments

## Current top-level structure

```text
doutorado.git/
├── README.md
├── CONTEXT.md
├── Taskfile.yml
├── tese.pdf
│
├── LATEX/
├── research-notes/
├── assets/
├── simulations/
├── embedded/
├── references/
├── presentations/
├── vendor/
├── sandbox/
└── docs/
```

## Folder mapping

### LaTeX, research notes, and shared assets

Keep authored LaTeX source in `LATEX/`. Keep planning, feedback, and supporting written material in `research-notes/`. Put reusable diagrams and images in `assets/`.

```text
LATEX/
├── thesis/
└── papers/
    ├── flying-capacitor-three-cell-converter/
    ├── proportional-switching-time-controller/
    └── publication/

research-notes/
├── planning/
├── feedback/
└── notes/

assets/
```

| Previous path | Current path | Notes |
| --- | --- | --- |
| `manuscripts/thesis/latex/` | `LATEX/thesis/` | Main thesis source. |
| `manuscripts/papers/artigo/` | `LATEX/papers/flying-capacitor-three-cell-converter/` | Hardware article source. |
| `manuscripts/papers/proportional-switching-time-controller/` | `LATEX/papers/proportional-switching-time-controller/` | Proportional controller article source. |
| `manuscripts/papers/publication/` | `LATEX/papers/publication/` | Publication LaTeX drafts and templates. |
| `manuscripts/planning/` | `research-notes/planning/` | Qualification and planning material. |
| `manuscripts/feedback/` | `research-notes/feedback/` | Review/comments material. |
| `manuscripts/notes/` | `research-notes/notes/` | Supporting notes and documents. |
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

### References

```text
references/
├── papers/
├── books/
├── courses/
├── tutorials/
└── misc/
```

| Current path | Proposed path | Notes |
| --- | --- | --- |
| `documentos/referencias/` | `references/` | Academic and technical references. |
| `z_tutoriais/` | `references/tutorials/` | Tutorial material. |
| `documentos/` non-reference files | Decide case by case | Some belong in `research-notes/`, some in `references/`. |

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
