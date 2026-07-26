# Doctorate Repository

This context defines the repository-level language for the doctorate's research artifacts. Scientific and experimental terms belong to the bounded contexts listed in `CONTEXT-MAP.md`.

## Language

**Doctorate Repository**:
The complete body of work for the doctorate, including manuscripts, simulations, embedded experiments, presentations, planning material, and research references.
_Avoid_: Project folder, workspace

**LaTeX Source**:
Source material for a thesis or article expressed as a LaTeX document.
_Avoid_: Manuscript when referring specifically to source files

**Technical Note**:
Authored analysis, derivation, or meeting material that supports the research without being a formal manuscript.
_Avoid_: Article, scratch file

**Shared Asset**:
A diagram, image, or other research artifact intended for reuse by multiple manuscripts or presentations.
_Avoid_: Attachment, local figure

**Thesis**:
The main doctoral dissertation and its supporting source material.
_Avoid_: Article, paper

**Article**:
A publication derived from the doctorate work and maintained separately from the thesis.
_Avoid_: Thesis, technical note

**Simulation**:
A computational experiment used to model, test, or evaluate a control strategy before or alongside a hardware experiment.
_Avoid_: Embedded experiment, numerical script

**MATLAB Simulation**:
A simulation performed in MATLAB for active control analysis and evaluation.
_Avoid_: MATLAB script, legacy simulation material

**Legacy Simulation Material**:
Older simulation work retained for reference, comparison, or recovery but not treated as the canonical simulation model.
_Avoid_: MATLAB simulation

**Embedded Experiment**:
A hardware-facing experiment involving firmware, measurement, calibration, signal generation, or lab validation.
_Avoid_: Simulation, firmware project

**Projection Work**:
Analysis of projection or feasibility-set computation for the control problem.
_Avoid_: Simulation, feasibility claim

**Research Literature**:
External academic or technical material used to support manuscript or experiment design.
_Avoid_: Technical note, review material

**Presentation Material**:
Slides, animations, or other artifacts used to communicate the doctorate work.
_Avoid_: Manuscript, shared asset

**Planning Material**:
Qualification, schedule, and project-planning material that guides the doctorate work.
_Avoid_: Technical note, review material

**Review Material**:
Reviewer comments and associated citation metadata for a manuscript.
_Avoid_: Research literature, planning material

**Archive Material**:
Historical or support material retained for reference but not treated as active work.
_Avoid_: Legacy simulation material when referring specifically to older simulations
