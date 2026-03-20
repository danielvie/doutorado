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


def compute_preimage_halfspace(R_prev, Phi, Gamma, U):
    """
    1-step backward reachable set via the halfspace (dual) method.

    For each halfspace a_i^T y <= b_i of R_prev, the pre-image under
        y = Phi*x + Gamma*u
    is:
        { x | a_i^T Phi*x + min_{u in U} a_i^T Gamma*u <= b_i }

    The inner minimisation is an LP over U. No high-dimensional projection.
    """
    A_R, b_R = R_prev.A, R_prev.b
    A_U, b_U = U.A, U.b
    A_G = A_R @ Gamma  # (n_c, n_u)
    A_Phi = A_R @ Phi  # (n_c, n_x)

    new_rows, new_bs = [], []
    for i in range(A_R.shape[0]):
        # min  (A_G[i]) @ u  s.t.  A_U @ u <= b_U
        res = linprog(A_G[i], A_ub=A_U, b_ub=b_U, bounds=(None, None))
        if res.success:
            offset = res.fun
        else:
            u_verts = get_vertices(U)
            if u_verts is not None and len(u_verts) > 0:
                offset = min(np.dot(A_G[i], v) for v in u_verts)
            else:
                offset = 0.0
        new_rows.append(A_Phi[i])
        new_bs.append(b_R[i] - offset)

    if not new_rows:
        return None
    try:
        P = pc.Polytope(np.array(new_rows), np.array(new_bs))
        return pc.reduce(P) if P.A.shape[0] > 0 else None
    except Exception:
        return None


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

    # 2. Numerical scaling
    u_scale = 1e4
    Gamma_s = Gamma / u_scale
    c_s = c_vec * u_scale
    c_relaxed = np.minimum(c_s, -1e-5 * u_scale)

    # 3. LQR for terminal set
    R_scaled = R_mat / (u_scale**2)
    K, _, _ = dlqr(Phi, Gamma_s, Q_mat, R_scaled)

    # 4. Dwell-time constraint matrix L (p=1 => L = [1; -1])
    L = np.array([[1], [-1]])

    # 5. Compute MAS via iterative invariant-set computation
    print("[*] Computing Maximal Admissible Set (MAS)...")

    # The constraint {x | L*K*x <= -c} is an unbounded strip in 2D.
    # Intersect with a bounding box to get a bounded starting set.
    x_min, x_max = np.array([-0.5, -0.5]), np.array([0.5, 0.5])
    X_box = pc.box2poly(np.column_stack((x_min, x_max)))
    Xf = pc.reduce(X_box.intersect(pc.Polytope(L @ K, -c_relaxed)))
    Phi_cl = Phi - Gamma_s @ K

    mas_ok = False
    for i in range(200):
        X_next = pc.reduce(Xf.intersect(pc.Polytope(Xf.A @ Phi_cl, Xf.b)))
        if Xf.A.shape[0] == X_next.A.shape[0] and np.allclose(
            X_next.b, Xf.b, atol=1e-6
        ):
            Xf = X_next
            print(f"    MAS converged in {i} iterations.")
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
    u_lo = float(c_relaxed[0])
    u_hi = float(-c_relaxed[1])
    U = pc.box2poly(np.array([[u_lo, u_hi]]))  # (1, 2) => 1D interval
    v_u = get_vertices(U)
    print(
        f"    U: {len(v_u) if v_u is not None else 0} vertices, "
        f"bounds=[{u_lo:.4f}, {u_hi:.4f}]"
    )

    # 7. Backward reachability
    horizons = [1, 2, 4]
    results = {}  # horizon -> polytope
    vert_cache = {}  # horizon -> (n_verts, n_dims) array

    R_curr = Xf
    print("[*] Computing Backward Reachable Sets...")
    for k in range(1, max(horizons) + 1):
        R_next = compute_preimage_halfspace(R_curr, Phi, Gamma_s, U)
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
            print(
                f"    Np={k}: {len(v) if v is not None else 0} vertices, "
                f"full-dim={pc.is_fulldim(R_curr)}"
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
