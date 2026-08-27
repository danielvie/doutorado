# Stellato, Geyer, and Goulart (2017)

Status: descriptive source summary
BibTeX key: `stellato2017fcsMpc`
Source record: `references.bib`; publication DOI: `10.1109/TPEL.2016.2584678`
Read when: studying deterministic online computation in power-electronics MPC

## Bibliographic identity

B. Stellato, T. Geyer, and P. J. Goulart, “High-Speed Finite Control Set Model Predictive Control for Power Electronics,” *IEEE Transactions on Power Electronics*, 32(5), 4007–4020, 2017.

## Problem

The paper addresses the computational burden of finite-control-set model predictive control in power electronics, where the control decision must fit a short execution budget.

## System and setting

The method targets power-electronics systems using finite-control-set MPC and hardware-oriented implementation constraints.

## Approach

The paper uses short prediction horizons, an offline approximate tail cost, and fixed-point exhaustive evaluation. The project literature notes identify deterministic FPGA execution for the studied implementation.

## Main contribution

The source presents a high-speed finite-control-set MPC implementation that makes the online computation predictable for its selected horizon and hardware implementation.

## Evidence

The paper reports an FPGA-oriented implementation and measured execution behavior for the studied power-electronics controller.

## Assumptions and limitations

The execution result is implementation-specific. It does not establish a hardware-independent computation bound for arbitrary horizons, controllers, or converters.

## Concepts useful for later reading

- finite-control-set MPC;
- offline tail-cost approximation;
- short-horizon prediction;
- fixed-point exhaustive evaluation;
- deterministic execution time.

## Source pointers

The project citation review records the detailed sections used for the article's online-computation motivation.
