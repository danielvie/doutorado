"""Independently verify saved evidence. No optimization; read-only by default."""

import argparse
import csv
import hashlib
import importlib.util
import json
import sys
from collections import Counter
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from scipy.linalg import eigvalsh, expm, solve_discrete_are

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OLD = ROOT / "studies/s2-kawa-synthesis/results"
CERTIFIED_METHODS = ("current-lqr", "saved-common-p") + tuple(f"strategy-{i}" for i in range(1, 6))
METHODS = CERTIFIED_METHODS + ("strategy-marcolino",)
MARCOLINO = ROOT / "studies/s1-marcolino-conditioning-comparison"
MARCOLINO_HISTORY = [MARCOLINO / "results" / suffix / "cycle_history.csv"
                     for suffix in ("", "error-scale-2x", "error-scale-3x")]
# Historical evidence is imported, not regenerated or newly optimized.
FROZEN_HISTORY = {
    "synthesis.json": "a86fe6aeb9f2b52e48f287be531d6b551c660acfb67f4d0d7b4a22937c18f3da",
    "summary.csv": "72142cfaaa54d1cff2a14b020a4d07f09283892cd88ac6de9c6eda3002d68c68",
    "history.csv": "70f2f7675cf32e13a041b9be8855e56ac1cd6f8c27810882deaf9b20695b11bd",
}
METRIC_FIELDS = ("method", "case", "split", "cost", "cost_ratio_lqr", "first_cycle",
                 "sustained_cycle", "final_error", "minimum_dwell_us", "minimum_raw_dwell_us",
                 "minimum_beta", "conditioned_cycles", "anchor_sustained_time_ms",
                 "reference_sustained_time_ms", "final_reference_error", "clocked_error_sum",
                 "clocked_error_ratio_lqr", "clocked_sustained_time_ms", "final_clocked_error",
                 "extended_cycles", "maximum_cycle_duration_us", "total_boundary_delay_us")
SUMMARY_FIELDS = ("method", "split", "cases", "mean_cost_ratio_lqr", "worst_cost_ratio_lqr",
                  "best_cost_ratio_lqr", "cost_regressions", "mean_sustained_cycle",
                  "worst_sustained_cycle", "mean_clocked_error_ratio_lqr", "worst_clocked_error_ratio_lqr",
                  "clocked_error_regressions", "mean_clocked_sustained_time_ms",
                  "worst_clocked_sustained_time_ms", "clocked_unsettled_cases",
                  "maximum_final_reference_error")


class VerificationError(ValueError):
    pass


class Checks:
    def __init__(self):
        self.counts = Counter()
        self.max_errors = {}

    def require(self, label, condition):
        if not condition:
            raise VerificationError(label)
        self.counts[label] += 1

    def near(self, label, actual, expected, atol=1e-10, rtol=1e-9):
        a, b = np.asarray(actual, dtype=float), np.asarray(expected, dtype=float)
        self.require(label + ": shape/finiteness", a.shape == b.shape and
                     np.isfinite(a).all() and np.isfinite(b).all())
        error = float(np.max(np.abs(a - b))) if a.size else 0.0
        self.max_errors[label] = max(self.max_errors.get(label, 0.0), error)
        self.require(label, bool(np.all(np.abs(a - b) <= atol + rtol * np.abs(b))))


def array(value, shape, label):
    value = np.asarray(value, dtype=float)
    if value.shape != shape or not np.isfinite(value).all():
        raise VerificationError(f"{label}: expected finite shape {shape}, got {value.shape}")
    return value


def sym(value):
    return (value + value.T) / 2


def mineig(value):
    return float(eigvalsh(sym(value))[0])


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read_json(path):
    def reject_constant(value):
        raise VerificationError(f"Nonfinite JSON constant: {value}")

    def unique_keys(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise VerificationError(f"Duplicate JSON key: {key}")
            result[key] = value
        return result

    return json.loads(Path(path).read_text(encoding="utf-8-sig"),
                      parse_constant=reject_constant, object_pairs_hook=unique_keys)


def verify_hashes(manifest, root, checks, required=()):
    checks.require("nonempty source manifest", isinstance(manifest, dict) and bool(manifest))
    normalized = {key.replace("\\", "/"): value for key, value in manifest.items()}
    checks.require("unique normalized source paths", len(normalized) == len(manifest))
    checks.require("required source hashes", set(required) <= normalized.keys())
    for relative, expected in normalized.items():
        path = (root / relative).resolve()
        checks.require("source path contained in root", path.is_relative_to(root.resolve()))
        checks.require(f"source hash: {relative}", path.is_file() and digest(path) == expected)


def load_model():
    # Import the current prefixed source by absolute path, never a stale study alias.
    source = ROOT / "studies/s1-lyapunov/python/build_tutorial.py"
    sys.path.insert(0, str(source.parent.resolve()))
    try:
        spec = importlib.util.spec_from_file_location("_s3_independent_converter", source)
        tutorial = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = tutorial
        spec.loader.exec_module(tutorial)
    finally:
        sys.path.pop(0)
    cycle = tutorial.build_cycle_model()
    S, ts = np.diag([10., 20., 1.]), 1e-5
    A = np.linalg.solve(S, cycle.Phi @ S)
    B = np.linalg.solve(S, cycle.Gtau) * ts
    return SimpleNamespace(A=A, B=B, S=S, ts=ts, anchor=cycle.anchor,
                           dwell=cycle.dwell, D=cycle.dwell_map, F=cycle.generators,
                           cycle=cycle, propagate=tutorial.propagate_exact_cycle)


def expected_cases(model):
    z = np.linalg.solve(model.S, np.array([7.5143, 20.8211, .0314]) - model.anchor)
    train = [z, -z, [-.2, -.1, -.4], [.2, .1, .4], [-.1, .15, .2], [.1, -.15, -.2]]
    held = [[.15, 0, 0], [-.15, 0, 0], [0, .15, 0], [0, -.15, 0], [0, 0, .5],
            [0, 0, -.5], [.15, .15, .3], [-.15, -.15, -.3], [.15, -.15, .3],
            [-.15, .15, -.3], [.15, .15, -.3], [-.15, -.15, .3]]
    return ([dict(name="article-1x" if i == 1 else f"train-{i}", split="training", z=v)
             for i, v in enumerate(train, 1)] +
            [dict(name=f"withheld-{i}", split="withheld", z=v) for i, v in enumerate(held, 1)] +
            [dict(name=f"article-{i}x", split="historical-stress", z=i*z) for i in (2, 3)])


def verify_model(saved, model, checks):
    for key, value in {"A": model.A, "B": model.B, "S": model.S, "timing_scale": model.ts,
                       "anchor": model.anchor, "nominal_dwell": model.dwell,
                       "D": model.D, "generators": model.F}.items():
        checks.near("model " + key, saved[key], value, atol=1e-11, rtol=1e-12)
    checks.near("nominal period", sum(model.dwell), 286e-6, atol=1e-15, rtol=0)
    checks.near("orbit closure", model.cycle.orbit[-1][:3], model.anchor, atol=1e-10, rtol=0)


def verify_certificate(method, model, checks):
    K = array(method["K"], (8, 3), "K")
    P = array(method["P"], (3, 3), "P")
    checks.near("P symmetry", P, P.T, atol=1e-12, rtol=0)
    checks.near("P trace", np.trace(P), 3., atol=1e-10, rtol=0)
    checks.require("P eigenvalue floor", mineig(P) >= 1e-7 - 1e-10)
    margins = [mineig(P - M.T @ P @ M) for M in (model.A, model.A - model.B @ K)]
    checks.require("strict common-P endpoint margins", min(margins) > 1e-9)
    checks.near("physical gain", method["Kphysical"],
                model.ts * np.linalg.solve(model.S.T, K.T).T, atol=1e-13)
    expected = {"min_eigenvalue_P": mineig(P), "trace_P": float(np.trace(P)),
                "endpoint_decreases": margins, "condition_number_P": float(np.linalg.cond(P)),
                "raw_radius": float(max(abs(np.linalg.eigvals(model.A - model.B @ K))))}
    for key, value in expected.items():
        checks.near("certificate " + key, method["certificate"][key], value, atol=1e-10)
    return K, P


def verify_marcolino(method, current, model, checks):
    checks.require("Marcolino policy", method["policy"] == "marcolino")
    checks.require("Marcolino has no common-P coverage", method["P"] is None and
                   method["certificate"] is None and
                   method["certificate_status"] == "not-covered-variable-period")
    K = array(method["K"], (8, 3), "Marcolino K")
    checks.near("Marcolino unchanged current LQR", K, current, atol=1e-12, rtol=0)
    checks.near("Marcolino physical gain", method["Kphysical"],
                model.ts * np.linalg.solve(model.S.T, K.T).T, atol=1e-13)


def sequential_dwells(model, raw):
    nominal = np.r_[0., np.cumsum(model.dwell)]
    actual = np.zeros(10)
    for i in range(1, 9):
        actual[i] = max(nominal[i] + raw[i-1], actual[i-1] + 3e-6)
    actual[-1] = max(nominal[-1], actual[-2] + 3e-6)
    return np.diff(actual), actual[1:-1] - nominal[1:-1], actual[-1] - nominal[-1]


def propagate_dwells(model, state, dwells, elapsed=None):
    """Exact affine propagation, including a partial last realized dwell."""
    remaining = float(np.sum(dwells)) if elapsed is None else float(elapsed)
    augmented = np.r_[state, 1.]
    for generator, duration in zip(model.F, dwells):
        if remaining <= 0:
            break
        step = min(float(duration), remaining)
        augmented = expm(generator * step) @ augmented
        remaining -= step
    return augmented[:3]


def nominal_reference(model, time):
    period = float(sum(model.dwell))
    phase = time % period
    if min(phase, period-phase) < 1e-12:
        return model.anchor
    return propagate_dwells(model, model.anchor, model.dwell, phase)


def timing_values(model, states, dwell, sustained):
    period = float(sum(model.dwell))
    durations = dwell.sum(axis=0)
    times = np.r_[0., np.cumsum(durations)]
    extensions = durations - period
    references = np.column_stack([nominal_reference(model, t) for t in times])
    reference_errors = np.linalg.norm(np.linalg.solve(model.S, states-references), axis=0)
    _, reference_sustained = thresholds(reference_errors)
    clocked_times = np.arange(101)*period
    clocked_states = np.empty_like(states)
    for j, time in enumerate(clocked_times):
        # Partial propagation also handles samples arbitrarily close to a
        # boundary. Only the final index is clamped for clock roundoff.
        k = min(int(np.searchsorted(times, time, side="right")-1), 99)
        clocked_states[:, j] = propagate_dwells(model, states[:, k], dwell[:, k], max(0., time-times[k]))
    clocked_errors = np.linalg.norm(np.linalg.solve(model.S, clocked_states-model.anchor[:, None]), axis=0)
    clocked_first, clocked_sustained = thresholds(clocked_errors)
    return dict(cycle_times=times, cycle_durations=durations, terminal_extensions=extensions,
                extended_cycles=int(np.count_nonzero(extensions > 1e-12)),
                total_boundary_delay_us=float((times[-1]-100*period)*1e6),
                maximum_cycle_duration_us=float(durations.max()*1e6),
                anchor_sustained_time_ms=None if sustained is None else float(times[sustained]*1e3),
                reference_errors=reference_errors, reference_sustained_cycle=reference_sustained,
                reference_sustained_time_ms=None if reference_sustained is None else float(times[reference_sustained]*1e3),
                final_reference_error=float(reference_errors[-1]), clocked_times=clocked_times,
                clocked_states=clocked_states, clocked_errors=clocked_errors,
                clocked_first_sample=clocked_first, clocked_sustained_sample=clocked_sustained,
                clocked_sustained_time_ms=None if clocked_sustained is None else float(clocked_times[clocked_sustained]*1e3),
                final_clocked_error=float(clocked_errors[-1]),
                clocked_error_sum=float(np.sum(clocked_errors[:-1]**2)))


def thresholds(errors):
    first = np.flatnonzero(errors < .01)
    bad = np.flatnonzero(errors >= .01)
    return (int(first[0]) if first.size else None,
            0 if not bad.size else int(bad[-1] + 1) if bad[-1] < len(errors) - 1 else None)


def verify_response(response, K, case, model, checks, policy="uniform"):
    checks.require("response policy", response["policy"] == policy)
    states = array(response["states"], (3, 101), "states")
    raw = array(response["raw_offsets"], (8, 100), "raw offsets")
    applied = array(response["applied_offsets"], (8, 100), "applied offsets")
    dwell = array(response["dwells"], (9, 100), "dwells")
    checks.near("initial state", states[:, 0], model.anchor + model.S @ case["z"], atol=1e-11)
    z = np.linalg.solve(model.S, states - model.anchor[:, None])
    errors = np.linalg.norm(z, axis=0)
    checks.near("normalized errors", response["errors"], errors, atol=1e-12)
    checks.near("raw command", raw, -model.ts * K @ z[:, :-1], atol=1e-13)
    q = model.D @ raw
    if policy == "marcolino":
        checks.require("Marcolino has no beta", response["beta"] is None and response["minimum_beta"] is None)
        schedules = [sequential_dwells(model, raw[:, k]) for k in range(100)]
        expected_dwell = np.column_stack([s[0] for s in schedules])
        expected_applied = np.column_stack([s[1] for s in schedules])
        extension = np.array([s[2] for s in schedules])
        checks.near("sequential realized dwells", dwell, expected_dwell, atol=1e-13)
        checks.near("sequential interior offsets", applied, expected_applied, atol=1e-13)
        checks.near("separate terminal extension", response["terminal_extensions"], extension, atol=1e-13)
        # Include the terminal boundary when counting altered requests.
        conditioned = int(np.count_nonzero(np.any(abs(expected_applied-raw) > 1e-12, axis=0) |
                                           (extension > 1e-12)))
        minimum_beta = None
    else:
        checks.require("known uniform policy", policy == "uniform")
        betas = array(response["beta"], (100,), "beta")
        bounds = np.full_like(q, np.inf)
        np.divide(model.dwell[:, None] - 3e-6, -q, out=bounds, where=q < 0)
        expected_beta = np.minimum(1., bounds.min(axis=0))
        checks.require("beta interval", bool(np.all((betas >= 0) & (betas <= 1))))
        checks.near("maximal-feasible beta", betas, expected_beta, atol=1e-12)
        checks.near("applied command", applied, expected_beta * raw, atol=1e-13)
        checks.near("applied dwells", dwell, model.dwell[:, None] + model.D @ applied, atol=1e-13)
        checks.near("fixed period", dwell.sum(axis=0), np.full(100, 286e-6), atol=1e-13, rtol=0)
        conditioned = int(np.count_nonzero(expected_beta < 1 - 1e-12))
        minimum_beta = float(expected_beta.min())
    checks.require("minimum dwell", bool(np.min(dwell) >= 3e-6 - 1e-12))
    for k in range(100):
        state = (propagate_dwells(model, states[:, k], dwell[:, k]) if policy == "marcolino"
                 else model.propagate(model.cycle, states[:, k], applied[:, k]))
        checks.near("exact one-cycle state", states[:, k + 1], state, atol=1e-9, rtol=0)
    # Cycle-start cost, fixed Q=I, R=.001 I, and no terminal penalty.
    stage = np.sum(z[:, :-1]**2, axis=0) + .001 * np.sum((applied/model.ts)**2, axis=0)
    checks.near("stage costs", response["stage_cost"], stage, atol=1e-11)
    first, sustained = thresholds(errors)
    values = dict(cost=float(stage.sum()), first_cycle=first, sustained_cycle=sustained,
                  final_error=float(errors[-1]), minimum_dwell_us=float(dwell.min()*1e6),
                  minimum_raw_dwell_us=float((model.dwell[:, None] + q).min()*1e6),
                  minimum_beta=minimum_beta, conditioned_cycles=conditioned,
                  cycle_sample_minimum_state=states.min(axis=1))
    values.update(timing_values(model, states, dwell, sustained))
    for key, value in values.items():
        if value is None or key in ("first_cycle", "sustained_cycle", "conditioned_cycles", "extended_cycles",
                                    "reference_sustained_cycle", "clocked_first_sample", "clocked_sustained_sample"):
            checks.require("response " + key, response[key] == value)
        elif key in ("cycle_times", "cycle_durations", "terminal_extensions", "clocked_times"):
            checks.near("response " + key, response[key], value, atol=1e-13, rtol=1e-12)
        else:
            checks.near("response " + key, response[key], value)
    return values


def verify_training_score(score, rows, K, denominators, checks):
    costs = np.array([r["cost"] for r in rows])
    ratios = costs / denominators
    for key, value in dict(costs=costs, mean_ratio=ratios.mean(), worst_ratio=ratios.max(),
                           gain_norm=np.linalg.norm(K)).items():
        checks.near("training score " + key, score[key], value)
    checks.require("training settling", score["settling"] == [r["sustained_cycle"] for r in rows])


def verify_strategy2(raw, model, checks, final=None):
    X, Y, W = (array(raw[k], shape, k) for k, shape in
               (("X", (3, 3)), ("Y", (8, 3)), ("W", (3, 3))))
    checks.near("strategy2 X symmetry", X, X.T, atol=1e-8, rtol=0)
    checks.near("strategy2 W symmetry", W, W.T, atol=1e-8, rtol=0)
    checks.require("strategy2 X floor", mineig(X) >= 1e-7 - 1e-10)
    symmetry_X, symmetry_W = np.max(abs(X-X.T)), np.max(abs(W-W.T))
    X, W = sym(X), sym(W)
    weight, rate = float(raw["weight"]), float(raw["open_rate"])
    checks.require("strategy2 approved setting", weight in (.0001, .001, .01) and
                   rate in (.9999, .99995, .99999))
    K, Praw = np.linalg.solve(X.T, Y.T).T, sym(np.linalg.solve(X, np.eye(3)))
    checks.near("strategy2 gain recovery", K @ X, Y, atol=1e-10)
    checks.near("strategy2 inverse recovery", Praw @ X, np.eye(3), atol=1e-7)
    checks.near("strategy2 raw P", raw["P_cost_raw"], Praw, atol=1e-8)
    checks.near("strategy2 saved K", raw["K"], K, atol=1e-9)
    G = model.A @ X - model.B @ Y
    I, Z, Z38 = np.eye(3), np.zeros((3, 3)), np.zeros((3, 8))
    costblock = np.block([[X, G.T, X, np.sqrt(weight)*Y.T],
                          [G, X, Z, Z38], [X, Z, I, Z38],
                          [np.sqrt(weight)*Y, Z38.T, Z38.T, np.eye(8)]])
    openblock = np.block([[rate**2*X, (model.A @ X).T], [model.A @ X, X]]) - 1e-8*np.eye(6)
    epigraph = np.block([[W, I], [I, X]])
    for name, block in (("cost", costblock), ("open", openblock), ("epigraph", epigraph)):
        checks.require("strategy2 " + name + " LMI", mineig(block) >= -1e-8)
    F, Q = model.A - model.B @ K, I + weight*K.T @ K
    decrement = sym(Praw - F.T @ Praw @ F)
    raw_residual = mineig(decrement - Q)
    inflation = 1. if raw_residual >= 1e-9 else 1 + max(0., (1e-9 - raw_residual)/mineig(decrement))
    checks.require("strategy2 bounded inflation", 1 <= inflation <= 1 + 1e-5)
    checks.near("strategy2 reported inflation", raw["inflation"], inflation, atol=1e-10)
    Pcost = array(raw["P_cost"], (3, 3), "P_cost")
    checks.near("strategy2 inflated P", Pcost, inflation*Praw, atol=1e-8)
    checks.require("strategy2 strict cost bound", mineig(Pcost - F.T @ Pcost @ F - Q) > 0)
    checks.require("strategy2 open contraction", mineig(rate**2*Pcost - model.A.T @ Pcost @ model.A) > 0)
    residuals = {"symmetry_X": symmetry_X, "symmetry_W": symmetry_W,
                 "min_eigenvalue_X": mineig(X), "X_floor_residual": mineig(X-1e-7*I),
                 "gain_recovery_relative": np.linalg.norm(K @ X-Y)/max(1, np.linalg.norm(Y)),
                 "inverse_recovery_relative": np.linalg.norm(Praw @ X-I)/np.linalg.norm(I),
                 "raw_open_rate_P_residual": mineig(rate**2*Praw-model.A.T @ Praw @ model.A),
                 "open_rate_P_residual": mineig(rate**2*Pcost-model.A.T @ Pcost @ model.A),
                 "full_feedback_stability_residual": mineig(Pcost-F.T @ Pcost @ F),
                 "min_eigenvalue_Pcost": mineig(Pcost), "epigraph_trace_gap": np.trace(W)-np.trace(Praw),
                 "cost_inflation": inflation, "raw_full_feedback_cost_residual": raw_residual,
                 "full_feedback_cost_residual": mineig(Pcost-F.T @ Pcost @ F-Q),
                 "cost_block_min_eigenvalue": mineig(costblock),
                 "open_rate_block_residual": mineig(openblock),
                 "epigraph_min_eigenvalue": mineig(epigraph)}
    for key, value in residuals.items():
        checks.near("strategy2 residual " + key, raw["residuals"][key], value, atol=1e-8)
    checks.near("strategy2 raw stability P", raw["P_stability"], 3*Pcost/np.trace(Pcost))
    if final is not None:
        checks.near("strategy2 selected K", final["K"], K)
        checks.near("strategy2 normalized P", final["P"], 3*Pcost/np.trace(Pcost))


def verify_strategy3(raw, model, checks, final=None):
    X, Y, U = (array(raw[k], shape, k) for k, shape in
               (("X", (3, 3)), ("Y", (8, 3)), ("U", (8, 8))))
    t, r0, r1 = (float(raw[k]) for k in ("t", "r0", "r1"))
    checks.require("strategy3 approved setting", r0 in (.9999, .99999) and r1 in (.25, .5, .8)
                   and raw["lambda"] in (.01, .1))
    checks.near("strategy3 X symmetry", X, X.T, atol=1e-8, rtol=0)
    checks.near("strategy3 U symmetry", U, U.T, atol=1e-8, rtol=0)
    checks.near("strategy3 trace X", np.trace(X), 3., atol=1e-6, rtol=0)
    checks.require("strategy3 X floor", mineig(X) >= 1e-7 - 1e-9)
    K, P = np.linalg.solve(X.T, Y.T).T, sym(np.linalg.solve(X, np.eye(3)))
    checks.near("strategy3 gain recovery", K @ X, Y, atol=1e-9)
    checks.near("strategy3 inverse recovery", P @ X, np.eye(3), atol=1e-6)
    H = model.D / ((model.dwell - 3e-6)/model.ts)[:, None]
    G0, G1 = model.A @ X, model.A @ X - model.B @ Y
    blocks = {"X_floor": X - 1e-7*np.eye(3),
              "open": np.block([[r0*r0*X, G0.T], [G0, X]]),
              "feedback": np.block([[r1*r1*X, G1.T], [G1, X]]),
              "effort": np.block([[U, Y], [Y.T, X]])}
    for j in range(9):
        w = H[j:j+1] @ Y
        blocks[f"dwell-{j}"] = np.block([[np.array([[t]]), w], [w.T, X]])
    for label, block in blocks.items():
        tolerance = 1e-7 + 1e-7*np.linalg.norm(block, 2)
        checks.require("strategy3 " + label + " LMI", mineig(block) >= -tolerance)
    for M, rate in ((model.A, r0), (model.A-model.B @ K, r1)):
        checks.require("strategy3 recovered contraction", eigvalsh(sym(M.T @ P @ M), P)[-1]
                       <= rate*rate + 1e-6)
    effort = K @ X @ K.T
    checks.require("strategy3 effort Schur bound", mineig(U-effort) >=
                   -(1e-7 + 1e-7*max(np.linalg.norm(U, 2), np.linalg.norm(effort, 2))))
    demand = np.diag(H @ effort @ H.T)
    checks.require("strategy3 dwell Schur bound", bool(np.min(t-demand) >= -(1e-7+1e-7*max(1, abs(t)))))
    Pnormalized = 3*P/np.trace(P)
    checks.require("strategy3 recovered common-P floor", mineig(Pnormalized) >= 1e-7-1e-10)
    checks.require("strategy3 recovered common-P margins", min(mineig(Pnormalized-M.T @ Pnormalized @ M)
                   for M in (model.A, model.A-model.B @ K)) > 1e-9)
    # A requested full-feedback rate below the open spectral radius excludes K=0.
    checks.require("strategy3 excludes zero feedback", r1 < max(abs(np.linalg.eigvals(model.A))))
    if final is not None:
        checks.near("strategy3 selected K", final["K"], K)
        checks.near("strategy3 normalized P", final["P"], 3*P/np.trace(P))


def verify_strategy_extras(result, model, legacy, checks):
    name = result["name"]
    if name == "strategy-1":
        a, b, c = result["parameters"]["selected_setting"]
        Q, R = np.diag([10.**a, 10.**b, 1.]), .001*10.**c*np.eye(8)
        P = solve_discrete_are(model.A, model.B, Q, R)
        K = np.linalg.solve(R+model.B.T @ P @ model.B, model.B.T @ P @ model.A)
        checks.near("strategy1 selected LQR gain", result["K"], K, atol=1e-8)
    elif name == "strategy-2":
        for entry in result["candidate_log"]:
            if entry.get("accepted") and "synthesis" in entry:
                verify_strategy2(entry["synthesis"], model, checks)
        selected = result["selected_synthesis"]
        if selected is not None:
            verify_strategy2(selected, model, checks, result)
        else:
            checks.near("strategy2 unchanged seed K", result["K"], legacy["current"]["K"])
        diagnostic = result.get("best_synthesized_candidate")
        if diagnostic is not None:
            verify_strategy2(diagnostic, model, checks)
    elif name == "strategy-3":
        for entry in result["candidate_log"]:
            if entry.get("verification", {}).get("accepted"):
                verify_strategy3(entry["synthesis"], model, checks)
        selected = result["selected_synthesis"]
        if selected is not None:
            verify_strategy3(selected["variables"], model, checks, result)
        else:
            checks.near("strategy3 unchanged seed K", result["K"], legacy["current"]["K"])
    elif name == "strategy-4":
        raw = result.get("redistribution", result)
        N, Z, K0 = (array(raw[k], shape, k) for k, shape in
                    (("N", (8, 5)), ("Z", (5, 3)), ("K0", (8, 3))))
        K, P = np.array(result["K"]), np.array(result["P"])
        checks.near("strategy4 K0", K0, legacy["candidates"]["decay"]["K"])
        checks.near("strategy4 orthonormal nullspace", N.T @ N, np.eye(5), atol=1e-12)
        checks.near("strategy4 BN", model.B @ N, np.zeros((3, 5)), atol=1e-11, rtol=0)
        checks.near("strategy4 gain recovery", K, K0 + N @ Z, atol=1e-10)
        checks.near("strategy4 BK invariance", model.B @ (K-K0), np.zeros((3, 3)), atol=1e-10, rtol=0)
        checks.require("strategy4 BN norm", np.linalg.norm(model.B @ N) <= 1e-11*max(1, np.linalg.norm(model.B)))
        checks.require("strategy4 BK norm", np.linalg.norm(model.B @ (K-K0)) <= 1e-10*max(1, np.linalg.norm(model.B @ K0)))
        for key, value in (("BN", model.B @ N), ("B_gain_delta", model.B @ (K-K0))):
            if key in result:
                checks.near("strategy4 saved " + key, result[key], value, atol=1e-12)
        P0 = np.array(legacy["candidates"]["decay"]["P"])
        checks.near("strategy4 fixed P", P, 3*P0/np.trace(P0))
    elif name == "strategy-5":
        raw = result["parameters"]
        K0, D, theta = (array(raw[k], (8, 3), k) for k in ("K0", "D", "Theta"))
        checks.near("strategy5 K0", K0, legacy["current"]["K"])
        checks.near("strategy5 coordinate scales", D, np.maximum(1., abs(K0)))
        checks.require("strategy5 parameter bounds", bool(np.max(abs(theta)) <= 2.))
        checks.near("strategy5 gain recovery", result["K"], K0 + D*theta)
        P0 = np.array(legacy["current"]["P"])
        P0 = 3*P0/np.trace(P0)
        checks.near("strategy5 fixed P", result["P"], P0)
        seed_margins = [mineig(P0-M.T @ P0 @ M) for M in (model.A, model.A-model.B @ K0)]
        threshold = .1*min(seed_margins) + 1e-9
        checks.near("strategy5 margin threshold", raw["margin_threshold"], threshold, atol=1e-12)
        K = np.array(result["K"])
        checks.require("strategy5 strict fixed-P margin", min(mineig(P0-M.T @ P0 @ M)
                       for M in (model.A, model.A-model.B @ K)) > threshold)


def read_csv(path):
    with Path(path).open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        return reader.fieldnames, list(reader)


def verify_csv(path, rows, fields, checks):
    headers, saved = read_csv(path)
    checks.require("CSV headers", headers == list(fields))
    checks.require("CSV row count", len(saved) == len(rows))
    for actual, expected in zip(saved, rows):
        for key in fields:
            value = expected[key]
            if isinstance(value, str):
                checks.require("CSV " + key, actual[key] == value)
            elif value is None:
                checks.require("CSV missing " + key, actual[key] == "")
            else:
                checks.near("CSV " + key, float(actual[key]), value)


def verify_historical(mpc, checks):
    for name, expected in FROZEN_HISTORY.items():
        checks.require("frozen historical " + name, digest(OLD / name) == expected)
    legacy = read_json(OLD / "synthesis.json")
    # Historical paths predate the directory prefixes. These exact renames retain
    # the original bytes, including the archived original Python producer.
    aliases = {"/studies/lyapunov/": "/studies/s1-lyapunov/",
               "/studies/mpc-comparison/": "/studies/s1-mpc-comparison/",
               "/studies/kawa-synthesis/synthesize.py":
               "/studies/s2-kawa-synthesis/archive/synthesize-four-controller.py"}
    mapped = {}
    for relative, expected in legacy["source_sha256"].items():
        for old, current in aliases.items():
            relative = relative.replace(old, current)
        mapped[relative] = expected
    verify_hashes(mapped, ROOT.parents[2], checks)
    _, summary = read_csv(OLD / "summary.csv")
    _, history = read_csv(OLD / "history.csv")
    checks.require("only three imported MPC cases", [r["case"] for r in mpc] ==
                   [f"article-{i}x" for i in (1, 2, 3)])
    for scale, saved in enumerate(mpc, 1):
        rows = [r for r in summary if r["method"] == "mpc5" and int(r["error_scale"]) == scale]
        hist = [r for r in history if r["method"] == "mpc5" and int(r["error_scale"]) == scale]
        checks.require("historical MPC row count", len(rows) == 1 and len(hist) == 101)
        checks.near("historical MPC cycles", [float(r["cycle"]) for r in hist], np.arange(101))
        row = rows[0]
        values = {"cost": float(row["evaluation_cost"]),
                  "first_cycle": int(row["first_cycle_below_001"]),
                  "sustained_cycle": int(row["sustained_cycle_below_001"]),
                  "minimum_dwell_us": float(row["minimum_dwell_us"]),
                  "errors": [float(r["normalized_error"]) for r in hist],
                  "cumulative_cost": [float(r["cumulative_cost"]) for r in hist]}
        for key, value in values.items():
            checks.near("imported historical MPC " + key, saved[key], value)
        checks.require("historical MPC thresholds", thresholds(np.array(values["errors"])) ==
                       (values["first_cycle"], values["sustained_cycle"]))
        checks.near("historical MPC cumulative cost", values["cumulative_cost"][-1], values["cost"])


def verify_marcolino_history(responses, checks):
    for scale, path in enumerate(MARCOLINO_HISTORY, 1):
        _, historical = read_csv(path)
        checks.require("historical Marcolino 101 samples", len(historical) == 101)
        response = next(r for r in responses if r["method"] == "strategy-marcolino" and
                        r["case"] == f"article-{scale}x")
        checks.near("historical Marcolino cycle indices", [float(r["cycle"]) for r in historical], np.arange(101))
        for field, column, scale_factor in (("cycle_times", "marcolino_time_ms", 1e3),
                                            ("errors", "marcolino_phase_reset_error", 1.),
                                            ("reference_errors", "marcolino_global_phase_error", 1.)):
            checks.near("historical Marcolino " + field, np.asarray(response[field])*scale_factor,
                        [float(r[column]) for r in historical], atol=1e-8, rtol=1e-8)


def verify(results=HERE / "results"):
    results = Path(results)
    checks, model = Checks(), load_model()
    comparison_path = results / "comparison.json"
    strategy_paths = [results / f"strategy-{i}.json" for i in range(1, 6)]
    snapshots = {path: digest(path) for path in
                 [comparison_path, results / "metrics.csv", results / "summary.csv"] + strategy_paths}
    saved = read_json(comparison_path)
    required = [HERE / x for x in ("common.jl", "evaluate.jl", "SPEC.md", "strategy-marcolino.jl",
                                   "comparison_timing.jl", "MARCOLINO.md")]
    required += [MARCOLINO / "sequential_dwell_condition.m"] + MARCOLINO_HISTORY
    required += [results / "strategy-marcolino.json"]
    required += [results / "baseline_validation.json"] + [OLD / x for x in FROZEN_HISTORY]
    required += [HERE / f"strategy-{i}.jl" for i in range(1, 6)]
    required += strategy_paths
    verify_hashes(saved["source_sha256"], ROOT, checks,
                  [p.relative_to(ROOT).as_posix() for p in required])
    baseline = read_json(results / "baseline_validation.json")
    verify_hashes(baseline["source_sha256"], ROOT, checks,
                  ["studies/s3-gain-strategies/common.jl", "studies/s3-gain-strategies/test_common.jl",
                   "studies/s2-kawa-synthesis/results/history.csv"])
    checks.require("baseline validation passed", baseline["status"] == "passed")
    verify_historical(saved["historical_mpc"], checks)
    legacy = read_json(OLD / "synthesis.json")
    verify_model(saved["model"], model, checks)
    checks.near("legacy A", legacy["A"], model.A, atol=1e-11)
    checks.near("legacy B", legacy["B"], model.B, atol=1e-11)
    Q, R = np.eye(3), .001*np.eye(8)
    H = solve_discrete_are(model.A, model.B, Q, R)
    checks.near("independent current LQR", legacy["current"]["K"],
                np.linalg.solve(R+model.B.T @ H @ model.B, model.B.T @ H @ model.A), atol=1e-8)
    decay = legacy["candidates"]["decay"]
    checks.near("historical decay gain recovery", np.array(decay["K"]) @ np.array(decay["X"]), decay["Y"])
    checks.near("historical decay inverse recovery", np.array(decay["P"]) @ np.array(decay["X"]), np.eye(3))
    cases = expected_cases(model)
    checks.require("case count", len(saved["cases"]) == 20)
    for actual, expected in zip(saved["cases"], cases):
        checks.require("case identity/split", (actual["name"], actual["split"]) ==
                       (expected["name"], expected["split"]))
        checks.near("case initial error", actual["z"], expected["z"], atol=1e-12)
    checks.require("method identities/order", [m["name"] for m in saved["methods"]] == list(METHODS))
    methods = {m["name"]: m for m in saved["methods"]}
    strategies = {}
    for name, method in methods.items():
        if name == "strategy-marcolino":
            current = legacy["current"]["K"]
            verify_marcolino(method, current, model, checks)
            result = read_json(results / "strategy-marcolino.json")
            checks.require("Marcolino result identity", result["name"] == name)
            verify_marcolino(result, current, model, checks)
            verify_hashes(result["source_sha256"], ROOT, checks,
                          [p.relative_to(ROOT).as_posix() for p in
                           [HERE / "strategy-marcolino.jl", HERE / "comparison_timing.jl", HERE / "MARCOLINO.md", HERE / "common.jl",
                            MARCOLINO / "sequential_dwell_condition.m", OLD / "synthesis.json"] + MARCOLINO_HISTORY])
            for key in ("K", "Kphysical"):
                checks.near("comparison/Marcolino result " + key, method[key], result[key], atol=1e-12)
            strategies[name] = result
            continue
        checks.require("certified method uniform policy", method["policy"] == "uniform")
        checks.require("certified method coverage status", method["certificate_status"] == "verified-conditioned-linearized")
        verify_certificate(method, model, checks)
        if name.startswith("strategy-"):
            result = read_json(results / (name + ".json"))
            checks.require("strategy result identity", result["name"] == name)
            verify_hashes(result["source_sha256"], ROOT, checks,
                          [f"studies/s3-gain-strategies/{name}.jl", "studies/s3-gain-strategies/common.jl",
                           "studies/s3-gain-strategies/SPEC.md", "studies/s2-kawa-synthesis/results/synthesis.json"])
            verify_certificate(result, model, checks)
            for key in ("K", "P", "Kphysical"):
                checks.near("comparison/result " + key, method[key], result[key], atol=1e-12)
            checks.near("comparison/result elapsed seconds", method["elapsed_seconds"], result["elapsed_seconds"])
            verify_strategy_extras(result, model, legacy, checks)
            strategies[name] = result
        else:
            original = legacy["current"] if name == "current-lqr" else decay
            P = np.array(original["P"])
            checks.near("baseline K", method["K"], original["K"])
            checks.near("baseline normalized P", method["P"], 3*P/np.trace(P))
    identities = [(r["method"], r["case"], r["split"]) for r in saved["responses"]]
    checks.require("160 trajectory identities/order", identities ==
                   [(name, case["name"], case["split"]) for name in METHODS for case in cases])
    rows = []
    for response, (name, case_name, split) in zip(saved["responses"], identities):
        case = next(c for c in cases if c["name"] == case_name)
        values = verify_response(response, np.array(methods[name]["K"]), case, model, checks,
                                 policy=methods[name]["policy"])
        rows.append(dict(method=name, case=case_name, split=split, **values))
    verify_marcolino_history(saved["responses"], checks)
    denominators = {row["case"]: row["cost"] for row in rows if row["method"] == "current-lqr"}
    clocked_denominators = {row["case"]: row["clocked_error_sum"] for row in rows if row["method"] == "current-lqr"}
    for row, response in zip(rows, saved["responses"]):
        row["cost_ratio_lqr"] = row["cost"] / denominators[row["case"]]
        row["clocked_error_ratio_lqr"] = row["clocked_error_sum"] / clocked_denominators[row["case"]]
        checks.near("cost ratio", response["cost_ratio_lqr"], row["cost_ratio_lqr"])
        checks.near("clocked tracking ratio", response["clocked_error_ratio_lqr"], row["clocked_error_ratio_lqr"])
    for name, method in methods.items():
        training = [r for r in rows if r["method"] == name and r["split"] == "training"]
        costs = np.array([denominators[c["name"]] for c in cases[:6]])
        verify_training_score(method["training_score"], training, np.array(method["K"]), costs, checks)
        if name in strategies:
            verify_training_score(strategies[name]["training_score"], training,
                                  np.array(method["K"]), costs, checks)
    summaries = []
    for name in METHODS:
        for split in ("training", "withheld", "historical-stress"):
            rs = [r for r in rows if r["method"] == name and r["split"] == split]
            ratios = np.array([r["cost_ratio_lqr"] for r in rs])
            settling = [r["sustained_cycle"] for r in rs]
            complete = all(x is not None for x in settling)
            clocked_ratios = np.array([r["clocked_error_ratio_lqr"] for r in rs])
            clocked_settling = [r["clocked_sustained_time_ms"] for r in rs]
            clocked_complete = all(x is not None for x in clocked_settling)
            summaries.append(dict(method=name, split=split, cases=len(rs),
                                  mean_cost_ratio_lqr=float(ratios.mean()),
                                  worst_cost_ratio_lqr=float(ratios.max()), best_cost_ratio_lqr=float(ratios.min()),
                                  cost_regressions=int(np.count_nonzero(ratios > 1+1e-8)),
                                  mean_sustained_cycle=float(np.mean(settling)) if complete else None,
                                  worst_sustained_cycle=max(settling) if complete else None,
                                  mean_clocked_error_ratio_lqr=float(clocked_ratios.mean()),
                                  worst_clocked_error_ratio_lqr=float(clocked_ratios.max()),
                                  clocked_error_regressions=int(np.count_nonzero(clocked_ratios > 1+1e-8)),
                                  mean_clocked_sustained_time_ms=float(np.mean(clocked_settling)) if clocked_complete else None,
                                  worst_clocked_sustained_time_ms=max(clocked_settling) if clocked_complete else None,
                                  clocked_unsettled_cases=sum(x is None for x in clocked_settling),
                                  maximum_final_reference_error=max(r["final_reference_error"] for r in rs)))
    checks.require("summary count", len(saved["summaries"]) == 24)
    for actual, expected in zip(saved["summaries"], summaries):
        for key, value in expected.items():
            if isinstance(value, str) or value is None:
                checks.require("summary " + key, actual[key] == value)
            else:
                checks.near("summary " + key, actual[key], value)
    verify_csv(results / "metrics.csv", rows, METRIC_FIELDS, checks)
    verify_csv(results / "summary.csv", summaries, SUMMARY_FIELDS, checks)
    # Catch a concurrent rewrite during verification rather than bless mixed generations.
    verify_hashes(saved["source_sha256"], ROOT, checks)
    for path, expected in snapshots.items():
        checks.require("evidence unchanged during verification", digest(path) == expected)
    paths = required + [comparison_path, results / "metrics.csv", results / "summary.csv",
                        Path(__file__), HERE / "test_verifier.py", OLD.parent / "requirements.txt",
                        ROOT / "studies/s1-lyapunov/python/build_tutorial.py",
                        ROOT / "studies/s1-lyapunov/python/optimization.py"]
    return dict(status="passed", methods=8, certified_methods=7, cases=20, trajectories=160, completed_exact_cycles=16000,
                historical_marcolino_reproduced_cases=3, snapshot_bound_optimized_strategies=5,
                historical_mpc_imported_cases=3, historical_mpc_new_optimizations=0,
                check_counts=dict(checks.counts), maximum_absolute_errors=checks.max_errors,
                source_sha256={p.relative_to(ROOT).as_posix(): digest(p) for p in paths},
                scope="Floating-point checks of saved evidence. Common-P covers seven uniform linearized methods only, not variable-period Marcolino. Exact trajectories are simulations; anchor J100 and common-clock tracking-only sums are distinct.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-validation", action="store_true",
                        help="write results/validation.json only after every check passes")
    args = parser.parse_args()
    if not (HERE / "results/comparison.json").is_file():
        print("Pending: results/comparison.json is absent. No validation was written.", file=sys.stderr)
        return 2
    validation = verify()
    if args.write_validation:
        (HERE / "results/validation.json").write_text(json.dumps(validation, indent=2) + "\n", encoding="utf-8")
    print("Verified 8 methods, 160 trajectories, 16000 exact cycles; 7 uniform common-P checks; Marcolino history reproduced on 3 cases.")
    print(f"Maximum independent one-cycle state error: {validation['maximum_absolute_errors']['exact one-cycle state']:.3e}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
