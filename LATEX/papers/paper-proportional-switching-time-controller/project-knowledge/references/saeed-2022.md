# Saeed, Wang, and Fernando (2022)

Status: descriptive source summary
BibTeX key: `saeed2022laguerre`
Source record: `latex/references.bib`; publication DOI: `10.1109/TCST.2021.3069148`
Read when: studying reduced-dimension MPC for a converter

## Bibliographic identity

J. Saeed, L. Wang, and N. Fernando, “Model Predictive Control of Phase Shift Full-Bridge DC-DC Converter Using Laguerre Functions,” *IEEE Transactions on Control Systems Technology*, 30(2), 819–826, 2022.

## Problem

The paper addresses control of a phase-shift full-bridge DC-DC converter with constraints that must be handled within a short sampling interval.

## System and setting

The application is a phase-shift full-bridge converter. The control problem includes a nonlinear peak-current constraint.

## Approach

Laguerre functions parameterize the control sequence and reduce the number of MPC decision variables.

## Main contribution

The source demonstrates a reduced-variable MPC formulation for constrained converter control.

## Evidence

The paper reports results on a 60 W laboratory converter with a 40 microsecond sampling interval.

## Assumptions and limitations

The method remains predictive control with an optimization structure. Its converter, parameterization, and actuator differ from fixed-period switching-instant feedback.

## Concepts useful for later reading

- phase-shift full-bridge converter;
- Laguerre parameterization;
- reduced MPC decision dimension;
- peak-current constraint;
- short sampling interval.

## Source pointers

The article cites this source in the first Introduction paragraph as an example of reducing online predictive-control cost.
