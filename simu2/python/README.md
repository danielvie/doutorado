
# Feasibility Region Computation — Python Alternative

This folder provides pure-Python implementations of the MPT3 backward-reachability
analysis for the Patiño benchmarks (PATINO_1, PATINO_2, INTEGRADOR_DUPLO, and
LAB_CIRCUIT), enabling computation on macOS Apple Silicon without MATLAB.

## Files

| File | Description |
|------|-------------|
| `project_patino1.py` | PATINO_1 feasibility regions (n=2 states, p=1 input) |
| `project_patino2.py` | PATINO_2 feasibility regions (n=3 states, p=8 inputs) |
| `project_integrador_duplo.py` | INTEGRADOR_DUPLO feasibility regions (n=2 states, p=3 inputs) |
| `pyproject.toml` | Project manifest (uv) |
| `export_data.m` | MATLAB helper to export system matrices to `.mat` |

## Quick Start

```bash
# Install dependencies
uv sync

# Run PATINO_1
uv run python python/project_patino1.py

# Run PATINO_2
uv run python python/project_patino2.py

# Run INTEGRADOR_DUPLO
uv run python python/project_integrador_duplo.py
```

Each script auto-detects a `.mat` file with real system data; if none is found it
falls back to a representative template so the pipeline can be validated immediately.

## Exporting Real Data from MATLAB

On a machine with MATLAB + MPT3, run the provided helper:

```matlab
>> export_data('integrador_duplo');  % saves integrador_duplo_data.mat
>> export_data('patino1');           % saves patino_1_data.mat
>> export_data('patino2');           % saves patino_2_data.mat
>> export_data('lab_circuit');       % saves lab_circuit_data.mat
```

Or manually:

```matlab
s = Simulation(Enums.SimName.PATINO_2);
[Phi, Gamma] = s.get_phi_gamma();
c = s.get_switching_constraints();
save patino2_data.mat Phi Gamma c
```

Place the `.mat` file in the `simu2/` root directory (not inside `python/`).
Both scripts search the project root automatically.

## How It Works

Both scripts follow the same two-stage approach described in
`../DOCS/doc_feasibility_region_computation.md`:

### 1 — Maximal Admissible Set (MAS)
An iterative invariant-set computation under the closed-loop dynamics
`x+ = (Φ − ΓK)x` with the terminal constraint `L K x ≤ −c`, until the H-rep
stops changing.

### 2 — Backward Reachability
For each prediction horizon `Np ∈ {1, 2, 4}`:

1. For each halfspace `aᵢᵀ y ≤ bᵢ` of the current set `R_{k−1}`,
   solve the LP `min aᵢᵀ Γ u` over the input polytope `U` to obtain the tight
   offset `bᵢ′ = bᵢ − min aᵢᵀ Γ u`.
2. Form the new H-rep `R_k = { x | (aᵢᵀ Φ) x ≤ bᵢ′ }`.

This is the **halfspace (dual) method** — it avoids high-dimensional projection
entirely and works in the native state-space dimension (2D or 3D).

## Numerical Stability

The same fixes from the MPT3 documentation are applied:

- **Scaling**: inputs scaled by `u_scale = 1e4` to prevent tiny constraints
  (~10⁻⁴) from being misread as unbounded rays.
- **Relaxation**: `c_relaxed = min(c × u_scale, −1e-5 × u_scale)`.
- **H-rep row normalization** before vertex enumeration (fixes CDD vertex
  misclassification when hyperplane norms vary by orders of magnitude).
- **MAS convergence tolerance** `atol = 1e-6`.

## Dependencies

- `numpy`
- `scipy`
- `matplotlib`
- `control` (python-control, for `dlqr`)
- `polytope` (python-polytope, for H/V-rep operations)

All are installed automatically by `uv sync` via `pyproject.toml`.

## Notes

- `polytope` attempts to import `cvxopt.glpk`; if unavailable it falls back to
  `scipy.optimize.linprog` — no additional setup required.
- The 3D renderer (`project_patino2.py`) requires at least 4 non-coplanar
  vertices per polyhedron; degenerate cases are skipped with a warning.
figures are saved as `feasibility_regions_patino1.png`,
`feasibility_regions_patino2.png`, and `feasibility_regions_integrador_duplo.png`
in the project root for headless environments.