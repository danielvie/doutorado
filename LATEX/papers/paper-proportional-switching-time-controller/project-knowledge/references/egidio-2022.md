# Egidio, Deaecto, and Jungers (2022)

Status: descriptive source summary
BibTeX key: `egidio2022rank`
Source record: `latex/references.bib`; publication DOI: `10.1016/j.automatica.2022.110426`
Read when: studying state-dependent mode-selection control for switched-affine systems

## Bibliographic identity

L. N. Egidio, G. S. Deaecto, and R. M. Jungers, “Stabilization of Rank-Deficient Continuous-Time Switched Affine Systems,” *Automatica*, 143, 110426, 2022.

## Problem

The paper studies stabilization of continuous-time switched-affine systems when convex combinations of mode matrices are rank deficient.

## System and setting

The system is switched affine and the controller selects active modes as a function of the state. The control variable is the active subsystem rather than a timing-offset vector for a fixed schedule.

## Approach

The paper uses an LMI-based state-dependent switching function and derives global asymptotic and local exponential stability results under its stated conditions.

## Main contribution

The source provides a stabilization method for rank-deficient continuous-time switched-affine systems with state-dependent mode selection.

## Evidence

The paper includes application examples involving a DC motor and converter-related switching configurations.

## Assumptions and limitations

The mode-selection actuator changes which subsystem is active. This differs from preserving a prescribed mode order and shifting only interior switching instants.

## Concepts useful for later reading

- rank-deficient switched-affine systems;
- state-dependent mode selection;
- LMI-based switching laws;
- global asymptotic stability;
- local exponential stability.

## Source pointers

The article cites this source in the Introduction to distinguish state-dependent mode selection from its fixed-sequence timing actuator.
