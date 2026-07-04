# Context: MPC Feasibility Regions (Polytope Projection)

This document outlines the purpose, architecture, and dependencies of the `projecao` repository/module. It focuses on the calculation and visualization of constraints for systems controlled by a Model Predictive Control (MPC) algorithm, specifically in a Dual-Mode formulation.

## 1. Main Objective
The scripts calculate the **Maximal Admissible Set ($O_\infty$)** for the optimal terminal LQR control problem. Based on this, they extract the exact **Feasibility Region** using polytope projection techniques over augmented MPC prediction matrices for varying prediction horizons ($N$). The resulting plots usually overlay polygons generated from consecutive horizon steps and are most likely used as visual material for a PhD thesis.

## 2. Dependencies
To run this project seamlessly, **MATLAB** is required along with the following specialized toolboxes/libraries:
*   **MATLAB Control System Toolbox**: Used for geometric and system matrix calculations such as discrete optimal control (`dlqr`) and Toeplitz matrices.
*   **MPT Toolbox 3.x (Multi-Parametric Toolbox)** and **YALMIP** / **Internal Solvers (CDD, GLPK)**: Strongly coupled throughout the scripts. Used via the creation of geometric objects from the `Polyhedron()` class and methods like `projection()`.
*   **MATLAB Optimization Toolbox**: Used for the `linprog` function (along with `optimoptions`) when checking and removing redundant constraint bounds/edges.

## 3. Architecture and Core Structure

*   **Models and Examples (Main Scripts)**:
    *   `projecao_integrador_duplo.m`: Calculates the constraints and LQR gains for a fundamental 2-state double integrator problem.
    *   `projecao_patino1.m` and `projecao_patino2.m`: Formulate the Buck-Boost topology containing asymmetric constraints defined over error variables relative to a steady-state point `xbar`. `patino2` models a constrained state space in $\mathbb{R}^3$.
*   **Core Routines (`create_projection.m`)**:
    *   The central orchestrator routine that bridges the discrete-time LQR calculations with the computation of the $O_\infty$ set.
    *   It stacks the dynamic state equations (the `Sw` matrix) over the prediction horizon $N$ (and the chain of input variables) into a higher-dimensional space, perfectly extracting the feasible basis subject to the given constraints.
*   **Admissible Polygonal Characterization (`determina_oinf.m` and `teste_redundancia.m`)**:
    *   These scripts guarantee closed-loop terminal stability without bias by actively verifying whether the feedback gain and prediction matrix exceed permitted bounds. They evaluate bounds intersection over time with intermittent calls to `linprog` to discard redundant edges.
*   **Plotting Module (`+plotter` and `Projecao.m`)**:
    *   Object-oriented encapsulation of custom plot methods into dedicated hierarchical graphical packages.

## 4. Maintenance History (Points of Attention)
*   **Convexity and Abstract Misalignment Bug**: Previously, the generated polygons suffered from geometric plotting dispersion (abrupt cuts along unbounded rays creating discontiguous areas misaligned from `xbar`). This happened because the iterative multivariate detection loop of $O_\infty$ was being prematurely aborted due to spurious variable calls inside `teste_redundancia.m`.
    *   The subsequent fix involved:
        1. Correcting the undeclared native arguments `Sa` and `ba` inside `teste_redundancia.m` to properly use the ones passed in (`S` and `b`). We also added an isolated logical check for unbounded exit flags (`exitflag == -3`, yielding `t = 1`).
        2. Uncommenting the previously disabled iterative constraint loop in `determina_oinf.m`, forcing the solver to topologically close the invariant region instead of leaving an unrestricted analytical tunnel.
