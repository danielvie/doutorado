"""Common-P Lyapunov optimization for two fixed discrete-time matrices.

Usage: certificate = solve_common_lyapunov(A0, A1)
Both matrices must describe physical errors in the same coordinate system.
This module does not construct the plant, design feedback, or write files.
"""

from dataclasses import dataclass

import cvxpy as cp
import numpy as np
from numpy.typing import NDArray
from scipy.linalg import eigvalsh

Matrix = NDArray[np.float64]


@dataclass
class Certificate:
    """Common quadratic energy and independently checked endpoint residuals."""

    P: Matrix
    residuals: list[Matrix]  # Q_i = P - A_i.T @ P @ A_i
    eigenvalues_P: Matrix
    eigenvalues_residuals: list[Matrix]
    minimum_decrease: float
    eta: float
    rate_bound: float
    status: str


def solve_common_lyapunov(A0: Matrix, A1: Matrix) -> Certificate:
    """Maximize eta with P - A_i.T P A_i >= eta I at both endpoints.

    trace(P) fixes the arbitrary scale. The constraints are affine in P
    because A0 and A1, including any feedback gain, are already fixed.
    """
    state_count = A0.shape[0]
    identity = np.eye(state_count)
    P_variable = cp.Variable((state_count, state_count), symmetric=True)
    eta = cp.Variable()

    constraints = [
        cp.trace(P_variable) == state_count,
        P_variable >> 1e-7 * identity,
        P_variable - A0.T @ P_variable @ A0 >> eta * identity,
        P_variable - A1.T @ P_variable @ A1 >> eta * identity,
    ]
    problem = cp.Problem(cp.Maximize(eta), constraints)
    problem.solve(
        solver="CLARABEL",
        tol_gap_abs=1e-11,
        tol_feas=1e-11,
        tol_gap_rel=1e-11,
        max_iter=300,
    )
    if problem.status not in (cp.OPTIMAL, cp.OPTIMAL_INACCURATE):
        raise RuntimeError(f"No certificate returned: {problem.status}")
    if P_variable.value is None or eta.value is None:
        raise RuntimeError("Solver returned no values for P or eta")

    # Check the returned numerical matrices, not only the solver's status.
    P = (P_variable.value + P_variable.value.T) / 2
    residuals = [P - A.T @ P @ A for A in (A0, A1)]
    eigenvalues_P = eigvalsh(P)
    eigenvalues_residuals = [eigvalsh(Q) for Q in residuals]
    minimum_decrease = min(values[0] for values in eigenvalues_residuals)
    if not (eigenvalues_P[0] > 0 and minimum_decrease > 1e-9):
        raise RuntimeError("Solver output failed independent positivity checks")

    rate_bound = float(np.sqrt(1 - minimum_decrease / eigenvalues_P[-1]))
    return Certificate(
        P=P,
        residuals=residuals,
        eigenvalues_P=eigenvalues_P,
        eigenvalues_residuals=eigenvalues_residuals,
        minimum_decrease=float(minimum_decrease),
        eta=float(eta.value),
        rate_bound=rate_bound,
        status=problem.status,
    )
