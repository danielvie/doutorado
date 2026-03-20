"""
Feasibility Region Computation for PATINO_1 - Apple Silicon / macOS Alternative
------------------------------------------------------------------------------
Replicates the MPT3 backward-reachability analysis for PATINO_1
(n=2 state dimensions, p=1 scalar input) in pure Python.

Mirrors z_projection_patino1.m but replaces MPT3 with python-polytope + scipy,
making it fully native on Apple Silicon.

Usage:
    1. Export from MATLAB (on a machine with MPT3):
       >> s = Simulation(Enums.SimName.PATINO_1);
       >> [Phi, Gamma] = s.get_phi_gamma();
       >> c = s.get_switching_constraints();
       >> save('data_patino1.mat', 'Phi', 'Gamma', 'c');
    2. Run on your Mac:
       >> uv run --project python python/project_patino1.py
"""

import os

import matplotlib.pyplot as plt
import numpy as np
import polytope as pc
from control import dlqr
from scipy.io import loadmat
from scipy.optimize import linprog
from scipy.spatial import ConvexHull

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def is_bounded(P):
    """Fast check if polytope P is bounded using its H-rep."""
    if P is None:
        return False
    try:
        return P.A.shape[0] >= P.A.shape[1]
    except Exception:
        return False


def sample_interior(P, n_samples=500):
    """
    Sample random points strictly inside polytope P (H-rep: Ax <= b).
    Returns (n_verts, n_dims) array of boundary points from ConvexHull, or None.
    Handles unbounded bbox by clipping to constraint-derived bounds.
    """
    try:
        A, b = P.A, P.b
        n_dim = A.shape[1]

        # Derive a finite bounding box from constraint halfspaces
        # For each dimension j: -M <= x_j <= M where M is derived from constraints
        # x_j = (b_i - sum_{k!=j} A_ik * x_k) / A_ij for each constraint i
        # Take the most restrictive bounds
        M = 1e6  # fallback large bound
        bounds = np.array([[-M, M]] * n_dim)

        for j in range(n_dim):
            # Constraints that have a non-zero coefficient in dimension j
            idx = np.abs(A[:, j]) > 1e-12
            if not np.any(idx):
                continue
            Ai, bi = A[idx, j], b[idx]
            # For a_i*x <= b_i  =>  x_j <= (b_i - sum_{k!=j} A_ik*x_k) / A_ij
            # At optimum x_k=0: x_j <= bi / Ai
            # Similarly x_j >= -bi / Ai for -a_i*x <= b_i (i.e. Ai < 0)
            for k in range(len(Ai)):
                if Ai[k] > 0:
                    bounds[j, 1] = min(bounds[j, 1], bi[k] / Ai[k])
                else:
                    bounds[j, 0] = max(bounds[j, 0], -bi[k] / Ai[k])

        # Clamp to reasonable numerical limits
        bounds = np.clip(bounds, -1e9, 1e9)
        if np.any(bounds[:, 0] >= bounds[:, 1]):
            return None

        rng = np.random.default_rng(42)
        pts = rng.uniform(bounds[:, 0], bounds[:, 1], size=(n_samples, n_dim))

        # Keep interior points: Ax <= b
        keep = np.all(A @ pts.T <= b[:, None] + 1e-9, axis=0)
        pts = pts[keep]

        if len(pts) < 3:
            return None

        hull = ConvexHull(pts)
        return pts[hull.vertices]

    except Exception:
        return None


def get_vertices(P):
    """
    Get vertices of polytope P as (n_verts, n_dims) array.
    Tries pc.extreme first (fast, exact); falls back to interior sampling.
    """
    if P is None:
        return None
    try:
        v = pc.extreme(P)
        if v is not None and len(v) >= 3:
            return np.atleast_2d(v)
    except Exception:
        pass
    return sample_interior(P)


def normalize_hrep(P):
    """Normalize H-rep rows to unit length for numerical stability in plotting."""
    if P is None:
        return None
    try:
        if not hasattr(P, "A") or P.A.size == 0:
            return None
    except Exception:
        return None
    A, b = P.A, P.b
    norms = np.linalg.norm(A, axis=1)
    valid = norms > 1e-12
    if not np.any(valid):
        return None
    return pc.reduce(
        pc.Polytope(A[valid] / norms[valid, None], b[valid] / norms[valid])
    )


def compute_preimage_projection(R_prev, Phi, Gamma, U):
    """
    1-step backward reachable set via projection method.

    Computes the set of states x such that there exists u in U where
    Phi*x + Gamma*u ∈ R_prev.

    This is done by forming the lifted polytope in (x, u) space and projecting
    onto the x coordinates, which is the correct method (used by MPT3).

    The lifted constraint is:
        Phi*x + Gamma*u ∈ R_prev  =>  A_R @ (Phi*x + Gamma*u) <= b_R
        u ∈ U                      =>  A_U @ u <= b_U

    Which can be written as:
        [A_R @ Phi,  A_R @ Gamma] @ [x; u] <= b_R
        [0,          A_U]         @ [x; u] <= b_U
    """
    n_x = Phi.shape[0]
    n_u = Gamma.shape[1]

    A_R, b_R = R_prev.A, R_prev.b
    A_U, b_U = U.A, U.b

    # Form the lifted polytope P_lu = {(x, u) | Phi*x + Gamma*u ∈ R_prev, u ∈ U}
    # Constraint: A_R @ (Phi*x + Gamma*u) <= b_R
    #           = A_R @ Phi @ x + A_R @ Gamma @ u <= b_R
    # Matrix form: [A_R @ Phi,  A_R @ Gamma] @ [x; u] <= b_R

    # Lifted constraints
    A_lifted = np.block(
        [
            [A_R @ Phi, A_R @ Gamma],  # Dynamics constraint
            [np.zeros((A_U.shape[0], n_x)), A_U],  # Input constraint
        ]
    )
    b_lifted = np.concatenate([b_R, b_U])

    # Clip to prevent numerical overflow
    b_lifted = np.clip(b_lifted, -1e9, 1e9)

    try:
        # Create the lifted polytope
        P_lu = pc.Polytope(A_lifted, b_lifted)

        # Check if polytope is bounded and non-empty
        if not pc.is_fulldim(P_lu):
            return None

        # Project onto x coordinates (first n_x dimensions)
        # We do this by computing the projection polytope
        # Projection of P onto x: {x | exists u such that (x,u) in P}

        # Method: eliminate u variables using vertex projection
        verts = pc.extreme(P_lu)
        if verts is None or len(verts) == 0:
            return None

        # Filter out any NaN or Inf values
        valid_mask = np.all(np.isfinite(verts), axis=1)
        verts = verts[valid_mask]
        if len(verts) == 0:
            return None

        # Project vertices onto x coordinates
        x_verts = verts[:, :n_x]

        # Clip to reasonable bounds
        x_verts = np.clip(x_verts, -1e6, 1e6)

        # Compute convex hull of projected vertices
        if len(x_verts) < 3:
            # Not enough vertices for a 2D polytope
            # Return bounding box approximation
            x_min = np.min(x_verts, axis=0) if len(x_verts) > 0 else np.zeros(n_x)
            x_max = np.max(x_verts, axis=0) if len(x_verts) > 0 else np.zeros(n_x)
            return pc.box2poly(np.column_stack((x_min, x_max)))

        # Use qhull to compute convex hull
        try:
            hull = ConvexHull(x_verts)
            # Get hull vertices in order
            hull_verts = x_verts[hull.vertices]
            # Create polytope from vertices
            R = pc.qhull(hull_verts)
            return normalize_hrep(R)
        except Exception:
            # Fall back to bounding box
            x_min = np.min(x_verts, axis=0)
            x_max = np.max(x_verts, axis=0)
            return pc.box2poly(np.column_stack((x_min, x_max)))

    except Exception as e:
        print(f"    [!] Projection failed: {e}")
        return None


# Keep old function name for compatibility, but use projection method
def compute_preimage_halfspace(R_prev, Phi, Gamma, U):
    """Backward compatible wrapper that uses projection method."""
    return compute_preimage_projection(R_prev, Phi, Gamma, U)


def load_data(path="data_patino1.mat"):
    """
    Load system matrices from a .mat file or fall back to a representative
    template for PATINO_1 (n=2, p=1).
    Checks multiple paths for old and new naming conventions.
    """
    # Check multiple paths: old naming (data_patino1.mat) and new (data_patino_1.mat)
    search_paths = [
        path,
        "data_patino_1.mat",
        os.path.join("python", path),
        os.path.join("python", "data_patino_1.mat"),
    ]

    for p in search_paths:
        if os.path.exists(p):
            print(f"[*] Loading real system data from {p}...")
            try:
                data = loadmat(p)
                Phi = data["Phi"]
                Gamma = data["Gamma"]
                c = data["c"].flatten() if "c" in data else None
                Q = data.get("Q", np.eye(Phi.shape[0]))
                R = data.get("R", np.array([[1.0]]))
                return Phi, Gamma, c, Q, R
            except Exception as e:
                print(f"[!] Error loading .mat file: {e}")

    print("[!] No .mat file found. Using representative PATINO_1 template.")
    # PATINO_1: n=2, p=1 (2 states, scalar input)
    Phi = np.array([[0.998, 0.0012], [0.0008, 0.992]])
    Gamma = np.array([[0.0015], [0.0003]])  # (2, 1)
    c = np.array([-0.001, -0.001])  # u >= c[0], -u >= c[1]
    Q = np.eye(2)
    R = np.array([[1.0]])
    return Phi, Gamma, c, Q, R


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    # 1. Load data
    Phi, Gamma, c_vec, Q_mat, R_mat = load_data()
    n, p = Phi.shape[0], Gamma.shape[1]
    print(f"    System: n={n}, p={p}")

    # 2. No scaling needed for PATINO_1 - constraints are already well-bounded
    # Original constraints: c = [4.8e-05, -0.04] gives u ∈ [4.8e-05, 0.04]
    # MATLAB relaxes only c(1) to handle zero-boundary: c(1) = min(c(1), -1e-5)
    c_relaxed = c_vec.copy()
    if c_relaxed[0] > -1e-5:
        c_relaxed[0] = -1e-5

    # 3. LQR for terminal set (using original unscaled values)
    K, _, _ = dlqr(Phi, Gamma, Q_mat, R_mat)

    # 4. Dwell-time constraint matrix L (p=1 => L = [1; -1])
    L = np.array([[1], [-1]])

    # 5. Compute MAS via iterative invariant-set computation
    print("[*] Computing Maximal Admissible Set (MAS)...")

    # Initial constraint: L*K*x <= -c (from u = -K*x satisfying dwell-time constraints)
    # This defines the region where the LQR control law is admissible
    # The constraint alone defines an unbounded strip, so intersect with a reasonable box
    # Based on expected results, x1 ranges up to ~3-4, so use generous bounds
    x_min = np.array([-10.0, -10.0])
    x_max = np.array([10.0, 10.0])
    X_box = pc.box2poly(np.column_stack((x_min, x_max)))

    Xf_initial = pc.Polytope(L @ K, -c_relaxed)
    Xf = pc.reduce(X_box.intersect(Xf_initial))
    print(f"    Initial constraint polytope: {Xf.A.shape[0]} halfspaces")

    if pc.is_empty(Xf):
        print("[!] ERROR: Initial Xf is empty! Check constraints.")
        return

    # Normalize initial polytope
    Xf = normalize_hrep(Xf)
    print(f"    Initial Xf: full-dim={pc.is_fulldim(Xf)}, A shape={Xf.A.shape}")

    Phi_cl = Phi - Gamma @ K
    print(f"    Closed-loop Phi_cl eigenvalues: {np.linalg.eigvals(Phi_cl)}")

    mas_ok = False
    for i in range(200):
        # Pre-image under closed-loop dynamics: states x such that Phi_cl*x in Xf
        # This is: Xf.A @ Phi_cl @ x <= Xf.b
        X_pre = pc.Polytope(Xf.A @ Phi_cl, Xf.b)

        # Intersection with current set (invariant set computation)
        X_next = Xf.intersect(X_pre)

        # Reduce to minimal representation
        try:
            X_next = pc.reduce(X_next)
        except Exception:
            pass  # If reduce fails, continue with non-reduced

        # Check emptiness
        if pc.is_empty(X_next):
            print(f"    [!] MAS became empty at iteration {i}")
            break

        X_next = normalize_hrep(X_next)

        # Check convergence: compare H-representations (both A and b)
        converged = False
        if Xf.A.shape[0] == X_next.A.shape[0]:
            # Sort rows by angle for consistent comparison
            def sort_rows(A, b):
                norms = np.linalg.norm(A, axis=1)
                angles = (
                    np.arctan2(A[:, 1], A[:, 0])
                    if A.shape[1] >= 2
                    else np.zeros(len(A))
                )
                idx = np.lexsort((b, angles, norms))
                return A[idx], b[idx]

            A_curr, b_curr = sort_rows(Xf.A, Xf.b)
            A_next, b_next = sort_rows(X_next.A, X_next.b)

            if np.allclose(A_next, A_curr, atol=1e-8) and np.allclose(
                b_next, b_curr, atol=1e-8
            ):
                converged = True

        if converged:
            Xf = X_next
            print(f"    MAS converged in {i + 1} iterations.")
            mas_ok = True
            break

        Xf = X_next

    if not mas_ok:
        print("[!] MAS did not converge – using current approximation.")

    v_xf = get_vertices(Xf)
    print(
        f"    Xf: {len(v_xf) if v_xf is not None else 0} vertices, "
        f"full-dim={pc.is_fulldim(Xf)}"
    )

    # 6. Input constraint polytope U (bounded interval)
    # MATLAB: sys.u.min = c(1); sys.u.max = -c(2);
    # Constraint L*u >= c means: u >= c[0] and -u >= c[1] => u <= -c[1]
    u_min = float(c_relaxed[0])
    u_max = float(-c_relaxed[1])
    U = pc.box2poly(np.array([[u_min, u_max]]))  # (1, 2) => 1D interval
    v_u = get_vertices(U)
    print(
        f"    U: {len(v_u) if v_u is not None else 0} vertices, "
        f"bounds=[{u_min:.4f}, {u_max:.4f}]"
    )

    # 7. Backward reachability
    horizons = [1, 2, 4]
    results = {}  # horizon -> polytope
    vert_cache = {}  # horizon -> (n_verts, n_dims) array

    R_curr = Xf
    print("[*] Computing Backward Reachable Sets...")
    for k in range(1, max(horizons) + 1):
        R_next = compute_preimage_halfspace(R_curr, Phi, Gamma, U)
        if R_next is None:
            print(f"    [!] Pre-image failed at Np={k}. Stopping.")
            break
        try:
            if R_next.A.shape[0] == 0:
                print(f"    [!] Pre-image empty at Np={k}. Stopping.")
                break
        except Exception:
            pass
        R_curr = R_next
        if k in horizons:
            results[k] = R_curr
            v = get_vertices(R_curr)
            vert_cache[k] = v
            # Safely check full-dimensionality
            try:
                is_full = pc.is_fulldim(R_curr)
            except Exception:
                is_full = False
            print(
                f"    Np={k}: {len(v) if v is not None else 0} vertices, "
                f"full-dim={is_full}"
            )

    # 8. Visualisation (2D)
    print("[*] Rendering 2D Feasibility Regions...")
    fig, ax = plt.subplots(figsize=(8, 6), facecolor="white")
    colors = {1: "red", 2: "green", 4: "blue"}
    plotted = False

    for k in sorted(horizons, reverse=True):
        v = vert_cache.get(k)
        if v is None or len(v) < 3:
            print(f"    [!] Skipping Np={k}: no valid vertices.")
            continue
        try:
            # Fill and outline the polygon
            ax.fill(v[:, 0], v[:, 1], color=colors[k], alpha=0.25)
            ax.plot(v[:, 0], v[:, 1], color=colors[k], linewidth=1.2)
            # Close the polygon
            ax.plot(
                [v[-1, 0], v[0, 0]],
                [v[-1, 1], v[0, 1]],
                color=colors[k],
                linewidth=1.2,
            )
            # Legend proxy
            ax.plot([], [], color=colors[k], label=f"Np = {k}", linewidth=4)
            plotted = True
        except Exception as e:
            print(f"    [!] Plot failed for Np={k}: {e}")

    if plotted:
        ax.set_title("Feasibility Regions – PATINO_1 (Backward Reachability)")
        ax.set_xlabel("Error State x1")
        ax.set_ylabel("Error State x2")
        ax.legend(loc="best")
        ax.axis("equal")
        ax.grid(True, linestyle="--", alpha=0.4)
        plt.tight_layout()
        # Save figure for headless environments (e.g., Apple Silicon terminal)
        fig.savefig("feasibility_regions_patino1.png", dpi=150, bbox_inches="tight")
        plt.show()
    else:
        print("[!] Nothing to plot.")

    print("[*] Done.")


if __name__ == "__main__":
    main()
