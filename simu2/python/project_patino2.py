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

import os

import matplotlib.pyplot as plt
import numpy as np
import polytope as pc
from control import dlqr
from mpl_toolkits.mplot3d import Axes3D
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
    except Exception as e:
        print(f"        ConvexHull failed: {e}")
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
    if A is not None:
        P = pc.Polytope(A, b)
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


def compute_preimage_halfspace(R_prev, Phi, Gamma, U):
    """
    Compute 1-step backward reachable set via the dual halfspace method.

    For each halfspace a_i^T y <= b_i in R_prev, the pre-image under
    x -> Phi*x + Gamma*u is:
        { x | a_i^T Phi*x + min_{u in U} a_i^T Gamma*u <= b_i }

    The inner minimization is a linear program over the polytope U.
    This avoids any high-dimensional projection.

    Returns a new Polyhedron R_pre in the state-space (3D).
    """
    from scipy.optimize import linprog

    A_R, b_R = R_prev.A, R_prev.b
    n_x = Phi.shape[1]
    n_u = Gamma.shape[1]
    n_constraints = A_R.shape[0]

    A_U, b_U = U.A, U.b
    A_G = A_R @ Gamma  # (n_c, n_u)
    A_Phi = A_R @ Phi  # (n_c, n_x)

    new_A_rows = []
    new_b_vals = []

    for i in range(n_constraints):
        # Solve: min  a_G_i^T u  s.t.  A_U @ u <= b_U
        c = A_G[i]
        res = linprog(c, A_ub=A_U, b_ub=b_U, bounds=(None, None))

        if res.success:
            offset = res.fun
        else:
            # Fallback: use worst-case bound from vertices
            u_verts = pc.extreme(U)
            offset = min(np.dot(A_G[i], u) for u in u_verts)

        new_A_rows.append(A_Phi[i])
        new_b_vals.append(b_R[i] - offset)

    if not new_A_rows:
        return None

    A_new = np.array(new_A_rows)
    b_new = np.array(new_b_vals)

    P = pc.Polytope(A_new, b_new)
    if pc.is_empty(P):
        return None
    return pc.reduce(P)


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

    print(f"[!] No .mat file found. Using default PATINO_2 template.")
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
    # 1. Load system data
    Phi, Gamma, c, Q_mat, R_mat = load_data()
    n, p = Phi.shape[0], Gamma.shape[1]

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

    # 7. Visualization
    print("[*] Rendering 3D Feasibility Regions...")
    fig = plt.figure(figsize=(12, 8), facecolor="white")
    ax = fig.add_subplot(111, projection="3d")
    colors = {1: "red", 2: "green", 4: "blue"}

    plotted = False
    for k in sorted(horizons, reverse=True):
        raw = results.get(k)
        if raw is None:
            continue
        # Fast empty check without calling pc.is_empty (which is slow)
        try:
            if not hasattr(raw, "A") or raw.A.size == 0:
                continue
        except Exception:
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
                v[:, 0],
                v[:, 1],
                v[:, 2],
                triangles=hull.simplices,
                color=colors[k],
                alpha=0.15,
                edgecolor="black",
                linewidth=0.3,
            )
            ax.plot([], [], color=colors[k], label=f"Np = {k}", alpha=0.6, linewidth=6)
            plotted = True
        except Exception as e:
            print(f"    [!] Plotting failed for Np={k}: {type(e).__name__}: {e}")

    if plotted:
        ax.set_title("Feasibility Regions (Python / Apple Silicon)")
        ax.set_xlabel("Error State x1")
        ax.set_ylabel("Error State x2")
        ax.set_zlabel("Error State x3")
        ax.legend(loc="best")
        ax.view_init(elev=30, azim=45)
        plt.grid(True)
        fig.savefig("feasibility_regions_patino2.png", dpi=150, bbox_inches="tight")
        plt.show()
    else:
        print("[!] Nothing to plot.")

    print("[*] Done.")


if __name__ == "__main__":
    main()
