# Marcolino, Galvão, and Kienitz (2021)

Status: descriptive source summary
BibTeX key: `marcolino2021`
Source record: `references.bib`; local PDF recorded in `research/novelty-review.md`
Read when: studying the closest fixed-period timing-control predecessor

## Bibliographic identity

M. H. Marcolino, R. K. H. Galvão, and K. H. Kienitz, “Predictive Control of Linear Systems with Switched Actuators Subject to Dwell-Time Constraints,” *Journal of Control, Automation and Electrical Systems*, 32(1), 1–17, 2021. DOI: `10.1007/s40313-020-00667-9`.

## Problem

The paper addresses control of an LTI plant driven by switched actuator levels when the actuator schedule must obey minimum dwell-time constraints.

## System and setting

The plant has one constant state matrix and piecewise-constant actuator inputs. A fixed-period cycle is parameterized by its interior switching instants while the first and last cycle boundaries remain fixed.

## Approach

The paper derives a one-cycle prediction model in switching-time coordinates, writes dwell constraints as coupled linear inequalities, and formulates dwell-constrained predictive control. It also uses a discrete LQR law as a static timing-feedback comparison.

The standalone LQR comparison applies actuator-side sequential saturation. The project research notes record that this can move the final switching instant and that the reported example diverges.

## Main contribution

The paper combines fixed-period switching-time coordinates, a cycle-sampled model, dwell-constrained predictive control, and an LQR timing law for the switched-actuator class.

## Evidence

The paper reports numerical converter-oriented examples comparing predictive control and the static LQR timing law.

## Assumptions and limitations

The state matrix is common across actuator modes. The timing model and dwell inequalities are therefore narrower than a general mode-dependent switched-affine model. The constrained predictive controller and the static LQR comparison are separate parts of the study.

## Concepts useful for later reading

- fixed-period timing coordinates;
- interior switching-instant offsets;
- adjacent dwell inequalities;
- one-cycle prediction model;
- discrete LQR timing feedback;
- constrained predictive control.

## Source pointers

The project comparison is in `research/marcolino-propagation-comparison.md` and `research/novelty-review.md`. The manuscript discusses this source in the Introduction and the common-state-matrix specialization in Section 2.
