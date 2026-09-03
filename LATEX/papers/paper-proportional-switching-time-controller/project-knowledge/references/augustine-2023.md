# Augustine and Patil (2023)

Status: descriptive source summary
BibTeX key: `augustine2023mpc`
Source record: `latex/references.bib`; publication DOI: `10.1109/LCSYS.2022.3210368`
Read when: studying ways to reduce online switched-affine MPC cost

## Bibliographic identity

M. T. Augustine and D. U. Patil, “A Practically Stabilizing Model Predictive Control Scheme for Switched Affine Systems,” *IEEE Control Systems Letters*, 7, 625–630, 2023.

## Problem

The paper addresses the online computational burden of model predictive control for switched-affine systems while retaining a practical stability result.

## System and setting

The method applies to switched-affine systems and includes a converter-oriented application.

## Approach

The paper reduces the candidate search and approximates parts of the cost to make the MPC computation more practical.

## Main contribution

The source proposes a practically stabilizing switched-affine MPC scheme with computational reductions.

## Evidence

The paper reports converter simulations and numerical comparisons.

## Assumptions and limitations

The method remains an approximate predictive-control search. It does not replace the optimization problem with a scalar scan of a static timing action.

## Concepts useful for later reading

- switched-affine MPC;
- candidate pruning;
- cost approximation;
- practical stability;
- online computation.

## Source pointers

The article cites this source in the Introduction as an example of reducing the cost of predictive control.
