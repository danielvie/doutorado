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

# --- Standard library ---
import argparse
import os
import warnings

# --- Third-party ---
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import polytope as pc
from control import dlqr
from scipy.io import loadmat
from scipy.linalg import toeplitz
from scipy.spatial import ConvexHull

# =============================================================================
# POLYTOPE UTILITIES
# Helper functions for converting and cleaning polytope representations.
# =============================================================================


def normalize_hrep(P):
    """
    Normalize H-rep rows to unit length.
    Removes near-zero rows and redundant constraints for numerical stability.
    """
    if P is None or pc.is_empty(P):
        return None

    A, b = P.A, P.b

    # Compute row norms and keep only rows with non-negligible length
    norms = np.linalg.norm(A, axis=1)
    valid = norms > 1e-12
    if not np.any(valid):
        return None

    # Divide each row by its norm to get unit-length normals
    return pc.reduce(
        pc.Polytope(A[valid] / norms[valid, None], b[valid] / norms[valid])
    )


def vertices_to_hrep(vertices):
    """
    Convert V-rep (list of vertices) to H-rep (A, b) where Ax <= b.
    Uses scipy ConvexHull to extract facet equations from the vertex set.
    """
    if vertices is None or len(vertices) < 4:
        return None, None

    # Add tiny noise to avoid degenerate hulls caused by coplanar points
    eps = 1e-9
    rng = np.random.default_rng(42)
    verts = vertices + rng.uniform(-eps, eps, vertices.shape)

    try:
        hull = ConvexHull(verts)

        # hull.equations rows: [normal_x, ..., normal_n, offset]
        # Convention: normal . x + offset <= 0  =>  normal . x <= -offset
        eqs = hull.equations
        A = eqs[:, :-1]
        b = -eqs[:, -1]
        return A, b
    except Exception:
        return None, None


def robust_qhull(vertices):
    """
    Convert V-rep to H-rep with three fallback levels.

    Attempt 1: pc.qhull()         — native polytope library (fastest).
    Attempt 2: scipy ConvexHull   — more tolerant to near-degenerate inputs.
    Attempt 3: bounding box       — last resort; result may be INFLATED.
    """
    if vertices is None or len(vertices) < 4:
        return None

    # --- Attempt 1: native qhull from the polytope library ---
    try:
        result = pc.qhull(vertices)
        if result is not None and not pc.is_empty(result):
            return result
    except Exception:
        pass

    # --- Attempt 2: manual H-rep via scipy ConvexHull ---
    A, b = vertices_to_hrep(vertices)
    if A is not None and b is not None:
        P = pc.Polytope(A, b)  # type: ignore
        if not pc.is_empty(P):
            return P

    # --- Attempt 3: axis-aligned bounding box (conservative fallback) ---
    try:
        v_min = np.min(vertices, axis=0)
        v_max = np.max(vertices, axis=0)
        margin = 1e-6
        box = pc.box2poly(np.column_stack((v_min - margin, v_max + margin)))

        warnings.warn(
            f"robust_qhull: pc.qhull and scipy.ConvexHull both failed for {len(vertices)} "
            f"vertices in R^{vertices.shape[1]}. "
            "Falling back to bounding box — the feasibility region may be INFLATED "
            "in this iteration. Check whether the vertices are degenerate or coplanar.",
            RuntimeWarning,
            stacklevel=2,
        )
        return box
    except Exception:
        return None


# =============================================================================
# BACKWARD REACHABILITY
# Computes the 1-step pre-image of a polytope R under the system dynamics.
# =============================================================================


def compute_preimage(R_prev, Phi, Gamma, U):
    """
    Compute the 1-step backward reachable set (pre-image) of R_prev.

    Returns the set of states x such that there exists u in U with:
        Phi * x + Gamma * u ∈ R_prev

    Method:
      1. Build a lifted polytope in the joint (x, u) space.
      2. Enumerate its vertices via pc.extreme().
      3. Project the vertices onto the x subspace.
      4. Take the convex hull of the projected vertices.
    """
    n_x = Phi.shape[0]
    A_R, b_R = R_prev.A, R_prev.b
    A_U, b_U = U.A, U.b

    # --- Step 1: Build the lifted polytope in (x, u) space ---
    # Constraints:
    #   A_R * (Phi*x + Gamma*u) <= b_R   (next state must be in R_prev)
    #   A_U * u                 <= b_U   (control must be in U)
    A_lifted = np.block(
        [
            [A_R @ Phi, A_R @ Gamma],
            [np.zeros((A_U.shape[0], n_x)), A_U],
        ]
    )
    b_lifted = np.concatenate([b_R, b_U])

    try:
        P_lu = pc.Polytope(A_lifted, b_lifted)

        # --- Step 2: Enumerate vertices of the lifted polytope ---
        verts = pc.extreme(P_lu)
        if verts is None or len(verts) == 0:
            return None

        # --- Step 3: Project vertices onto x coordinates (drop u columns) ---
        x_verts = verts[:, :n_x]

        # --- Step 4: Compute convex hull of projected x-vertices ---
        if len(x_verts) < 3:
            # Too few points — return a bounding box as a safe fallback
            x_min = np.min(x_verts, axis=0) if len(x_verts) > 0 else np.zeros(n_x)
            x_max = np.max(x_verts, axis=0) if len(x_verts) > 0 else np.zeros(n_x)
            return pc.box2poly(np.column_stack((x_min, x_max)))

        try:
            hull = ConvexHull(x_verts)
            hull_verts = x_verts[hull.vertices]
            R = pc.qhull(hull_verts)
            return normalize_hrep(R)
        except Exception:
            # Convex hull failed — return bounding box of projected vertices
            x_min = np.min(x_verts, axis=0)
            x_max = np.max(x_verts, axis=0)
            return pc.box2poly(np.column_stack((x_min, x_max)))

    except Exception as e:
        print(f"    [!] Pre-image computation failed: {e}")
        return None


# =============================================================================
# DATA LOADING
# Loads system matrices from a .mat file or falls back to a built-in template.
# =============================================================================


def load_data(path="data_patino_2.mat"):
    """
    Load system matrices (Phi, Gamma, c, Q, R) from a .mat file.
    Searches multiple candidate paths before falling back to a default template.
    """
    # Search candidate paths to handle different working directories and naming conventions
    search_paths = [
        path,
        "data_patino2.mat",
        os.path.join("python", path),
        os.path.join("python", "data_patino2.mat"),
    ]

    for p in search_paths:
        if os.path.exists(p):
            print(f"[*] Loading system data from: {p}")
            try:
                data = loadmat(p)
                Phi = data["Phi"]
                Gamma = data["Gamma"]
                c = data["c"].flatten()

                # Q and R default to identity if not provided in the file
                Q = data.get("Q", np.eye(Phi.shape[0]))
                R = data.get("R", np.eye(Gamma.shape[1]))
                return Phi, Gamma, c, Q, R
            except Exception as e:
                print(f"[!] Error loading .mat file: {e}")

    # --- Fallback: built-in PATINO_2 template (3 states, 8 inputs) ---
    print("[!] No .mat file found. Using default PATINO_2 template.")
    n, p = 3, 8
    Phi = np.array(
        [
            [0.992, 0.005, 0.001],
            [0.001, 0.985, 0.008],
            [0.005, 0.002, 0.970],
        ]
    )
    Gamma = np.zeros((n, p))
    for i in range(p):
        Gamma[:, i] = np.array([0.0012, 0.0025, 0.0018]) * (1.0 + 0.1 * i)
    c = np.ones(p + 1) * 1.5e-4

    return Phi, Gamma, c, np.eye(n), np.eye(p)


# =============================================================================
# MAIN PIPELINE
# Orchestrates all stages: load → scale → LQR → MAS → backward reachability → plot.
# =============================================================================


def main():
    parser = argparse.ArgumentParser(
        description="Compute feasibility regions for PATINO_2"
    )
    parser.add_argument(
        "--save-only", action="store_true", help="Save figure without displaying"
    )
    args = parser.parse_args()

    # Use non-interactive backend when running headless (no display needed)
    if args.save_only:
        matplotlib.use("Agg")

    # -------------------------------------------------------------------------
    # Stage 1 — Load system matrices
    # Phi: state transition matrix  |  Gamma: input matrix  |  c: switching limits
    # -------------------------------------------------------------------------
    Phi, Gamma, c, Q_mat, R_mat = load_data()
    _n, p = Phi.shape[0], Gamma.shape[1]

    # -------------------------------------------------------------------------
    # Stage 2 — Numerical scaling
    # Gamma entries are O(1e-3); scaling keeps all quantities near O(1)
    # to avoid ill-conditioning in the polytope computations.
    # -------------------------------------------------------------------------
    u_scale = 1e4
    Gamma_s = Gamma / u_scale  # scaled input matrix
    c_s = c * u_scale  # scaled constraint limits
    c_relaxed = np.minimum(c_s, -1e-5 * u_scale)  # enforce strictly negative bounds

    # -------------------------------------------------------------------------
    # Stage 3 — LQR gain computation
    # K is used only to define the terminal set (closed-loop stability region).
    # The closed-loop dynamics become: x[k+1] = Phi_cl * x[k], Phi_cl = Phi - Gamma*K
    # -------------------------------------------------------------------------
    Q = Q_mat
    R = R_mat / (u_scale**2)  # scale R to match the scaled input
    K, _, _ = dlqr(Phi, Gamma_s, Q, R)
    Phi_cl = Phi - Gamma_s @ K  # closed-loop state matrix

    # -------------------------------------------------------------------------
    # Stage 4 — Dwell-time constraint matrix L
    # L encodes that consecutive switching inputs must satisfy a minimum dwell time.
    # Built as a Toeplitz matrix: rows enforce u[k] - u[k-1] within bounds.
    # -------------------------------------------------------------------------
    L = toeplitz(
        np.array([1, -1] + [0] * (p - 1)),
        np.array([1] + [0] * (p - 1)),
    )

    # -------------------------------------------------------------------------
    # Stage 5 — Maximal Admissible Set (MAS)
    # The MAS is the largest set of states x such that the closed-loop trajectory
    # satisfies L*K*x <= c for all future time steps.
    #
    # Algorithm (fixed-point iteration):
    #   Xf ← Xf ∩ { x | Xf contains Phi_cl * x }
    # Converges when Xf stops shrinking (no new constraints are added).
    # -------------------------------------------------------------------------
    print("[*] Stage 5 — Computing Maximal Admissible Set (MAS)...")

    # Initial set: states satisfying the switching constraints under LQR
    Xf = pc.Polytope(L @ K, -c_relaxed)

    mas_converged = False
    for i in range(100):
        # One-step forward image of Xf under Phi_cl, intersected back with Xf
        X_next = pc.reduce(Xf.intersect(pc.Polytope(Xf.A @ Phi_cl, Xf.b)))

        if pc.is_empty(X_next):
            print("[!] MAS became empty during iteration.")
            break

        # Convergence check: same number of constraints and same b-vector
        if X_next.A.shape[0] == Xf.A.shape[0] and np.allclose(
            X_next.b, Xf.b, atol=1e-6
        ):
            Xf = X_next
            print(f"    MAS converged after {i} iteration(s).")
            mas_converged = True
            break

        Xf = X_next

    if not mas_converged:
        print("[!] MAS did not converge within 100 iterations.")

    if pc.is_empty(Xf):
        print("[!] MAS is empty — check constraints and scaling.")
        return

    # -------------------------------------------------------------------------
    # Stage 6 — Backward reachability
    # Starting from the MAS (terminal safe set), iteratively compute which states
    # can reach it in Np steps by applying some admissible control u ∈ U.
    #
    #   R_0 = MAS
    #   R_k = Pre(R_{k-1}) = { x | ∃ u ∈ U : Phi*x + Gamma*u ∈ R_{k-1} }
    # -------------------------------------------------------------------------
    print("[*] Stage 6 — Computing Backward Reachable Sets...")

    # Build the admissible control set U = { u | -L*u <= -c_relaxed }
    U = pc.Polytope(-L, -c_relaxed)
    u_verts = pc.extreme(U)
    if u_verts is None or len(u_verts) < 1:
        print("[!] Cannot enumerate vertices of U.")
        return

    # Compute the image of U under -Gamma_s to verify non-degeneracy
    V_verts = np.array([-Gamma_s @ u for u in u_verts])

    # Add tiny noise to V_verts to break potential degeneracy in 3D
    eps = 1e-7
    rng = np.random.default_rng(99)
    V_verts_noisy = V_verts + rng.uniform(-eps, eps, V_verts.shape)

    V_poly = robust_qhull(V_verts_noisy)
    if V_poly is None or pc.is_empty(V_poly):
        print("[!] Control set V is empty or invalid.")
        return

    print(
        f"    V: {len(V_verts)} verts, full-dim={pc.is_fulldim(V_poly)} | "
        f"U: {len(u_verts)} verts, full-dim={pc.is_fulldim(U)}"
    )

    # Horizons at which the reachable set will be saved and plotted
    horizons = [1, 2, 4]
    results = {}
    R_curr = Xf  # start backward iteration from the MAS

    for k in range(1, max(horizons) + 1):
        print(f"    - Horizon Np={k}...")

        # A non-full-dimensional set cannot be projected reliably
        if not pc.is_fulldim(R_curr):
            print(f"      [!] R_curr is not full-dimensional at step {k}. Stopping.")
            break

        # Compute the 1-step pre-image of the current reachable set
        R_next = compute_preimage(R_curr, Phi, Gamma_s, U)

        if R_next is None or pc.is_empty(R_next):
            print(f"      [!] Pre-image is empty at Np={k}. Stopping.")
            break

        R_curr = R_next

        # Save the result at the requested horizon steps
        if k in horizons:
            results[k] = R_curr
            v_count = (
                pc.extreme(R_curr).shape[0] if pc.extreme(R_curr) is not None else 0
            )
            print(f"      Np={k}: {v_count} vertices, full-dim={pc.is_fulldim(R_curr)}")

    # -------------------------------------------------------------------------
    # Stage 7 — 3D Visualization
    # Renders each feasibility region as a translucent convex hull surface.
    # Larger horizons produce larger regions (more time to reach the MAS).
    # -------------------------------------------------------------------------
    print("[*] Stage 7 — Rendering 3D Feasibility Regions...")

    # Compute axis bounds across all plotted horizons for axis labels
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
            x1_min = min(x1_min, np.min(v[:, 0]))
            x1_max = max(x1_max, np.max(v[:, 0]))
            x2_min = min(x2_min, np.min(v[:, 1]))
            x2_max = max(x2_max, np.max(v[:, 1]))
            x3_min = min(x3_min, np.min(v[:, 2]))
            x3_max = max(x3_max, np.max(v[:, 2]))

    # Color map: red = Np=1 (smallest), green = Np=2, blue = Np=4 (largest)
    colors = {1: "red", 2: "green", 4: "blue"}

    fig = plt.figure(figsize=(10, 8), facecolor="white")
    ax = fig.add_subplot(111, projection="3d")
    plotted = False

    # Plot largest horizon first so smaller ones are visible on top
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
                    f"    [!] Skipping Np={k}: not enough vertices ({len(v) if v is not None else 0})."
                )
                continue

            # Triangulate the convex hull surface for 3D rendering
            hull = ConvexHull(v)
            ax.plot_trisurf(
                v[:, 0],
                v[:, 1],
                v[:, 2],
                triangles=hull.simplices,
                color=colors[k],
                alpha=0.2,
                edgecolor="black",
                linewidth=0.3,
            )

            # Dummy line for legend entry
            ax.plot(
                [], [], [], color=colors[k], label=f"Np = {k}", alpha=0.6, linewidth=6
            )
            plotted = True

        except Exception as e:
            print(f"    [!] Plotting failed for Np={k}: {e}")

    if plotted:
        ax.set_title("Feasibility Regions for PATINO_2 (Backward Reachability)")
        ax.set_xlabel(f"Error State x1 [{x1_min:.2f}, {x1_max:.2f}]")
        ax.set_ylabel(f"Error State x2 [{x2_min:.2f}, {x2_max:.2f}]")
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
