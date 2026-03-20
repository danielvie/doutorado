"""
Feasibility Region Computation for INTEGRADOR_DUPLO - Apple Silicon / macOS Alternative
--------------------------------------------------------------------------------------
Replicates the MPT3 backward-reachability analysis for INTEGRADOR_DUPLO
(n=2 state dimensions, p=3 inputs) in pure Python.

Usage:
    # Run with display
    uv run --project python python/project_integrador_duplo.py

    # Save only (no display, for headless/CI environments)
    uv run --project python python/project_integrador_duplo.py --save-only

    # Specify custom output path
    uv run --project python python/project_integrador_duplo.py --output my_plot.png
"""

import argparse
import os
import sys

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import polytope as pc
from control import dlqr
from scipy.io import loadmat
from scipy.linalg import toeplitz
from scipy.optimize import linprog
from scipy.spatial import ConvexHull

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def normalize_hrep(P):
    """Normalize H-rep rows to unit length for numerical stability."""
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

    try:
        # Create the lifted polytope
        P_lu = pc.Polytope(A_lifted, b_lifted)

        # Project onto x coordinates (first n_x dimensions)
        # We do this by computing the projection polytope
        # Projection of P onto x: {x | exists u such that (x,u) in P}

        # Method: eliminate u variables using Fourier-Motzkin elimination
        # or use pc.projection if available

        # Try using polytope's project method
        if hasattr(pc, "project"):
            R = pc.project(P_lu, range(n_x))
            return normalize_hrep(R)

        # Alternative: use vertex-based projection
        verts = pc.extreme(P_lu)
        if verts is None or len(verts) == 0:
            return None

        # Project vertices onto x coordinates
        x_verts = verts[:, :n_x]

        # Compute convex hull of projected vertices
        if len(x_verts) < 3:
            # Not enough vertices for a 2D polytope
            # Return bounding box approximation
            x_min = np.min(x_verts, axis=0) if len(x_verts) > 0 else np.zeros(n_x)
            x_max = np.max(x_verts, axis=0) if len(x_verts) > 0 else np.zeros(n_x)
            return pc.box2poly(np.column_stack((x_min, x_max)))

        # Use qhull to compute convex hull
        try:
            from scipy.spatial import ConvexHull

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


def load_data(path="data_integrador_duplo.mat"):
    """
    Load system matrices from a .mat file or fall back to template.
    """
    search_paths = [
        path,
        "integrador_duplo_data.mat",
        "intduplo_data.mat",
        os.path.join("python", path),
        os.path.join("python", "integrador_duplo_data.mat"),
        os.path.join("python", "intduplo_data.mat"),
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
                R = data.get("R", np.eye(Gamma.shape[1]))
                print(f"    Loaded: Phi shape={Phi.shape}, Gamma shape={Gamma.shape}")
                print(f"    Phi eigenvalues: {np.linalg.eigvals(Phi)}")
                return Phi, Gamma, c, Q, R
            except Exception as e:
                print(f"[!] Error loading .mat file: {e}")

    print("[!] No .mat file found. Using representative INTEGRADOR_DUPLO template.")
    # Template: discrete-time double integrator
    Ts = 0.01
    Phi = np.array([[1, Ts], [0, 1]])
    Gamma = np.array([[0.0001, 0.0002, 0.0001], [0.01, 0.01, 0.01]])
    c = np.array([0.01, 0.01, 0.01, 0.01])
    Q = np.eye(2)
    R = np.eye(3)
    print(f"    Template: Phi shape={Phi.shape}, Gamma shape={Gamma.shape}")
    return Phi, Gamma, c, Q, R


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Compute feasibility regions for INTEGRADOR_DUPLO"
    )
    parser.add_argument(
        "--show", action="store_true", help="Display figure (default: save only)"
    )
    parser.add_argument(
        "--output",
        default="feasibility_regions_integrador_duplo.png",
        help="Output filename",
    )
    args = parser.parse_args()

    # Configure matplotlib for headless by default
    if not args.show:
        matplotlib.use("Agg")

    # 1. Load data
    print("[*] Loading system data...")
    Phi, Gamma, c_vec, Q_mat, R_mat = load_data()
    n, p = Phi.shape[0], Gamma.shape[1]
    print(f"    System dimensions: n={n}, p={p}")

    # 2. Control design (NO scaling for INTEGRADOR_DUPLO - unlike PATINO_2)
    print("[*] Computing LQR gain...")
    K, _, _ = dlqr(Phi, Gamma, Q_mat, R_mat)
    # Use original constraints (no scaling needed)
    c_relaxed = c_vec
    print(f"    K shape: {K.shape}")
    print(f"    K values: {K}")

    # 3. Dwell-time constraint matrix L
    first_col = np.zeros(p + 1)
    first_col[0], first_col[1] = 1, -1
    first_row = np.zeros(p)
    first_row[0] = 1
    L = toeplitz(first_col, first_row)
    print(f"    L matrix shape: {L.shape}")
    print(f"    L:\n{L}")

    # 4. Compute MAS
    print("[*] Computing Maximal Admissible Set (MAS)...")

    # Initial constraint: L*K*x <= -c (from u = -K*x satisfying dwell-time constraints)
    # This defines the region where the LQR control law is admissible
    Xf = pc.Polytope(L @ K, -c_relaxed)
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
            print(f"[!] MAS became empty at iteration {i}")
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

        # Debug: print range every 10 iterations
        if i % 10 == 0:
            try:
                v_curr = pc.extreme(Xf)
                if v_curr is not None and len(v_curr) > 0:
                    x1_min, x1_max = np.min(v_curr[:, 0]), np.max(v_curr[:, 0])
                    x2_min, x2_max = np.min(v_curr[:, 1]), np.max(v_curr[:, 1])
                    print(
                        f"    Iter {i}: x1=[{x1_min:.2f}, {x1_max:.2f}], x2=[{x2_min:.2f}, {x2_max:.2f}]"
                    )
            except Exception as e:
                print(f"    Iter {i}: could not get vertices ({e})")

    if not mas_ok:
        print("[!] MAS did not converge – using current approximation.")

    # Debug: final MAS
    try:
        v_final = pc.extreme(Xf)
        if v_final is not None:
            print(
                f"    Final MAS: x1=[{np.min(v_final[:, 0]):.2f}, {np.max(v_final[:, 0]):.2f}], "
                f"x2=[{np.min(v_final[:, 1]):.2f}, {np.max(v_final[:, 1]):.2f}]"
            )
    except Exception as e:
        print(f"    Final MAS: could not get vertices ({e})")

    # 5. Input constraint polytope
    U = pc.Polytope(-L, -c_relaxed)
    print(f"    Input polytope U: {U.A.shape[0]} halfspaces")

    # 6. Backward reachability
    print("[*] Computing Backward Reachable Sets...")
    horizons = [1, 2, 4]
    vert_cache = {}

    R_curr = Xf
    for k in range(1, max(horizons) + 1):
        print(f"    Computing step {k}...")
        R_next = compute_preimage_halfspace(R_curr, Phi, Gamma, U)

        if R_next is None:
            print(f"    [!] Pre-image failed at step {k}")
            break

        if pc.is_empty(R_next):
            print(f"    [!] Pre-image is empty at step {k}")
            break

        R_curr = normalize_hrep(R_next)

        if k in horizons:
            try:
                v = pc.extreme(R_curr)
                vert_cache[k] = v
                if v is not None:
                    x1_range = [np.min(v[:, 0]), np.max(v[:, 0])]
                    x2_range = [np.min(v[:, 1]), np.max(v[:, 1])]
                    print(
                        f"    Np={k}: vertices={len(v)}, x1=[{x1_range[0]:.2f}, {x1_range[1]:.2f}], "
                        f"x2=[{x2_range[0]:.2f}, {x2_range[1]:.2f}]"
                    )
            except Exception as e:
                print(f"    Np={k}: could not get vertices ({e})")

    # 7. Visualization
    print("[*] Rendering...")
    fig, ax = plt.subplots(figsize=(10, 8), facecolor="white")
    colors = {1: "red", 2: "green", 4: "blue"}
    plotted = False

    for k in sorted(horizons, reverse=True):
        v = vert_cache.get(k)
        if v is None or len(v) < 3:
            print(f"    [!] Skipping Np={k}: no valid vertices.")
            continue

        try:
            # Sort vertices for proper polygon
            centroid = np.mean(v, axis=0)
            angles = np.arctan2(v[:, 1] - centroid[1], v[:, 0] - centroid[0])
            v_sorted = v[np.argsort(angles)]

            # Fill polygon
            ax.fill(
                v_sorted[:, 0],
                v_sorted[:, 1],
                color=colors[k],
                alpha=0.3,
                label=f"Np = {k}",
            )
            # Outline
            ax.plot(
                np.append(v_sorted[:, 0], v_sorted[0, 0]),
                np.append(v_sorted[:, 1], v_sorted[0, 1]),
                color=colors[k],
                linewidth=2,
            )
            plotted = True
        except Exception as e:
            print(f"    [!] Plot failed for Np={k}: {e}")

    if plotted:
        ax.set_title("Feasibility Regions – INTEGRADOR_DUPLO (Backward Reachability)")
        ax.set_xlabel("Error State x1")
        ax.set_ylabel("Error State x2")
        ax.legend(loc="best")
        # ax.axis("equal")  # Critical for correct aspect ratio
        ax.grid(True, linestyle="--", alpha=0.4)
        plt.tight_layout()

        # Save figure
        fig.savefig(args.output, dpi=150, bbox_inches="tight")
        print(f"[*] Figure saved to: {args.output}")

        if args.show:
            plt.show()
    else:
        print("[!] Nothing to plot.")

    print("[*] Done.")


if __name__ == "__main__":
    main()
