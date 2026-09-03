# Patino, Riedinger, and Ruiz (2010)

Status: descriptive source summary
BibTeX key: `patino2010`
Source record: `references.bib`; local literature PDF recorded in `research/novelty-review.md`
Read when: studying the converter benchmark or mode-dependent switching sensitivity

## Bibliographic identity

D. Patino, P. Riedinger, and F. Ruiz, “A Predictive Control Approach for DC-DC Power Converters and Cyclic Switched Systems,” 2010 IEEE International Conference on Industrial Technology, pages 1259–1264.

## Problem

The paper studies predictive control for DC-DC power converters and cyclic switched systems whose behavior depends on the active switching mode. Switching instants are treated as control variables within a repeating cycle.

## System and setting

The setting is a cyclic switched system with a fixed final cycle time and mode-dependent dynamics. The paper includes a three-cell multilevel DC-DC converter example. The benchmark data used by the present project come from this example, including the physical mode sequence, rounded switching boundaries, converter parameters, and reported cycle-start state.

## Approach

The paper derives analytical sensitivities of states at later switching events with respect to earlier switching instants. The sensitivity contains the difference between the vector fields before and after the displaced switching instant, propagated through the subsequent modes. The sensitivities are used inside a predictive optimization procedure.

## Main contribution

The paper provides a mode-dependent switching-instant sensitivity formulation for cyclic switched systems and applies it to predictive converter control.

## Evidence

The paper reports a converter-oriented numerical application and cyclic switched-system control calculations.

## Assumptions and limitations

The control setting uses a cyclic schedule and timing variables. The sensitivity is a local differential object. The project literature review records no stability proof for the predictive controller in this source.

## Concepts useful for later reading

- cyclic switched systems;
- switching-instant sensitivity;
- vector-field jump at a switching event;
- predictive control using timing variables;
- fixed final cycle time.

## Source pointers

See `research/novelty-review.md`, `research/marcolino-propagation-comparison.md`, and `latex/article.tex` for the way the present manuscript describes this source. The local PDF is under the repository's `research-material/literature/` archive.
