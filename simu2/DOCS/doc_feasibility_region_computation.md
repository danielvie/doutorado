# Feasibility Region Computation using MPT3

This document details the theory, methodology, and best practices for computing the feasible state-space regions of simulated dynamic systems (like the PATINO switch-mode systems) using the Multi-Parametric Toolbox 3 (MPT3) in MATLAB.

## Overview

The feasibility region of a system for a given prediction horizon $N_p$ is the set of all initial states $x_0$ for which there exists a valid sequence of control inputs that satisfies all system constraints over the horizon, while guaranteeing that the final state lands in a safe terminal set.

MPT3 is the standard academic tool for this, as it provides highly optimized routines for polyhedral geometry, invariant sets, and reachability analysis.

## Mathematical Formulation

### 1. System Dynamics
The system at the switching instants is linearized into a discrete-time representation:
$$x_{k+1} = \Phi x_k + \Gamma u_k$$
where $u_k$ represents the variations in switching times ($dt_k$).

### 2. Constraints
Switching time variations are bound by minimum dwell times, forming inequality constraints:
$$L u_k \ge c \implies -L u_k \le -c$$
where $L$ is a Toeplitz matrix mapping differences in intervals, and $c$ is the constraint vector based on timing margins.

### 3. Terminal Set / Maximal Admissible Set (MAS)
To guarantee infinite-horizon stability, the prediction horizon must end inside a Terminal Invariant Set ($X_f$). This is computed as the Maximal Admissible Set (MAS) under an unconstrained LQR controller $u = -K x$.
The closed-loop dynamics become:
$$x_{k+1} = (\Phi - \Gamma K) x_k$$
Subject to the mapped constraints:
$$-L (-K x) \le -c \implies L K x \le -c$$

## Implementation Approaches

There are two primary ways to project these constraints into the state-space.

### Approach 1: Explicit MPC Domain (Low-Dimensional Systems)
For simple systems (e.g., `PATINO_1` with $n=2$, small $p$), we can formulate the complete Multi-Parametric problem.

1. Define the MPT3 `LTISystem` with state and input penalties ($Q$, $R$).
2. Apply the constraints and the Terminal Set ($X_f$).
3. Formulate the `MPCController` with horizon $N_p$.
4. Convert to an Explicit MPC controller. The exact parametric `Domain` of this explicit partition represents the feasibility region.

**Limitations:** This approach suffers from severe combinatorial explosion in higher dimensions. It attempts to divide the feasible region into optimal control partitions, which is completely unnecessary if we only want the outer boundary of the feasible set.

### Approach 2: Backward Reachability Sets (High-Dimensional Systems)
For complex systems (e.g., `PATINO_2` with $n=3$, $p=8$), solving the explicit MPC is intractable. Instead, we use purely geometric **Backward Reachability Sets**. 

The feasibility domain of an MPC problem with horizon $N_p$ and terminal set $X_f$ is exactly mathematically equivalent to the **$N_p$-step backward reachable set** from $X_f$.

1. Initialize $R_{current} = X_f$.
2. Iteratively compute the 1-step backward reachable set $N_p$ times.
3. The resulting polyhedron at step $k$ is the exact feasibility region for $N_p = k$.

*This approach is recommended for all simulation cases as it is extremely fast and robust.*

## Important Numerical Considerations (Lessons Learned)

When projecting these sets, several critical numerical issues arise due to the floating-point nature of the CDD/GLPK solvers used by MPT3.

### 1. Zero-Boundary Relaxation
If elements of the constraint vector $c$ evaluate to exactly `0.0`, the origin lies perfectly on the boundary of the allowed space. Geometric solvers frequently fail to compute invariant sets for marginal boundary cases due to tolerances. 
**Fix:** Apply a tiny negative relaxation to the constraints:
```matlab
c_relaxed = min(c, -1e-5);
```

### 2. Numerical Variable Scaling (Crucial)
If system inputs/constraints are extremely small (e.g., $c \approx 10^{-4}$) while the states are $O(1)$, the resulting LQR gain $K$ drops to $10^{-4}$. MPT3 solvers rely on fixed tolerances ($\approx 10^{-7}$). This mismatch causes the solvers to interpret small, sharp vertices as "unbounded rays", resulting in corrupted, infinite, or completely empty polyhedra.

**Fix:** Scale the input variables up without changing the mathematical behavior. If we scale inputs by a factor (e.g., $10^4$), the solvers work perfectly.
```matlab
u_scale = 1e4;
Gamma_s = Gamma / u_scale;
c_s = c * u_scale;
R_s = R / (u_scale^2); % Adjust R to maintain exact LQR equivalence

% Compute MAS and Reachable sets using Gamma_s and c_s
```

### 3. Polyhedron Minimization
Backward reachability iteratively adds hyperplanes to the polyhedron, many of which become mathematically redundant. If left unchecked, the computation slows down exponentially.
**Fix:** Force MPT3 to minimize the Half-space representation (H-rep) after every step.
```matlab
R_current.minHRep();
```

### 4. H-Rep Row Normalization (Plotting Fix)
Even after scaling and minimization, the backward reachability iterations accumulate hyperplanes whose rows in $A$ (from $Ax \le b$) have widely different norms (e.g., one row with $\|a_i\| = 0.02$ and another with $\|a_i\| = 1.4$). The CDD library (used internally by MPT3 for vertex enumeration during `plot()`) relies on fixed floating-point tolerances. When row norms vary by orders of magnitude, CDD misclassifies vertices — producing missing faces, corrupted geometry, or outright errors like:

```
*Error: Numerical inconsistency is found.  Use the GMP exact arithmetic.
```

**Symptoms without this fix:**
- Some horizons (e.g., $N_p = 2$) may not render at all.
- Larger horizons (e.g., $N_p = 4$) display with missing vertices/faces.
- The H-rep itself is mathematically correct (contains the origin, is bounded, non-empty), but vertex enumeration fails silently or with the error above.

**Fix:** Before plotting, normalize each row of the H-representation to unit length:
```matlab
function P_out = normalize_hrep(P)
    A_h = P.A;
    b_h = P.b;
    row_norms = sqrt(sum(A_h.^2, 2));
    A_n = A_h ./ row_norms;
    b_n = b_h ./ row_norms;
    P_out = Polyhedron(A_n, b_n);
    P_out.minHRep();
end
```

This divides each constraint $a_i^T x \le b_i$ by $\|a_i\|_2$, making all rows comparable in scale without changing the geometry. After normalization, CDD enumerates vertices cleanly for all horizons.

## Summary of Numerical Fixes

| Issue | Symptom | Fix |
|---|---|---|
| Zero-boundary constraints | Empty invariant sets | `c_relaxed = min(c, -1e-5)` |
| Small constraint magnitudes (~1e-4) | Empty or unbounded polyhedra | Scale inputs: `Gamma/s`, `c*s`, `R/s^2` |
| Redundant hyperplanes after reachability | Exponential slowdown | `R_current.minHRep()` after each step |
| Non-uniform H-rep row norms | Missing faces/vertices when plotting | Normalize rows to unit length before `plot()` |

## Example Best-Practice Implementation

```matlab
% 1. Extract and Scale System
[Phi, Gamma] = sys.get_phi_gamma();
c = sys.get_switching_constraints();

u_scale = 1e4;
Gamma_s = Gamma / u_scale;
c_relaxed = min(c * u_scale, -1e-5 * u_scale);

% 2. Compute Terminal Set (MAS)
K_s = dlqr(Phi, Gamma_s, Q, R / (u_scale^2));
sys_cl = LTISystem('A', Phi - Gamma_s*K_s);

% Assume L maps constraints as: -L*u <= -c
Hmpt = [L*K_s, -c_relaxed];
X_constraints = Polyhedron('H', Hmpt);
Xf = sys_cl.invariantSet('X', X_constraints);

% 3. Iterate Backward Reachability
sys_open = LTISystem('A', Phi, 'B', Gamma_s);
sys_open.u.with('setConstraint');
sys_open.u.setConstraint = Polyhedron(-L, -c_relaxed);

R_current = Xf;
for k = 1:Np_max
    R_current = sys_open.reachableSet('X', R_current, 'N', 1, 'direction', 'backward');
    R_current.minHRep(); % Keep geometry optimal
    
    % R_current is now the feasibility region for N_p = k
end

% 4. Normalize and Plot
for i = 1:length(domains)
    P = normalize_hrep(domains{i});  % Fix vertex enumeration
    plot(P, 'color', colors{i}, 'alpha', 0.2);
end
```
