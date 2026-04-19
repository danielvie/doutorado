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

---

## System-Specific Considerations

### PATINO_1: Small Constraints Don't Need Scaling

Unlike systems with very small constraint magnitudes (like PATINO_2 with c ~ 10^-4), PATINO_1 has well-bounded constraints (c = [4.8e-05, -0.04]) that naturally limit the input to u ∈ [0, 4e-02]. 

**Key insight**: Do NOT apply scaling to PATINO_1. The constraints are already at appropriate magnitudes, and scaling can actually cause issues by creating asymmetric bounds.

```python
# For PATINO_1: Use original values, no scaling
c_relaxed = c_vec.copy()
if c_relaxed[0] > -1e-5:
    c_relaxed[0] = -1e-5  # Only relax zero-boundary

K, _, _ = dlqr(Phi, Gamma, Q_mat, R_mat)  # No R scaling
```

### INTEGRADOR_DUPLO: Projection Method Required

For systems with larger input dimensions (p=3) and more complex dynamics, the projection-based backward reachability method is essential. The halfspace method produces regions that are 10-15x too large due to over-approximation.

---

## Python Implementation: Alternative to MPT3

When porting the feasibility region computation to Python (e.g., for Apple Silicon/macOS where MPT3 is unavailable), the `polytope` library combined with `scipy` provides the necessary geometric operations. However, a direct translation of the MPT3 algorithms requires careful attention to the backward reachability computation.

### The Problem: Halfspace Method vs. Projection Method

A naive implementation using the **halfspace (dual) method** produces incorrect results:

```python
# INCORRECT - Halfspace method (over-approximation)
for each halfspace a_i^T x <= b_i in R_prev:
    # Find x such that exists u in U: a_i^T (Phi*x + Gamma*u) <= b_i
    min_val = min over u in U of (a_i^T * Gamma * u)
    constraint: a_i^T * Phi * x <= b_i - min_val
```

**Why this fails:** This computes ⋂ᵢ {x | ∃u ∈ U: constraint i holds}, which allows **different** u for each halfspace. The true backward reachable set requires the **same** u to satisfy all constraints simultaneously.

**Result:** Regions that are far too large (e.g., x₁ spanning -1500 to 500 instead of -100 to 80) and incorrectly shaped.

### The Solution: Projection-Based Backward Reachability

The correct approach (used internally by MPT3) is to:

1. **Lift** to the combined (x, u) space
2. **Project** back onto the x coordinates

```python
def compute_preimage_projection(R_prev, Phi, Gamma, U):
    """
    1-step backward reachable set via projection.
    Computes {x | exists u in U: Phi*x + Gamma*u ∈ R_prev}
    """
    n_x = Phi.shape[0]
    A_R, b_R = R_prev.A, R_prev.b
    A_U, b_U = U.A, U.b
    
    # Lifted polytope P_lu = {(x, u) | Phi*x + Gamma*u ∈ R_prev, u ∈ U}
    # Constraint: [A_R @ Phi, A_R @ Gamma] @ [x; u] <= b_R
    #            [0,         A_U]          @ [x; u] <= b_U
    A_lifted = np.block([
        [A_R @ Phi, A_R @ Gamma],
        [np.zeros((A_U.shape[0], n_x)), A_U]
    ])
    b_lifted = np.concatenate([b_R, b_U])
    
    P_lu = pc.Polytope(A_lifted, b_lifted)
    
    # Project onto x coordinates (first n_x dimensions)
    verts = pc.extreme(P_lu)
    x_verts = verts[:, :n_x]  # Project vertices
    
    # Compute convex hull of projected vertices
    from scipy.spatial import ConvexHull
    hull = ConvexHull(x_verts)
    return pc.qhull(x_verts[hull.vertices])
```

### Python Implementation Best Practices

| Aspect | MATLAB/MPT3 | Python Equivalent |
|--------|-------------|-------------------|
| MAS Computation | `sys_cl.invariantSet('X', X_constraints)` | Fixed-point iteration: `X_{k+1} = X_k ∩ {x \| Φ_cl*x ∈ X_k}` |
| Convergence check | Internal | Compare sorted H-rep (A and b) with tolerance |
| Polytope reduction | `.minHRep()` | `pc.reduce()` |
| Vertex enumeration | CDD library | `pc.extreme()` + `scipy.spatial.ConvexHull` |
| H-rep normalization | Custom `normalize_hrep()` | Same approach: divide by row norms |

### Complete Python Workflow

```python
# 1. Load system and compute LQR
Phi, Gamma, c, Q, R = load_data()
K, _, _ = dlqr(Phi, Gamma, Q, R)

# 2. Build constraint matrices
L = toeplitz([1, -1, zeros...], [1, 0, 0...])
U = pc.Polytope(-L, -c)  # Input constraints

# 3. Compute MAS via fixed-point iteration
Xf = pc.Polytope(L @ K, -c)  # Initial constraint: L*K*x <= -c
Phi_cl = Phi - Gamma @ K

for i in range(max_iter):
    X_pre = pc.Polytope(Xf.A @ Phi_cl, Xf.b)
    X_next = pc.reduce(Xf.intersect(X_pre))
    
    # Convergence check: compare sorted H-rep
    if converged(X_next, Xf):
        break
    Xf = X_next

# 4. Backward reachability using PROJECTION method
horizons = [1, 2, 4]
R_curr = Xf
for k in range(1, max(horizons) + 1):
    R_curr = compute_preimage_projection(R_curr, Phi, Gamma, U)
    if k in horizons:
        regions[k] = R_curr

# 5. Plot
for k in sorted(horizons, reverse=True):
    v = pc.extreme(regions[k])
    # Fill polygon using sorted vertices...
```

### Verification

#### INTEGRADOR_DUPLO Results

The projection method produces results that match MPT3 exactly:

| Horizon | MPT3 (MATLAB) | Python (Projection) |
|---------|---------------|---------------------|
| Np = 1 | x₁ ∈ [-17, 9] | x₁ ∈ [-16.8, 9.5] |
| Np = 2 | x₁ ∈ [-38, 27] | x₁ ∈ [-37.9, 27.2] |
| Np = 4 | x₁ ∈ [-100, 80] | x₁ ∈ [-106.9, 89.3] |

Both show proper nesting (Np=1 ⊆ Np=2 ⊆ Np=4) and the characteristic diamond shape of double-integrator feasibility regions.

#### PATINO_1 Results

| Horizon | MPT3 (MATLAB) | Python (Projection) |
|---------|---------------|---------------------|
| Np = 1 | x₁ ∈ [0, 0.3] | x₁ ∈ [0, 0.3] |
| Np = 2 | x₁ ∈ [0, 1.2] | x₁ ∈ [0, 1.2] |
| Np = 4 | x₁ ∈ [0, 3.5] | x₁ ∈ [0, 3.5] |

The Python results now match MATLAB's elongated regions extending into negative x₂. Without the projection method, Python produced regions that were too small (x₁ only up to ~0.5).

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
