"""Offline LMI candidates for the unchanged article cycle model.

CVXPY PSD constraints and solver options follow:
https://www.cvxpy.org/tutorial/constraints/index.html#semidefinite-matrices
https://www.cvxpy.org/tutorial/solvers/index.html#setting-solver-options
"""

import csv
import hashlib
import json
import platform
from importlib.metadata import version
from pathlib import Path

import cvxpy as cp
import numpy as np
from scipy.linalg import eigvalsh, solve_discrete_lyapunov

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUTPUT = HERE / "results"
SOLVER_OPTIONS = dict(
    solver="CLARABEL", tol_gap_abs=1e-9, tol_feas=1e-9,
    tol_gap_rel=1e-9, max_iter=500,
)
RATE_TOLERANCE = 1e-6
OPEN_RATE = 0.99995
INPUT_WEIGHT = 0.001


def symmetric(matrix):
    return (matrix + matrix.T) / 2


def contraction_block(X, G, rate):
    return cp.bmat([[rate * rate * X, G.T], [G, X]])


def check_certificate(A, B, K, P):
    """Recompute the actual gain and endpoint inequalities, not solver status."""
    P = symmetric(P)
    endpoints = (A, A - B @ K)
    decreases = [float(eigvalsh(symmetric(P - M.T @ P @ M))[0]) for M in endpoints]
    minimum_P = float(eigvalsh(P)[0])
    if minimum_P <= 0 or min(decreases) <= 1e-9:
        raise RuntimeError(f"Invalid common-P certificate: {minimum_P=}, {decreases=}")
    return dict(
        K=K, P=P, endpoint_decreases=decreases,
        min_eigenvalue_P=minimum_P,
        raw_radius=float(max(abs(np.linalg.eigvals(endpoints[1])))),
        Pnorm_rates=[float(np.sqrt(eigvalsh(M.T @ P @ M, P)[-1])) for M in endpoints],
        gain_frobenius=float(np.linalg.norm(K)),
        condition_number_P=float(np.linalg.cond(P)),
    )


def solve_decay_at_rate(A, B, rate):
    """The PDF's pure feasibility problem, without a gain-selection tie-break."""
    n, m = B.shape
    X = cp.Variable((n, n), symmetric=True)
    Y = cp.Variable((m, n))
    constraints = [cp.trace(X) == n, X >> 1e-7 * np.eye(n)]
    constraints += [contraction_block(X, G, rate) >> 0 for G in (A @ X, A @ X - B @ Y)]
    problem = cp.Problem(cp.Minimize(0), constraints)
    problem.solve(**SOLVER_OPTIONS)
    record = dict(rate=rate, status=problem.status, accepted=False)
    if problem.status not in (cp.OPTIMAL, cp.OPTIMAL_INACCURATE):
        return None, record
    x = symmetric(X.value)
    if eigvalsh(x)[0] <= 0:
        return None, record
    K = np.linalg.solve(x, Y.value.T).T
    try:
        result = check_certificate(A, B, K, np.linalg.inv(x))
    except RuntimeError:
        return None, record
    P = result["P"]
    residuals = [float(eigvalsh(symmetric(rate * rate * P - M.T @ P @ M))[0])
                 for M in (A, A - B @ K)]
    record.update(min_rate_residual=min(residuals), min_eigenvalue_X=float(eigvalsh(x)[0]))
    if min(residuals) <= 1e-9 or max(result["Pnorm_rates"]) > rate + 1e-10:
        return None, record
    record["accepted"] = True
    result.update(X=x, Y=Y.value, rate=rate, rate_residuals=residuals,
                  solver_status=problem.status, trace_X=float(np.trace(x)))
    return result, record


def synthesize_decay(A, B):
    floor = float(max(abs(np.linalg.eigvals(A))))
    low, high = floor, 1.0 - 1e-8
    best, first = solve_decay_at_rate(A, B, high)
    if best is None:
        raise RuntimeError("Initial decay-rate SDP failed independent checks")
    history = [first]
    while high - low > RATE_TOLERANCE:
        rate = (low + high) / 2
        candidate, record = solve_decay_at_rate(A, B, rate)
        history.append(record)
        if candidate is None:
            low = rate
        else:
            high, best = rate, candidate
    # K=0 is an equally good limiting design. Construct its rate certificate
    # separately so the nonuniqueness is demonstrated rather than hidden.
    zero_P = solve_discrete_lyapunov((A / high).T, np.eye(A.shape[0]))
    zero_X = np.linalg.inv(zero_P)
    zero_P *= np.trace(zero_X) / A.shape[0]
    zero_residual = symmetric(high * high * zero_P - A.T @ zero_P @ A)
    if eigvalsh(zero_P)[0] <= 0 or eigvalsh(zero_residual)[0] <= 0:
        raise RuntimeError("Zero-feedback counterexample certificate failed")
    best.update(
        objective="minimum full-interval contraction; solver-selected feasible gain",
        analytical_rate_floor=floor, bisection_lower=low, bisection_upper=high,
        bisection_tolerance=RATE_TOLERANCE, bisection_history=history,
        zero_gain_same_rate_feasible=True,
        zero_gain_min_rate_residual=float(eigvalsh(zero_residual)[0]),
        gain_selection="CLARABEL pure-feasibility point, no secondary performance objective",
    )
    return best


def synthesize_cost(A, B):
    """Minimize a full-feedback cost bound while retaining the open endpoint."""
    n, m = B.shape
    I = np.eye(n)
    X = cp.Variable((n, n), symmetric=True)
    Y = cp.Variable((m, n))
    W = cp.Variable((n, n), symmetric=True)
    G = A @ X - B @ Y
    z = np.zeros((n, n))
    z_nm = np.zeros((n, m))
    cost_block = cp.bmat([
        [X, G.T, X, np.sqrt(INPUT_WEIGHT) * Y.T],
        [G, X, z, z_nm],
        [X, z, I, z_nm],
        [np.sqrt(INPUT_WEIGHT) * Y, z_nm.T, z_nm.T, np.eye(m)],
    ])
    constraints = [
        X >> 1e-7 * I,
        cp.bmat([[W, I], [I, X]]) >> 0,
        contraction_block(X, A @ X, OPEN_RATE) >> 1e-8 * np.eye(2 * n),
        cost_block >> 0,
    ]
    problem = cp.Problem(cp.Minimize(cp.trace(W)), constraints)
    problem.solve(**SOLVER_OPTIONS)
    if problem.status not in (cp.OPTIMAL, cp.OPTIMAL_INACCURATE) or X.value is None:
        raise RuntimeError(f"Cost synthesis failed: {problem.status}")
    x = symmetric(X.value)
    K = np.linalg.solve(x, Y.value.T).T
    P_solver = symmetric(np.linalg.solve(x, I))
    if abs(float(np.trace(P_solver)) - float(problem.value)) > 1e-5:
        raise RuntimeError("Epigraph objective and recovered Lyapunov trace differ")
    # This changes the reported bound, not K. It gives the cost inequality
    # visible slack rather than relying on a nearly active floating-point LMI.
    inflation = 1.0 + 1e-6
    P = inflation * P_solver
    result = check_certificate(A, B, K, P)
    closed = A - B @ K
    cost_residual = symmetric(P - closed.T @ P @ closed - I - INPUT_WEIGHT * K.T @ K)
    open_residual = symmetric(OPEN_RATE**2 * P - A.T @ P @ A)
    if eigvalsh(cost_residual)[0] <= 0 or eigvalsh(open_residual)[0] <= 0:
        raise RuntimeError("Cost or open-endpoint rate inequality failed independent positivity checks")
    result.update(
        X=x / inflation, Y=Y.value / inflation,
        X_solver=x, Y_solver=Y.value, P_solver=P_solver,
        certificate_inflation=inflation, solver_status=problem.status,
        objective="minimum trace(P) full-feedback guaranteed Q/R cost",
        objective_value=float(problem.value), trace_P=float(np.trace(P)),
        open_rate=OPEN_RATE,
        min_open_rate_residual=float(eigvalsh(open_residual)[0]),
        min_raw_cost_residual=float(eigvalsh(cost_residual)[0]),
        open_block_floor=1e-8,
        cost_scope="unconditioned linearized full-feedback endpoint only",
    )
    return result


def json_value(value):
    if isinstance(value, np.ndarray):
        return value.tolist()
    if isinstance(value, np.generic):
        return value.item()
    raise TypeError(type(value).__name__)


def main():
    source = ROOT / "studies/lyapunov/results/certificate.json"
    saved = json.loads(source.read_text(encoding="utf-8"))
    julia_path = ROOT / "studies/lyapunov/results/lyapunov_analysis_julia_certificate.json"
    julia = json.loads(julia_path.read_text(encoding="utf-8"))
    A, B, K = (np.array(saved[name], dtype=float) for name in ("A0", "B", "K"))
    S = np.array(saved["S"], dtype=float)
    ts = float(saved["ts"])
    if np.linalg.norm(A - B @ K - np.array(saved["A1"])) > 1e-12:
        raise RuntimeError("Saved model and current gain are inconsistent")
    current = check_certificate(A, B, K, np.array(julia["P"], dtype=float))
    decay = synthesize_decay(A, B)
    cost = synthesize_cost(A, B)
    for candidate in (current, decay, cost):
        candidate["Kphysical"] = ts * candidate["K"] @ np.linalg.inv(S)
    sources = [source, julia_path, Path(__file__).resolve(),
               ROOT / "scripts/+paper/benchmark.m", ROOT / "scripts/+paper/design_feedback.m",
               ROOT / "scripts/condition_dwell_times.m",
               ROOT / "studies/mpc-comparison/mpc_problem.m",
               ROOT.parents[2] / "simulations/matlab-sim/+Mpc/build_problem.m",
               ROOT.parents[2] / "simulations/matlab-sim/+Mpc/solve.m"]
    result = dict(
        A=A, B=B, K_current=K, P_current=current["P"], current=current,
        state_scale=S, timing_scale=ts, boundaries_us=saved["boundaries_us"],
        input_weight=INPUT_WEIGHT, candidates=dict(decay=decay, cost=cost),
        solver=dict(interface="CVXPY", solver="CLARABEL", options=SOLVER_OPTIONS,
                    cvxpy=version("cvxpy"), clarabel=version("clarabel"),
                    numpy=version("numpy"), scipy=version("scipy"),
                    python=platform.python_version(), platform=platform.platform()),
        source_sha256={str(path.relative_to(ROOT.parents[2])).replace("\\", "/"):
                       hashlib.sha256(path.read_bytes()).hexdigest() for path in sources},
        limitations=["floating-point certificates, not interval verification",
                     "linearized stability only; no nonlinear attraction or hardware guarantee",
                     "the original objective does not uniquely select a useful gain",
                     "full-feedback cost certificate does not bound conditioned nonlinear cost"],
    )
    OUTPUT.mkdir(exist_ok=True)
    (OUTPUT / "synthesis.json").write_text(
        json.dumps(result, default=json_value, indent=2) + "\n", encoding="utf-8")
    with (OUTPUT / "gains_normalized.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["method", "switching_instant", "k_z1", "k_z2", "k_z3"])
        for name, candidate in (("current", current), ("kawa_decay", decay), ("kawa_cost", cost)):
            for i, row in enumerate(candidate["K"], 1):
                writer.writerow([name, i, *row])
    print(f"Open-loop spectral radius: {decay['analytical_rate_floor']:.12f}")
    print(f"Original rate bracket: [{decay['bisection_lower']:.12f}, {decay['bisection_upper']:.12f}]")
    for name, candidate in (("current", current), ("decay", decay), ("cost", cost)):
        print(f"{name}: raw radius={candidate['raw_radius']:.9f}, "
              f"gain norm={candidate['gain_frobenius']:.6f}, "
              f"endpoint decrease={candidate['endpoint_decreases']}")
    print(f"Saved {OUTPUT / 'synthesis.json'}")


if __name__ == "__main__":
    main()
