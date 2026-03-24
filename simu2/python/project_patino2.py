"""
Feasibility Region Computation - Apple Silicon / macOS Alternative
------------------------------------------------------------------
This script replicates MPT3's backward reachability analysis in Python.
It is designed to be used when MATLAB's MPT3 toolbox is unavailable (e.g., ARM Macs).

How to use with your research data:
1. In MATLAB, run your simulation setup and export the system matrices:
   >> [Phi, Gamma] = s.get_phi_gamma();
   >> c = s.get_switching_constraints();
   >> save('data_patino2.mat', 'Phi', 'Gamma', 'c');
2. Place 'data_patino2.mat' in the same directory as this script.
3. Run this script using uv:
   >> uv run --project python python python/project_patino2.py
"""

import argparse
import os

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import polytope as pc
from control import dlqr
from scipy.io import loadmat
from scipy.linalg import toeplitz
from scipy.spatial import ConvexHull


def normalize_hrep(P):
    """Normalize H-representation rows to unit length for numerical stability."""
    if P is None or pc.is_empty(P):
        return None
    A, b = P.A, P.b
    norms = np.linalg.norm(A, axis=1)
    valid = norms > 1e-12
    if not np.any(valid):
        return None
    return pc.reduce(
        pc.Polytope(A[valid] / norms[valid, None], b[valid] / norms[valid])
    )


def vertices_to_hrep(vertices):
    """
    Convert a set of vertices to H-representation (A, b) where Ax <= b.
    Uses scipy ConvexHull and computes halfspaces from facet normals.
    """
    if vertices is None:
        return None, None
    n_pts = len(vertices)
    if n_pts < 4:
        return None, None

    # Add tiny noise to avoid degenerate hulls (e.g., coplanar points)
    eps = 1e-9
    rng = np.random.default_rng(42)
    verts = vertices + rng.uniform(-eps, eps, vertices.shape)

    try:
        hull = ConvexHull(verts)
        # equations: [normal_x, normal_y, normal_z, offset]
        # such that normal . x + offset <= 0  =>  normal . x <= -offset
        eqs = hull.equations
        A = eqs[:, :-1]
        b = -eqs[:, -1]
        return A, b
    except Exception:
        return None, None


def robust_qhull(vertices):
    """
    Wrapper around pc.qhull that handles degenerate cases.
    If qhull fails or returns empty, falls back to manual facet
    computation via scipy ConvexHull + halfspace intersection.
    """
    if vertices is None:
        return None
    n_pts = len(vertices)
    if n_pts < 4:
        return None

    # Try polytope's qhull first
    try:
        result = pc.qhull(vertices)
        if result is not None and not pc.is_empty(result):
            return result
    except Exception:
        pass

    # Fallback: compute H-rep from V-rep manually
    A, b = vertices_to_hrep(vertices)
    if A is not None and b is not None:
        P = pc.Polytope(A, b)  # type: ignore
        if not pc.is_empty(P):
            return P

    # Second fallback: build a bounding box around the vertices and intersect
    # with a small inward offset to guarantee a non-empty bounded polytope
    try:
        v_min = np.min(vertices, axis=0)
        v_max = np.max(vertices, axis=0)
        margin = 1e-6
        box = pc.box2poly(np.column_stack((v_min - margin, v_max + margin)))
        return box
    except Exception:
        return None


def compute_preimage_projection(R_prev, Phi, Gamma, U):
    """
    1-step backward reachable set via projection method.

    Computes the set of states x such that there exists u in U where
    Phi*x + Gamma*u ∈ R_prev.

    This is done by forming the lifted polytope in (x, u) space and projecting
    onto the x coordinates, which is the correct method (used by MPT3).
    """
    n_x = Phi.shape[0]
    # n_u = Gamma.shape[1]

    A_R, b_R = R_prev.A, R_prev.b
    A_U, b_U = U.A, U.b

    # Form the lifted polytope P_lu = {(x, u) | Phi*x + Gamma*u ∈ R_prev, u ∈ U}
    A_lifted = np.block(
        [
            [A_R @ Phi, A_R @ Gamma],  # Dynamics constraint
            [np.zeros((A_U.shape[0], n_x)), A_U],  # Input constraint
        ]
    )
    b_lifted = np.concatenate([b_R, b_U])

    try:
        # Create the lifted polytope
        if b_lifted is None:
            return None
        P_lu = pc.Polytope(A_lifted, b_lifted)

        # Project onto x coordinates (first n_x dimensions)
        verts = pc.extreme(P_lu)
        if verts is None or len(verts) == 0:
            return None

        # Project vertices onto x coordinates
        x_verts = verts[:, :n_x]

        # Compute convex hull of projected vertices
        if len(x_verts) < 3:
            x_min = np.min(x_verts, axis=0) if len(x_verts) > 0 else np.zeros(n_x)
            x_max = np.max(x_verts, axis=0) if len(x_verts) > 0 else np.zeros(n_x)
            return pc.box2poly(np.column_stack((x_min, x_max)))

        try:
            hull = ConvexHull(x_verts)
            hull_verts = x_verts[hull.vertices]
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


def compute_preimage_halfspace(R_prev, Phi, Gamma, U):
    """Backward compatible wrapper that uses projection method."""
    return compute_preimage_projection(R_prev, Phi, Gamma, U)


def load_data(path="data_patino_2.mat"):
    """Loads system matrices from a .mat file or falls back to a template."""
    # Check multiple paths for both old and new naming conventions
    search_paths = [
        path,
        "data_patino2.mat",  # old naming convention
        os.path.join("python", path),
        os.path.join("python", "data_patino2.mat"),
    ]

    for p in search_paths:
        if os.path.exists(p):
            print(f"[*] Loading real system data from {p}...")
            try:
                data = loadmat(p)
                Phi = data["Phi"]
                Gamma = data["Gamma"]
                c = data["c"].flatten()
                Q = data.get("Q", np.eye(Phi.shape[0]))
                p_cols = Gamma.shape[1]
                R = data.get("R", np.eye(p_cols))
                return Phi, Gamma, c, Q, R
            except Exception as e:
                print(f"[!] Error loading .mat file: {e}")

    print("[!] No .mat file found. Using default PATINO_2 template.")
    n, p = 3, 8
    Phi = np.array(
        [[0.992, 0.005, 0.001], [0.001, 0.985, 0.008], [0.005, 0.002, 0.970]]
    )
    Gamma = np.zeros((n, p))
    for i in range(p):
        Gamma[:, i] = np.array([0.0012, 0.0025, 0.0018]) * (1.0 + 0.1 * i)
    c = np.ones(p + 1) * 1.5e-4
    return Phi, Gamma, c, np.eye(n), np.eye(p)


def main():
    parser = argparse.ArgumentParser(
        description="Compute feasibility regions for PATINO_2"
    )
    parser.add_argument(
        "--save-only", action="store_true", help="Save figure without displaying"
    )
    args = parser.parse_args()

    # Use Agg backend only when --save-only is specified
    if args.save_only:
        matplotlib.use("Agg")

    # 1. Load system data
    Phi, Gamma, c, Q_mat, R_mat = load_data()
    _n, p = Phi.shape[0], Gamma.shape[1]

    # 2. Numerical scaling
    u_scale = 1e4
    Gamma_s = Gamma / u_scale
    c_s = c * u_scale
    c_relaxed = np.minimum(c_s, -1e-5 * u_scale)

    # 3. LQR for terminal set
    Q = Q_mat
    R = R_mat / (u_scale**2)
    K, _, _ = dlqr(Phi, Gamma_s, Q, R)

    # 4. Dwell-time constraint matrix L
    L = toeplitz(np.array([1, -1] + [0] * (p - 1)), np.array([1] + [0] * (p - 1)))

    # 5. Compute MAS
    print("[*] Computing Maximal Admissible Set (MAS)...")
    Xf = pc.Polytope(L @ K, -c_relaxed)
    Phi_cl = Phi - Gamma_s @ K
    mas_converged = False
    for i in range(100):
        X_next = pc.reduce(Xf.intersect(pc.Polytope(Xf.A @ Phi_cl, Xf.b)))
        if pc.is_empty(X_next):
            print("[!] MAS became empty during iteration.")
            break
        if X_next.A.shape[0] == Xf.A.shape[0] and np.allclose(
            X_next.b, Xf.b, atol=1e-6
        ):
            Xf = X_next
            print(f"    MAS converged in {i} steps.")
            mas_converged = True
            break
        Xf = X_next

    if not mas_converged:
        print("[!] MAS did not converge in 100 iterations.")

    if pc.is_empty(Xf):
        print("[!] MAS is empty. Check constraints/scaling.")
        return

    # 6. Backward reachability
    print("[*] Computing Backward Reachable Sets...")

    # U = { u | -L*u <= -c_relaxed }
    U = pc.Polytope(-L, -c_relaxed)
    u_verts = pc.extreme(U)
    if u_verts is None or len(u_verts) < 1:
        print("[!] Cannot enumerate vertices of U.")
        return

    # V = { -Gamma_s * u | u in U }
    V_verts = np.array([-Gamma_s @ u for u in u_verts])

    # Add tiny identity-noise to V_verts to break degeneracy in 3D
    eps = 1e-7
    rng = np.random.default_rng(99)
    V_verts_noisy = V_verts + rng.uniform(-eps, eps, V_verts.shape)

    V_poly = robust_qhull(V_verts_noisy)
    if V_poly is None or pc.is_empty(V_poly):
        print("[!] Control set V is empty or invalid.")
        return
    print(
        f"    V: {len(V_verts)} verts, full-dim={pc.is_fulldim(V_poly)}, "
        f"U: {len(u_verts)} verts, full-dim={pc.is_fulldim(U)}"
    )

    horizons = [1, 2, 4]
    results = {}
    R_curr = Xf

    for k in range(1, max(horizons) + 1):
        print(f"    - Horizon Np={k}...")

        # Check if R_curr is full-dimensional
        if not pc.is_fulldim(R_curr):
            print(f"      [!] R_curr is not full-dimensional at step {k}. Skipping.")
            break

        # Compute 1-step backward reachable set via projection
        R_next = compute_preimage_halfspace(R_curr, Phi, Gamma_s, U)

        if R_next is None or pc.is_empty(R_next):
            print(f"      [!] Pre-image is empty at Np={k}. Stopping.")
            break

        R_curr = R_next

        if k in horizons:
            results[k] = R_curr
            v_count = (
                pc.extreme(R_curr).shape[0] if pc.extreme(R_curr) is not None else 0
            )
            print(f"      Np={k}: {v_count} vertices, full-dim={pc.is_fulldim(R_curr)}")

    # 7. Visualization (3D only with min/max labels)
    print("[*] Rendering 3D Feasibility Regions...")

    # Compute min/max values for each state variable
    x1_min, x1_max = float("inf"), float("-inf")
    x2_min, x2_max = float("inf"), float("-inf")
    x3_min, x3_max = float("inf"), float("-inf")

    for k in horizons:
        raw = results.get(k)
        if raw is None:
            continue
        P = normalize_hrep(raw)
        if P is None:
            continue
        v = pc.extreme(P)
        if v is not None and len(v) > 0:
            x1_min, x1_max = min(x1_min, np.min(v[:, 0])), max(x1_max, np.max(v[:, 0]))
            x2_min, x2_max = min(x2_min, np.min(v[:, 1])), max(x2_max, np.max(v[:, 1]))
            x3_min, x3_max = min(x3_min, np.min(v[:, 2])), max(x3_max, np.max(v[:, 2]))

    colors = {1: "red", 2: "green", 4: "blue"}
    fig = plt.figure(figsize=(10, 8), facecolor="white")
    ax = fig.add_subplot(111, projection="3d")
    plotted = False

    for k in sorted(horizons, reverse=True):
        raw = results.get(k)
        if raw is None:
            continue
        P = normalize_hrep(raw)
        if P is None:
            continue
        try:
            v = pc.extreme(P)
            if v is None or len(v) < 4:
                print(
                    f"    [!] Skipping Np={k}: {len(v) if v is not None else 0} vertices."
                )
                continue
            hull = ConvexHull(v)
            ax.plot_trisurf(
                v[:, 1],  # x2 (swapped)
                v[:, 0],  # x1 (swapped)
                v[:, 2],  # x3
                triangles=hull.simplices,
                color=colors[k],
                alpha=0.2,
                edgecolor="black",
                linewidth=0.3,
            )
            ax.plot(
                [], [], [], color=colors[k], label=f"Np = {k}", alpha=0.6, linewidth=6
            )
            plotted = True
        except Exception as e:
            print(f"    [!] Plotting failed for Np={k}: {e}")

    if plotted:
        ax.set_title("Feasibility Regions for PATINO_2 (Backward Reachability)")
        ax.set_xlabel(f"Error State x2 [{x2_min:.2f}, {x2_max:.2f}]")
        ax.set_ylabel(f"Error State x1 [{x1_min:.2f}, {x1_max:.2f}]")
        ax.set_zlabel(f"Error State x3 [{x3_min:.2f}, {x3_max:.2f}]")
        ax.legend(loc="best")
        ax.view_init(elev=30, azim=45)
        fig.savefig("feasibility_regions_patino2.png", dpi=150, bbox_inches="tight")
        print("[*] Figure saved to: feasibility_regions_patino2.png")

        if not args.save_only:
            plt.show()
    else:
        print("[!] Nothing to plot.")

    print("[*] Done.")


if __name__ == "__main__":
    main()
