# Repository reorganization plan

This document records the implemented target structure for making the repository easier to navigate. It also keeps the old-to-new folder mapping for future reference.

## Principle

Organize by workstream, not by file type.

The main workstreams are:

1. Manuscripts
2. Simulations and analysis
3. Embedded experiments
4. References
5. Presentations
6. External/vendor material
7. Sandbox experiments

## Current top-level structure

```text
doutorado.git/
├── README.md
├── CONTEXT.md
├── Taskfile.yml
├── tese.pdf
│
├── manuscripts/
├── simulations/
├── embedded/
├── references/
├── presentations/
├── vendor/
├── sandbox/
└── docs/
```

## Folder mapping

### Manuscripts

Use `manuscripts/` for everything directly related to producing, planning, reviewing, and publishing written academic work.

```text
manuscripts/
├── thesis/
├── papers/
├── planning/
├── feedback/
├── notes/
└── assets/
```

| Current path | Proposed path | Notes |
| --- | --- | --- |
| `LATEX/Tese/` | `manuscripts/thesis/latex/` | Main thesis source. |
| `LATEX/Artigo/` | `manuscripts/papers/artigo/` | Article source. |
| `publication/` | `manuscripts/papers/` | Publication drafts. |
| `plan/` | `manuscripts/planning/qualification/` | Qualification and planning material. |
| `comentarios/` | `manuscripts/feedback/` | Review/comments material. |
| root `TODO` | `manuscripts/planning/TODO.md` or keep at root temporarily | Move only after deciding it is mostly writing/planning work. |
| `docs/README_NOTES_ARCHIVE.md` | `manuscripts/notes/README_NOTES_ARCHIVE.md` | Historical writing notes, if desired. |
| root `drawing.svg` | `manuscripts/assets/` | Only if it belongs to thesis/paper writing. |

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
| `documentos/` non-reference files | Decide case by case | Some belong in `manuscripts/`, some in `references/`. |

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
