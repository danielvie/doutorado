"""Build the physical converter model and its common-P Lyapunov tutorial.

Run from any working directory. Dependencies: numpy, scipy, cvxpy (CLARABEL).
Stored MATLAB results are used only for validation, never to construct the model.

Pipeline:
    physical modes -> augmented cycle -> physical error dynamics -> LQR
    -> common-P SDP -> independent checks -> laboratory data -> offline HTML
"""

import json
from dataclasses import dataclass
from importlib.metadata import version
from pathlib import Path
from typing import Any

import numpy as np
import scipy
from optimization import Certificate, solve_common_lyapunov
from numpy.typing import NDArray
from scipy.io import loadmat
from scipy.linalg import eigvalsh, expm, solve_discrete_are

Matrix = NDArray[np.float64]
STUDY_DIR = Path(__file__).resolve().parents[1]
PAPER_DIR = STUDY_DIR.parents[1]
OUTPUT_DIR = STUDY_DIR / "tutorial"
RESULTS_DIR = STUDY_DIR / "results"
MICROSECOND = 1e-6

# Independently encoded physical parameters and schedule from scripts/+paper/benchmark.m.
SOURCE_VOLTAGE = 30.0
CAPACITANCE_1 = 40e-6
CAPACITANCE_2 = 40e-6
INDUCTANCE = 10e-3
RESISTANCE = 10.0
MODE_SEQUENCE = (0, 1, 3, 7, 2, 0, 4, 7, 4)
BOUNDARIES_US = (
    0.0,
    63.889183506119,
    87.556782881998,
    109.556782881998,
    132.538059851499,
    154.538059851499,
    218.210068109424,
    240.380157440049,
    263.827584831201,
    286.0,
)
ORBIT_ANCHOR = (9.9247, 19.2928, 0.9823)
INITIAL_STATE = (7.5143, 20.8211, 0.0314)
STATE_SCALES = (10.0, 20.0, 1.0)
TIMING_SCALE = 10e-6
MINIMUM_DWELL = 3e-6
LQR_INPUT_WEIGHT = 0.001
SIMULATION_CYCLES = 100
BETA_SWEEP_POINTS = 201


@dataclass
class CycleModel:
    """Physical model and intermediate matrices displayed in the tutorial."""

    anchor: Matrix
    boundaries: Matrix
    dwell: Matrix
    modes: list[dict[str, Any]]
    generators: list[Matrix]  # F_i, augmented 4 x 4 mode generators
    transitions: list[Matrix]  # phi_i = exp(F_i * dwell_i)
    orbit: list[Matrix]  # nominal augmented boundary states
    partial_products: list[Matrix]
    Phi_aug: Matrix  # ordered augmented cycle product, 4 x 4
    Gamma_aug: Matrix  # augmented dwell sensitivities, 4 x N
    projection: Matrix  # Pi: augmented error -> physical error
    embedding: Matrix  # iota: physical error -> augmented error
    dwell_map: Matrix  # D: switching offsets -> dwell changes
    Phi: Matrix  # physical cycle matrix, 3 x 3
    Gd: Matrix  # physical dwell sensitivities, 3 x N
    Gtau: Matrix  # physical switching sensitivities, 3 x (N-1)


@dataclass
class Feedback:
    """The paper's fixed aggressive LQR in normalized coordinates."""

    state_scale: Matrix
    timing_scale: float
    A0: Matrix  # normalized open-loop endpoint, beta = 0
    B: Matrix
    K: Matrix  # normalized timing feedback gain
    Kphysical: Matrix  # seconds per physical state unit
    A1: Matrix  # normalized closed-loop endpoint, beta = 1


# 1. Construct the cycle from circuit equations, then project physical errors.


def build_physical_mode(mode: int) -> tuple[list[int], Matrix, Matrix]:
    """Decode u1 as the most significant bit and construct dx/dt = A*x + b."""
    bits = [(mode >> bit) & 1 for bit in (2, 1, 0)]
    u1, u2, u3 = bits
    A = np.array(
        [
            [0, 0, (u2 - u1) / CAPACITANCE_1],
            [0, 0, (u3 - u2) / CAPACITANCE_2],
            [(u1 - u2) / INDUCTANCE, (u2 - u3) / INDUCTANCE, -RESISTANCE / INDUCTANCE],
        ]
    )
    b = np.array([0, 0, SOURCE_VOLTAGE * u3 / INDUCTANCE])
    return bits, A, b


def build_dwell_map(interval_count: int) -> Matrix:
    """Delaying instant j lengthens dwell j and shortens dwell j+1."""
    D = np.zeros((interval_count, interval_count - 1))
    for j in range(interval_count - 1):
        D[j, j] = 1
        D[j + 1, j] = -1
    return D


def build_cycle_model() -> CycleModel:
    anchor = np.array(ORBIT_ANCHOR)
    boundaries = np.array(BOUNDARIES_US) * MICROSECOND
    dwell = np.diff(boundaries)
    state_count = len(anchor)
    augmented_count = state_count + 1
    interval_count = len(MODE_SEQUENCE)

    generators, transitions, modes = [], [], []
    for mode, duration in zip(MODE_SEQUENCE, dwell):
        bits, A, b = build_physical_mode(mode)
        F = np.zeros((augmented_count, augmented_count))
        F[:state_count, :state_count] = A
        F[:state_count, state_count] = b

        generators.append(F)
        transitions.append(expm(F * duration))
        modes.append(
            {
                "mode": mode,
                "bits": bits,
                "A": A,
                "b": b,
                "F": F,
                "dwell_us": duration * 1e6,
            }
        )

    # The next interval acts on the left: Phi_aug = phi_N ... phi_1.
    orbit = [np.r_[anchor, 1.0]]
    Phi_aug = np.eye(augmented_count)
    partial_products = []
    for phi in transitions:
        orbit.append(phi @ orbit[-1])
        Phi_aug = phi @ Phi_aug
        partial_products.append(Phi_aug.copy())

    # gamma_i = phi_N ... phi_(i+1) F_i chi_bar_i.
    Gamma_aug = np.zeros((augmented_count, interval_count))
    downstream = np.eye(augmented_count)
    for i in reversed(range(interval_count)):
        Gamma_aug[:, i] = downstream @ generators[i] @ orbit[i + 1]
        downstream = downstream @ transitions[i]

    # chi has last coordinate 1, but epsilon = chi - chi_bar has last entry 0.
    # Restrict the Lyapunov analysis to epsilon = iota * e, not all of R^4.
    projection = np.c_[np.eye(state_count), np.zeros(state_count)]
    embedding = projection.T
    dwell_map = build_dwell_map(interval_count)
    Phi = projection @ Phi_aug @ embedding
    Gd = projection @ Gamma_aug
    Gtau = Gd @ dwell_map

    return CycleModel(
        anchor=anchor,
        boundaries=boundaries,
        dwell=dwell,
        modes=modes,
        generators=generators,
        transitions=transitions,
        orbit=orbit,
        partial_products=partial_products,
        Phi_aug=Phi_aug,
        Gamma_aug=Gamma_aug,
        projection=projection,
        embedding=embedding,
        dwell_map=dwell_map,
        Phi=Phi,
        Gd=Gd,
        Gtau=Gtau,
    )


# 2. Reproduce the fixed LQR gain before solving for a common P.


def design_feedback(model: CycleModel) -> Feedback:
    """Use z = S^-1 e and v = delta_tau / timing_scale, as in the paper."""
    S = np.diag(STATE_SCALES)
    A0 = np.linalg.solve(S, model.Phi @ S)
    B = np.linalg.solve(S, model.Gtau) * TIMING_SCALE
    Q = np.eye(A0.shape[0])
    R = LQR_INPUT_WEIGHT * np.eye(B.shape[1])

    riccati_solution = solve_discrete_are(A0, B, Q, R)
    K = np.linalg.solve(
        R + B.T @ riccati_solution @ B,
        B.T @ riccati_solution @ A0,
    )
    Kphysical = TIMING_SCALE * K @ np.linalg.inv(S)
    A1 = A0 - B @ K
    return Feedback(S, TIMING_SCALE, A0, B, K, Kphysical, A1)


# 3. Independently verify the reconstructed model and its derivatives.


def propagate_exact_cycle(model: CycleModel, state: Matrix, offsets: Matrix) -> Matrix:
    """Propagate the affine plant with the requested switching-time offsets."""
    applied_dwell = model.dwell + model.dwell_map @ offsets
    augmented_state = np.r_[state, 1.0]
    for generator, duration in zip(model.generators, applied_dwell):
        augmented_state = expm(generator * duration) @ augmented_state
    return augmented_state[:-1]


def relative_error(actual: Matrix, reference: Matrix) -> float:
    return float(np.linalg.norm(actual - reference) / np.linalg.norm(reference))


def require_below(name: str, value: float, tolerance: float) -> None:
    """Keep validation active even when Python is invoked with -O."""
    if not value < tolerance:
        raise ValueError(f"{name}: {value:.6e} must be below {tolerance:.6e}")


def check_finite_differences(model: CycleModel) -> list[float]:
    state_count, offset_count = model.Gtau.shape
    state_step = 1e-5
    timing_step = 1e-8
    zero_offsets = np.zeros(offset_count)
    Phi_fd = np.zeros_like(model.Phi)
    Gamma_fd = np.zeros_like(model.Gtau)

    for j in range(state_count):
        perturbation = np.eye(state_count)[j] * state_step
        plus = propagate_exact_cycle(model, model.anchor + perturbation, zero_offsets)
        minus = propagate_exact_cycle(model, model.anchor - perturbation, zero_offsets)
        Phi_fd[:, j] = (plus - minus) / (2 * state_step)

    for j in range(offset_count):
        perturbation = np.eye(offset_count)[j] * timing_step
        plus = propagate_exact_cycle(model, model.anchor, perturbation)
        minus = propagate_exact_cycle(model, model.anchor, -perturbation)
        Gamma_fd[:, j] = (plus - minus) / (2 * timing_step)

    errors = [
        relative_error(Phi_fd, model.Phi),
        relative_error(Gamma_fd, model.Gtau),
    ]
    require_below("Finite-difference Jacobian error", max(errors), 1e-7)
    return errors


def validate_against_paper(model: CycleModel, feedback: Feedback) -> dict[str, Any]:
    """Read stored outputs only after the physical reconstruction is complete."""
    saved = loadmat(
        PAPER_DIR / "results" / "paper_results.mat",
        simplify_cells=True,
    )["results"]
    gain_error = relative_error(
        feedback.Kphysical,
        saved["controller"]["K_aggressive_physical"],
    )
    require_below("Saved aggressive gain error", gain_error, 1e-7)

    for name, rebuilt in (("Phi", model.Phi), ("Gamma", model.Gtau)):
        error = relative_error(rebuilt, saved["linearization"][name])
        require_below(f"Saved {name} error", error, 1e-10)

    closure = float(np.linalg.norm(model.orbit[-1][:-1] - model.anchor, np.inf))
    require_below("Nominal closure error", closure, 1e-10)
    return {
        "closure": closure,
        "gain_error": gain_error,
        "fd_errors": check_finite_differences(model),
    }


# 4. Generate laboratory data. Exact nonlinear trajectories are evidence only.


def conditioned_matrix(feedback: Feedback, beta: float) -> Matrix:
    return (1 - beta) * feedback.A0 + beta * feedback.A1


def spectral_radius(matrix: Matrix) -> float:
    return float(max(abs(np.linalg.eigvals(matrix))))


def sweep_conditioning_factor(feedback: Feedback, certificate: Certificate) -> list:
    """Sample the segment for visualization; the endpoint theorem proves it."""
    sweep = []
    for beta in np.linspace(0, 1, BETA_SWEEP_POINTS):
        A = conditioned_matrix(feedback, beta)
        residual = certificate.P - A.T @ certificate.P @ A
        sweep.append([beta, spectral_radius(A), eigvalsh(residual)[0]])
    return sweep


def condition_dwell_changes(model: CycleModel, changes: Matrix) -> float:
    shortening = changes < 0
    if not shortening.any():
        return 1.0
    margins = model.dwell[shortening] - MINIMUM_DWELL
    feasible_scale = np.min(margins / (-changes[shortening]))
    return min(1.0, float(feasible_scale))


def simulate_trajectories(
    model: CycleModel,
    feedback: Feedback,
    certificate: Certificate,
) -> dict[str, list]:
    initial_error = np.array(INITIAL_STATE) - model.anchor
    z0 = np.linalg.solve(feedback.state_scale, initial_error)
    trajectories = {}

    for kind in ("linear", "exact"):
        z = z0.copy()
        rows = []
        for cycle in range(SIMULATION_CYCLES + 1):
            raw_offsets = -feedback.timing_scale * feedback.K @ z
            dwell_changes = model.dwell_map @ raw_offsets
            beta = condition_dwell_changes(model, dwell_changes)
            applied_dwell = model.dwell + beta * dwell_changes
            rows.append(
                {
                    "k": cycle,
                    "z": z.copy(),
                    "beta": beta,
                    "V": z @ certificate.P @ z,
                    "min_dwell_us": min(applied_dwell) * 1e6,
                }
            )

            if kind == "linear":
                z = conditioned_matrix(feedback, beta) @ z
            else:
                state = model.anchor + feedback.state_scale @ z
                next_state = propagate_exact_cycle(model, state, beta * raw_offsets)
                z = np.linalg.solve(feedback.state_scale, next_state - model.anchor)
        trajectories[kind] = rows

    return trajectories


# 5. Preserve the JSON keys consumed by the existing interactive HTML template.


def assemble_tutorial_data(
    model: CycleModel,
    feedback: Feedback,
    certificate: Certificate,
    validation: dict[str, Any],
) -> dict[str, Any]:
    inverse_scale = np.linalg.inv(feedback.state_scale)
    Pphysical = inverse_scale.T @ certificate.P @ inverse_scale
    return {
        "parameters": {
            "E": SOURCE_VOLTAGE,
            "C1": CAPACITANCE_1,
            "C2": CAPACITANCE_2,
            "L": INDUCTANCE,
            "R": RESISTANCE,
        },
        "modes": model.modes,
        "boundaries_us": model.boundaries * 1e6,
        "dwell_us": model.dwell * 1e6,
        "xstar": model.anchor,
        "phis": model.transitions,
        "products": model.partial_products,
        "orbit": model.orbit,
        "Phi_aug": model.Phi_aug,
        "Gamma_aug": model.Gamma_aug,
        "Pi": model.projection,
        "iota": model.embedding,
        "D": model.dwell_map,
        "Phi": model.Phi,
        "Gd": model.Gd,
        "Gtau": model.Gtau,
        "S": feedback.state_scale,
        "ts": feedback.timing_scale,
        "A0": feedback.A0,
        "B": feedback.B,
        "K": feedback.K,
        "Kphysical": feedback.Kphysical,
        "A1": feedback.A1,
        "P": certificate.P,
        "Pphysical": Pphysical,
        "Qs": certificate.residuals,
        "eigP": certificate.eigenvalues_P,
        "eigQs": certificate.eigenvalues_residuals,
        "q": certificate.minimum_decrease,
        "eta": certificate.eta,
        "rho_bound": certificate.rate_bound,
        "radii": [spectral_radius(A) for A in (feedback.A0, feedback.A1)],
        **validation,
        "sweep": sweep_conditioning_factor(feedback, certificate),
        "trajectories": simulate_trajectories(model, feedback, certificate),
        "solver": {
            "interface": "CVXPY",
            "solver": "CLARABEL",
            "status": certificate.status,
            "cvxpy": version("cvxpy"),
            "numpy": np.__version__,
            "scipy": scipy.__version__,
        },
    }


def serialize_numpy(value: Any) -> Any:
    if isinstance(value, np.ndarray):
        return value.tolist()
    if isinstance(value, np.generic):
        return value.item()
    raise TypeError(f"Cannot serialize {type(value).__name__}")


def write_tutorial(data: dict[str, Any], output_dir: Path) -> Path:
    """Embed full-precision data in the self-contained MathML/SVG template."""
    template = (output_dir / "template.html").read_text(encoding="utf-8")
    placeholder = "__CERTIFICATE_DATA__"
    if template.count(placeholder) != 1:
        raise ValueError("The HTML template must contain exactly one data placeholder")

    text = json.dumps(data, default=serialize_numpy, indent=2)
    html_path = output_dir / "index.html"
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    (RESULTS_DIR / "certificate.json").write_text(text, encoding="utf-8")
    html_path.write_text(template.replace(placeholder, text), encoding="utf-8")
    return html_path


def main() -> None:
    model = build_cycle_model()
    feedback = design_feedback(model)
    certificate = solve_common_lyapunov(feedback.A0, feedback.A1)
    validation = validate_against_paper(model, feedback)
    data = assemble_tutorial_data(model, feedback, certificate, validation)
    html_path = write_tutorial(data, OUTPUT_DIR)

    summary_keys = (
        "solver",
        "P",
        "eigP",
        "eigQs",
        "q",
        "rho_bound",
        "radii",
        "closure",
        "gain_error",
        "fd_errors",
    )
    summary = {key: data[key] for key in summary_keys}
    print(json.dumps(summary, default=serialize_numpy, indent=2))
    print("Written:", html_path)


if __name__ == "__main__":
    main()
