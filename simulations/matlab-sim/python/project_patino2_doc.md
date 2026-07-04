# project_patino2.py — Technical Documentation

> Feasibility Region Computation via Backward Reachability Analysis  
> Python alternative to MATLAB's MPT3 toolbox, designed for Apple Silicon / macOS environments.

---

## Table of Contents

- [project\_patino2.py — Technical Documentation](#project_patino2py--technical-documentation)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [System Model](#system-model)
  - [Key Concepts](#key-concepts)
    - [H-representation (H-rep)](#h-representation-h-rep)
    - [V-representation (V-rep)](#v-representation-v-rep)
    - [Maximal Admissible Set (MAS)](#maximal-admissible-set-mas)
    - [Backward Reachability](#backward-reachability)
    - [Feasibility Region](#feasibility-region)
  - [Dependencies](#dependencies)
  - [Pipeline Overview](#pipeline-overview)
  - [Function Reference](#function-reference)
    - [`normalize_hrep`](#normalize_hrep)
    - [`vertices_to_hrep`](#vertices_to_hrep)
    - [`robust_qhull`](#robust_qhull)
    - [`compute_preimage`](#compute_preimage)
    - [`load_data`](#load_data)
    - [`main`](#main)
  - [Pipeline Stages (main)](#pipeline-stages-main)
    - [Stage 1 — Load System Matrices](#stage-1--load-system-matrices)
    - [Stage 2 — Numerical Scaling](#stage-2--numerical-scaling)
    - [Stage 3 — LQR Gain Computation](#stage-3--lqr-gain-computation)
    - [Stage 4 — Dwell-Time Constraint Matrix](#stage-4--dwell-time-constraint-matrix)
    - [Stage 5 — Maximal Admissible Set](#stage-5--maximal-admissible-set)
    - [Stage 6 — Backward Reachability](#stage-6--backward-reachability)
    - [Stage 7 — 3D Visualization](#stage-7--3d-visualization)
  - [How to Run](#how-to-run)
  - [Output](#output)
  - [Known Limitations](#known-limitations)

---

## Overview

This script computes the **feasibility region** of a discrete-time linear switching system described by the PATINO_2 model. It replicates the backward reachability analysis performed by MATLAB's MPT3 toolbox entirely in Python.

The central question it answers is:

> *"For which initial states `x` does there exist an admissible control sequence `u` that keeps the system within its constraints for `Np` time steps?"*

The set of all such states is the **feasibility region** for horizon `Np`.

---

## System Model

The system follows discrete-time linear dynamics:

```
x[k+1] = Phi * x[k] + Gamma * u[k]
```

Where:

| Symbol  | Dimension   | Description                                       |
| ------- | ----------- | ------------------------------------------------- |
| `x[k]`  | `n × 1`     | State vector at time step `k`                     |
| `u[k]`  | `p × 1`     | Control input (switching signal) at time step `k` |
| `Phi`   | `n × n`     | State transition matrix                           |
| `Gamma` | `n × p`     | Input matrix (effect of control on state)         |
| `c`     | `(p+1) × 1` | Dwell-time constraint limits                      |

The PATINO_2 default template uses `n = 3` states and `p = 8` inputs.

---

## Key Concepts

### H-representation (H-rep)

A polytope in H-rep is described by a set of linear inequalities:

```
P = { x ∈ Rⁿ | A * x ≤ b }
```

Each row of `A` defines a halfspace (a "wall" bounding the polytope). The polytope is the intersection of all halfspaces.

**Advantages:**
- Easy to check if a point is inside (`A*x ≤ b`)
- Intersection of two polytopes is trivial (stack the rows of `A` and `b`)

**Used in:** MAS construction, pre-image constraints, control set `U`.

---

### V-representation (V-rep)

A polytope in V-rep is described by listing its **vertices** explicitly.

**Advantages:**
- Easy projection (drop coordinates from vertices)
- Easy visualization (plot the vertices)

**Disadvantages:**
- Intersection requires converting back to H-rep
- Number of vertices can grow exponentially with dimension

**Used in:** intermediate computations inside `compute_preimage`, and for 3D mesh rendering in the plot.

---

### Maximal Admissible Set (MAS)

The MAS (`Xf`) is the largest set of states from which the closed-loop system satisfies all constraints **for all future time**. It is computed as the fixed point of the iteration:

```
Xf⁰ = { x | L * K * x ≤ c }
Xfⁱ⁺¹ = Xfⁱ ∩ { x | Phi_cl * x ∈ Xfⁱ }
```

Convergence is reached when `Xfⁱ⁺¹ = Xfⁱ`, i.e., no new constraints are added.

The MAS serves as the **terminal safe set** — the target that backward reachability aims to reach.

---

### Backward Reachability

Given a target set `R` and system dynamics, the **1-step pre-image** is:

```
Pre(R) = { x | ∃ u ∈ U : Phi * x + Gamma * u ∈ R }
```

This is the set of states that can reach `R` in exactly one step by choosing some admissible control `u`.

Iterating this operation gives the feasibility region for horizon `Np`:

```
R₀ = MAS
R₁ = Pre(R₀)   → states that reach MAS in 1 step
R₂ = Pre(R₁)   → states that reach MAS in 2 steps
R₄ = Pre(R₃)   → states that reach MAS in 4 steps
```

Each successive set is a **superset** of the previous one — more time means more initial states are feasible.

---

### Feasibility Region

The feasibility region for horizon `Np` is `Rₙₚ`: the set of all initial states from which there exists at least one admissible control sequence of length `Np` that drives the system into the MAS.

Intuitively: the larger `Np`, the more "room" the controller has, and the larger the feasibility region.

---

## Dependencies

| Package         | Role                                              |
|-----------------|---------------------------------------------------|
| `numpy`         | Matrix operations, numerical computations         |
| `scipy`         | `ConvexHull`, `toeplitz`, `loadmat`               |
| `polytope`      | Polytope representation, `qhull`, `extreme`, etc. |
| `control`       | Discrete LQR (`dlqr`)                             |
| `matplotlib`    | 3D visualization                                  |

---

## Pipeline Overview

```
┌─────────────────────────────────────────┐
│  Stage 1: Load system data              │
│  Phi, Gamma, c, Q, R  ←  .mat file      │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│  Stage 2: Numerical scaling             │
│  Gamma_s = Gamma / 1e4                  │
│  c_relaxed = min(c * 1e4, -0.1)         │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│  Stage 3: LQR gain K                    │
│  K = dlqr(Phi, Gamma_s, Q, R)           │
│  Phi_cl = Phi - Gamma_s * K             │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│  Stage 4: Dwell-time matrix L           │
│  L = toeplitz(...)                      │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│  Stage 5: Maximal Admissible Set (MAS)  │
│  Xf ← fixed-point iteration             │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│  Stage 6: Backward Reachability         │
│  R_k = Pre(R_{k-1})  for k = 1..4       │
└────────────────────┬────────────────────┘
                     ↓
┌─────────────────────────────────────────┐
│  Stage 7: 3D Plot                       │
│  Render R₁, R₂, R₄ as convex hulls      │
└─────────────────────────────────────────┘
```

---

## Function Reference

---

### `normalize_hrep`

```python
normalize_hrep(P: pc.Polytope) -> pc.Polytope | None
```

**Responsibility:**  
Normalizes the H-representation of a polytope so that each row of `A` has unit Euclidean norm. Also removes near-zero rows (norm < 1e-12) and calls `pc.reduce()` to eliminate redundant constraints.

**Why it exists:**  
Numerical computations on polytopes can accumulate floating-point errors, leading to rows with very small or very large norms. Normalizing ensures all halfspace constraints are comparably scaled, improving stability in subsequent operations.

**Inputs:**

| Parameter | Type          | Description              |
|-----------|---------------|--------------------------|
| `P`       | `pc.Polytope` | Polytope in H-rep        |

**Returns:** Normalized `pc.Polytope`, or `None` if empty or degenerate.

**Called by:** `compute_preimage`, visualization stage in `main`.

---

### `vertices_to_hrep`

```python
vertices_to_hrep(vertices: np.ndarray) -> tuple[np.ndarray, np.ndarray] | tuple[None, None]
```

**Responsibility:**  
Converts a V-rep (array of vertices) into an H-rep `(A, b)` such that `A * x ≤ b`. Uses `scipy.spatial.ConvexHull` to extract the facet equations of the convex hull.

**How it works:**  
`ConvexHull` returns equations in the form `[normal, offset]` where `normal · x + offset ≤ 0`. This is equivalent to `normal · x ≤ -offset`, so `A = normal` and `b = -offset`.

A small random perturbation (`1e-9`) is added to the vertices before computing the hull to avoid failures caused by exactly coplanar points.

**Inputs:**

| Parameter  | Type         | Description                   |
|------------|--------------|-------------------------------|
| `vertices` | `np.ndarray` | Array of shape `(n_pts, dim)` |

**Returns:** `(A, b)` as numpy arrays, or `(None, None)` on failure.

**Called by:** `robust_qhull` (Attempt 2).

---

### `robust_qhull`

```python
robust_qhull(vertices: np.ndarray) -> pc.Polytope | None
```

**Responsibility:**  
Converts a V-rep into an H-rep polytope using a three-level fallback strategy. Handles degenerate or near-degenerate vertex sets that would cause `pc.qhull` to fail.

**Fallback levels:**

| Attempt | Method                    | Quality        | When used                    |
| ------- | ------------------------- | -------------- | ---------------------------- |
| 1       | `pc.qhull()`              | ✅ Exact        | Always tried first           |
| 2       | `scipy.ConvexHull`        | ✅ Exact        | If Attempt 1 fails           |
| 3       | Axis-aligned bounding box | ⚠️ Conservative | If both Attempt 1 and 2 fail |

> ⚠️ **Warning:** Attempt 3 (bounding box) returns a region that is **larger** than the true convex hull. When this fallback is triggered, a `RuntimeWarning` is issued informing that the feasibility region may be **inflated** in that iteration.

**Inputs:**

| Parameter  | Type         | Description                   |
|------------|--------------|-------------------------------|
| `vertices` | `np.ndarray` | Array of shape `(n_pts, dim)` |

**Returns:** `pc.Polytope` in H-rep, or `None` if all attempts fail.

**Called by:** `main` (Stage 6, to verify that the control set `V` is valid).

---

### `compute_preimage`

```python
compute_preimage(R_prev, Phi, Gamma, U) -> pc.Polytope | None
```

**Responsibility:**  
Computes the 1-step backward reachable set (pre-image) of polytope `R_prev` under the system dynamics. Returns the set of all states `x` from which there exists an admissible control `u ∈ U` such that the next state `Phi*x + Gamma*u` lies inside `R_prev`.

**Mathematical definition:**

```
Pre(R_prev) = { x | ∃ u ∈ U : Phi * x + Gamma * u ∈ R_prev }
```

**Internal steps:**

**Step 1 — Build the lifted polytope in `(x, u)` space:**

The constraints are assembled into a single H-rep over the joint variable `(x, u)`:

```
[ A_R * Phi,  A_R * Gamma ] [ x ]   [ b_R ]
[ 0,          A_U         ] [ u ] ≤ [ b_U ]
```

- First block: next state must be in `R_prev`
- Second block: control must be in `U`

**Step 2 — Enumerate vertices of the lifted polytope:**

`pc.extreme()` computes the V-rep of the lifted polytope.

**Step 3 — Project vertices onto the `x` subspace:**

The `u` columns are dropped, keeping only the first `n_x` coordinates of each vertex.

**Step 4 — Compute the convex hull of the projected vertices:**

`scipy.ConvexHull` + `pc.qhull()` reconstruct the H-rep of the projected set. The result is normalized via `normalize_hrep()`.

**Inputs:**

| Parameter | Type          | Description                               |
|-----------|---------------|-------------------------------------------|
| `R_prev`  | `pc.Polytope` | Target set (must be H-rep)                |
| `Phi`     | `np.ndarray`  | State transition matrix `(n × n)`         |
| `Gamma`   | `np.ndarray`  | Input matrix `(n × p)`                    |
| `U`       | `pc.Polytope` | Admissible control set in H-rep           |

**Returns:** Pre-image as `pc.Polytope` in H-rep, or `None` on failure.

**Called by:** `main` (Stage 6, inside the backward reachability loop).

---

### `load_data`

```python
load_data(path: str = "data_patino_2.mat") -> tuple[Phi, Gamma, c, Q, R]
```

**Responsibility:**  
Loads the system matrices from a `.mat` file. Searches multiple candidate paths to handle different working directories and naming conventions. Falls back to a hardcoded PATINO_2 template if no file is found.

**Search order:**

1. `path` (argument as provided)
2. `data_patino2.mat` (alternate naming convention)
3. `python/<path>`
4. `python/data_patino2.mat`

**Fallback template:**  
3-state, 8-input system with pre-defined `Phi`, `Gamma`, and `c` matrices. `Q` and `R` default to identity matrices if not present in the `.mat` file.

**Inputs:**

| Parameter | Type  | Description                       |
|-----------|-------|-----------------------------------|
| `path`    | `str` | Primary path to the `.mat` file   |

**Returns:** `(Phi, Gamma, c, Q, R)` as numpy arrays.

**Called by:** `main` (Stage 1).

---

### `main`

```python
main() -> None
```

**Responsibility:**  
Top-level orchestrator. Parses CLI arguments and executes all 7 stages of the pipeline in sequence: data loading, scaling, LQR design, MAS computation, backward reachability, and 3D visualization.

**CLI arguments:**

| Flag          | Description                                      |
| ------------- | ------------------------------------------------ |
| `--save-only` | Save the figure to disk without opening a window |

---

## Pipeline Stages (main)

### Stage 1 — Load System Matrices

Calls `load_data()` to retrieve `Phi`, `Gamma`, `c`, `Q`, `R` from a `.mat` file or the built-in template.

---

### Stage 2 — Numerical Scaling

Raw `Gamma` entries are typically on the order of `1e-3`. Without scaling, the polytope computations become numerically ill-conditioned. The scaling factor `u_scale = 1e4` brings all quantities to approximately the same order of magnitude:

```
Gamma_s   = Gamma / u_scale     # O(1e-3) → O(1)
c_s       = c * u_scale         # compensates for the scaling
c_relaxed = min(c_s, -0.1)     # ensures strictly negative lower bound
```

---

### Stage 3 — LQR Gain Computation

Computes the discrete LQR gain `K` that minimizes the quadratic cost:

```
J = Σ ( xᵀQx + uᵀRu )
```

`K` is used **only** to define the terminal set. The closed-loop matrix is:

```
Phi_cl = Phi - Gamma_s * K
```

Under `Phi_cl`, the state evolves as `x[k+1] = Phi_cl * x[k]`, which is stable by design.

---

### Stage 4 — Dwell-Time Constraint Matrix

The matrix `L` is built as a Toeplitz matrix that encodes **dwell-time switching constraints**: the control input cannot change arbitrarily between consecutive time steps.

```
L = toeplitz([1, -1, 0, ..., 0], [1, 0, ..., 0])
```

The constraint `L * u ≤ c` limits the rate of change of the switching signal across its `p` components.

---

### Stage 5 — Maximal Admissible Set

Computes `Xf`, the terminal safe set. The initial polytope is:

```
Xf⁰ = { x | L * K * x ≤ -c_relaxed }
```

At each iteration, the one-step forward image of `Xf` under `Phi_cl` is computed and intersected back:

```
Xfⁱ⁺¹ = Xfⁱ ∩ { x | A * Phi_cl * x ≤ b }
```

`pc.reduce()` removes redundant constraints after each intersection. Convergence is detected when the number of rows in `A` and the values in `b` stop changing (tolerance `1e-6`). Maximum 100 iterations.

---

### Stage 6 — Backward Reachability

Starting from the MAS `Xf`, iteratively computes the pre-image for `k = 1, 2, 3, 4`:

```
R₀ = Xf   (MAS, terminal safe set)
Rₖ = Pre(R_{k-1})
```

Results at horizons `Np ∈ {1, 2, 4}` are saved into the `results` dictionary for plotting.

The admissible control set is:

```
U = { u | -L * u ≤ -c_relaxed }
```

The image set `V = { -Gamma_s * u | u ∈ U }` is verified to be non-empty and full-dimensional before the loop begins.

---

### Stage 7 — 3D Visualization

Each feasibility region `Rₙₚ` is converted to V-rep via `pc.extreme()`, triangulated with `scipy.ConvexHull`, and rendered as a translucent surface using `ax.plot_trisurf()`.

Horizons are plotted in **reverse order** (largest first) so that smaller regions remain visible on top.

| Color   | Horizon | Meaning                            |
| ------- | ------- | ---------------------------------- |
| 🔴 Red   | Np = 1  | Smallest — only 1 step available   |
| 🟢 Green | Np = 2  | Intermediate region                |
| 🔵 Blue  | Np = 4  | Largest — 4 steps to reach the MAS |

Axis labels display the min/max range of each state variable computed across all plotted horizons.

The figure is always saved to `feasibility_regions_patino2.png`. If `--save-only` is not passed, it is also displayed interactively.

---

## How to Run

**Standard (interactive plot):**
```bash
uv run --project python python python/project_patino2.py
```

**Headless / CI (save figure only):**
```bash
uv run --project python python python/project_patino2.py --save-only
```

**Exporting data from MATLAB before running:**
```matlab
[Phi, Gamma] = s.get_phi_gamma();
c = s.get_switching_constraints();
save('data_patino2.mat', 'Phi', 'Gamma', 'c');
```

---

## Output

| File                                | Description                                     |
|-------------------------------------|-------------------------------------------------|
| `feasibility_regions_patino2.png`   | 3D plot of feasibility regions for Np = 1, 2, 4 |

---

## Known Limitations

| Issue | Location | Impact |
|---|---|---|
| Bounding box fallback in `robust_qhull` | Attempt 3 | Region may be **inflated** — a `RuntimeWarning` is issued |
| Vertex enumeration via `pc.extreme()` | `compute_preimage` Step 2 | Exponential complexity in high dimensions; can be slow for large `p` |
| MAS convergence check compares `b` but not `A` structure | Stage 5 | May miss convergence when rows of `A` are permuted |
| Projection is approximate for non-bounded lifted polytopes | `compute_preimage` | Result may not be the exact pre-image in degenerate cases |