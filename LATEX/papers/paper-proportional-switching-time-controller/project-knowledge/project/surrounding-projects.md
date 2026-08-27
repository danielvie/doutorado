# Surrounding projects

Status: descriptive relationship map
Source of truth: `AGENTS.md`, paper scripts, sibling project files, thesis files, and linearization notes
Read when: tracing provenance or dependencies beyond the paper directory

## MATLAB simulation project

Location: `simulations/matlab-sim/`

The paper scripts use this project as the plant-model and dynamics source. The relevant paper path instantiates the `PATINO_2` simulation and uses its configured matrices and affine vectors. The simulation project contains model data, exact switching propagation, cycle simulation, and cycle linearization utilities.

The paper's own scripts then apply a paper-specific schedule, anchor, normalization, controller design, conditioning operation, and output-writing layer.

## Thesis

Location: `LATEX/thesis/`

The thesis contains broader development around switched-affine systems, trajectory construction, the Patiño converter application, and linearization. It provides research provenance and explanatory context for material used by the article, but the current article does not include thesis chapter files directly.

The thesis may contain earlier formulations or terminology. When it conflicts with the current article, use the current article and `CONTEXT.md` for the paper's present vocabulary.

## Linearization notes

Location: `research-material/working-notes/linearization/linearization_v2_augmented.tex`

These notes document the augmented-state linearization procedure in more detail. They are background for understanding the derivation in `article.tex`, not an active article input.

## Embedded ESP project

Location: `embedded/esp32_idf/`

The embedded project contains ESP32 control and signal-processing code, implementation documents, and hardware-oriented context. The current paper's numerical pipeline does not call this code and the article does not report a hardware experiment.

The existence of embedded code should therefore not be treated as evidence that the paper's controller has been validated on hardware.

## Provenance versus evidence

The thesis, research notes, and embedded project can explain where ideas or implementation concerns came from. They do not automatically provide evidence for claims in the article. A claim still needs to be checked against the manuscript, numerical outputs, source literature, or an explicit experiment.
