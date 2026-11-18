"""Independent saved-evidence checks; read-only unless --write-validation is set."""

import argparse
import csv
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
from scipy.io import loadmat
from scipy.linalg import eigvalsh, solve_discrete_are, solve_discrete_lyapunov

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RESULTS = HERE / "results"
METHODS = ("current", "mpc5", "kawa_decay")
LEGACY_METHODS = METHODS + ("kawa_cost",)


def read_rows(name):
    with (RESULTS / name).open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def group(rows, method, scale):
    return [row for row in rows if row["method"] == method and int(row["error_scale"]) == scale]


def column(rows, key):
    return np.array([float(row[key]) for row in rows])


def close(actual, expected, atol=1e-9):
    np.testing.assert_allclose(actual, expected, rtol=1e-9, atol=atol, equal_nan=True)


def verify_response_order(rows, methods, rows_per_method):
    identities = [(row["method"], int(row["error_scale"])) for row in rows]
    expected = [(method, scale) for scale in (1, 2, 3) for method in methods
                for _ in range(rows_per_method)]
    assert identities == expected, "CSV response identities/order disagree with MAT names"


def verify_certificates(s):
    A, B, S = (np.array(s[key]) for key in ("A", "B", "state_scale"))
    I = np.eye(A.shape[0])
    candidates = {"current": s["current"], "kawa_decay": s["candidates"]["decay"]}
    if "cost" in s["candidates"]:
        candidates["kawa_cost"] = s["candidates"]["cost"]
    for method, c in candidates.items():
        K, P = np.array(c["K"]), np.array(c["P"])
        close(P, P.T, 1e-12)
        assert eigvalsh(P)[0] > 0
        margins = [eigvalsh(P - M.T @ P @ M)[0] for M in (A, A - B @ K)]
        assert min(margins) > 1e-9
        close(margins, c["endpoint_decreases"], 1e-10)
        close(c["Kphysical"], s["timing_scale"] * K @ np.linalg.solve(S, I), 1e-13)
        if method != "current":
            X, Y = np.array(c["X"]), np.array(c["Y"])
            close(K @ X, Y, 1e-10)
            close(P @ X, I, 1e-9)
        if method == "kawa_decay":
            assert abs(np.trace(X) - 3) < 1e-7
            rate = c["rate"]
            for M in (A, A - B @ K):
                assert eigvalsh(rate * rate * P - M.T @ P @ M)[0] > 1e-9
            assert c["bisection_upper"] - c["bisection_lower"] <= c["bisection_tolerance"]
            assert c["bisection_lower"] >= max(abs(np.linalg.eigvals(A))) - 1e-12
            assert c["zero_gain_same_rate_feasible"] and c["zero_gain_min_rate_residual"] > 0
        if method == "kawa_cost":
            Q = I + 0.001 * K.T @ K
            Ac = A - B @ K
            residual = P - Ac.T @ P @ Ac - Q
            assert eigvalsh(residual)[0] > 1e-8
            close(eigvalsh(residual)[0], c["min_raw_cost_residual"], 1e-11)
            assert eigvalsh(c["open_rate"]**2 * P - A.T @ P @ A)[0] > 0
            policy_cost = solve_discrete_lyapunov(Ac.T, Q)
            lqr_cost = solve_discrete_are(A, B, I, 0.001 * np.eye(B.shape[1]))
            assert eigvalsh(P - policy_cost)[0] > -1e-7
            assert eigvalsh(policy_cost - lqr_cost)[0] > -1e-7
    study_prefix = (ROOT / "studies").relative_to(ROOT.parents[2]).as_posix() + "/"
    for relative, digest in s["source_sha256"].items():
        paths = [ROOT.parents[2] / relative]
        # The historical manifest predates the study directory renames.
        for old, new in (("lyapunov", "s1-lyapunov"), ("mpc-comparison", "s1-mpc-comparison")):
            prefix = study_prefix + old + "/"
            if relative.startswith(prefix):
                paths.append(ROOT / "studies" / new / relative[len(prefix):])
        if relative in (study_prefix + "kawa-synthesis/synthesize.py",
                        study_prefix + "s2-kawa-synthesis/synthesize.py"):
            # Retained evidence must match an exact historical producer, not the Julia port.
            paths += [HERE / "archive/synthesize-four-controller.py",
                      HERE / "archive/synthesize-decay.py"]
        assert any(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == digest
                   for path in paths), f"Stale synthesis input: {relative}"
    return candidates


def verify_simulations(s, candidates):
    # The existing independent Python reconstruction is imported read-only.
    sys.path.insert(0, str(ROOT / "studies/s1-lyapunov/python"))
    from build_tutorial import build_cycle_model, propagate_exact_cycle
    model = build_cycle_model()
    S, ts = np.array(s["state_scale"]), s["timing_scale"]
    A, B = np.array(s["A"]), np.array(s["B"])
    close(np.linalg.solve(S, model.Phi @ S), A, 1e-11)
    close(np.linalg.solve(S, model.Gtau) * ts, B, 1e-11)
    saved = loadmat(RESULTS / "comparison.mat", struct_as_record=False, squeeze_me=True)
    summary, history, commands = [read_rows(name) for name in ("summary.csv", "history.csv", "commands.csv")]
    trajectories = read_rows("trajectories.csv")
    methods = tuple(str(name) for name in np.atleast_1d(saved["names"]))
    assert methods in (METHODS, LEGACY_METHODS), f"Unexpected saved method order: {methods}"
    assert saved["responses"].shape == (3, len(methods))
    assert all(method in candidates for method in methods if method != "mpc5")
    verify_response_order(summary, methods, 1)
    verify_response_order(history, methods, 101)
    verify_response_order(commands, methods, 900)
    verify_response_order(trajectories, ("reference",) + methods, 12 * 9 * 30 + 1)
    gains = read_rows("gains_normalized.csv")
    gain_methods = tuple(dict.fromkeys(row["method"] for row in gains))
    active_gains = tuple(method for method in methods if method != "mpc5")
    assert gain_methods in (active_gains, tuple(candidates))
    assert [row["method"] for row in gains] == [method for method in gain_methods for _ in range(8)]
    for method in gain_methods:
        candidate = candidates[method]
        rows = [row for row in gains if row["method"] == method]
        close(column(rows, "switching_instant"), np.arange(1, 9))
        close(np.array([column(rows, key) for key in ("k_z1", "k_z2", "k_z3")]).T,
              candidate["K"], 1e-12)
    largest_exact_error = 0.0
    baseline_state = np.array([7.5143, 20.8211, 0.0314])
    for scale in (1, 2, 3):
        for index, method in enumerate(methods):
            r = saved["responses"][scale - 1, index]
            close(r.states[:, 0], model.anchor + scale * (baseline_state - model.anchor), 1e-12)
            errors = np.linalg.norm(np.linalg.solve(S, r.states - model.anchor[:, None]), axis=0)
            close(errors, r.error, 1e-12)
            close(r.dwell, model.dwell[:, None] + model.dwell_map @ r.applied_offsets, 1e-13)
            close(r.raw_dwell, model.dwell[:, None] + model.dwell_map @ r.raw_offsets, 1e-13)
            assert np.min(r.dwell) >= 3e-6 - 1e-12
            close(np.sum(r.dwell, axis=0), 286e-6, 1e-13)
            for k in range(100):
                state = propagate_exact_cycle(model, r.states[:, k], r.applied_offsets[:, k])
                error = float(np.max(abs(state - r.states[:, k + 1])))
                largest_exact_error = max(largest_exact_error, error)
                assert error < 1e-9
                if method == "mpc5":
                    close(r.raw_offsets[:, k], r.applied_offsets[:, k], 1e-13)
                    assert np.isnan(r.beta[k]) and r.exitflag[k] == 1
                else:
                    K, P = np.array(candidates[method]["K"]), np.array(candidates[method]["P"])
                    z = np.linalg.solve(S, r.states[:, k] - model.anchor)
                    close(r.raw_offsets[:, k], -ts * K @ z, 1e-13)
                    q = model.dwell_map @ r.raw_offsets[:, k]
                    shortening = q < 0
                    beta = min(1.0, float(np.min((model.dwell[shortening] - 3e-6) / -q[shortening]))) if shortening.any() else 1.0
                    close(r.beta[k], beta, 1e-12)
                    close(r.applied_offsets[:, k], beta * r.raw_offsets[:, k], 1e-13)
                    linear_next = A @ z + B @ (r.applied_offsets[:, k] / ts)
                    assert linear_next @ P @ linear_next <= z @ P @ z + 1e-11
            stage = errors[:-1]**2 + 0.001 * np.sum((r.applied_offsets / ts)**2, axis=0)
            cost = float(np.sum(stage))
            first = np.flatnonzero(errors < .01)
            bad = np.flatnonzero(errors >= .01)
            first = float(first[0]) if first.size else np.nan
            sustained = 0.0 if not bad.size else float(bad[-1] + 1) if bad[-1] < 100 else np.nan
            row = group(summary, method, scale)[0]
            assert int(row["completed_cycles"]) == 100
            close(float(row["evaluation_cost"]), cost, 1e-10)
            close(float(row["first_cycle_below_001"]), first)
            close(float(row["sustained_cycle_below_001"]), sustained)
            close(float(row["minimum_dwell_us"]), np.min(r.dwell) * 1e6, 1e-8)
            close(float(row["minimum_raw_dwell_us"]), np.min(r.raw_dwell) * 1e6, 1e-8)
            close(float(row["final_error"]), errors[-1], 1e-12)
            h = group(history, method, scale)
            close(column(h, "cycle"), np.arange(101))
            close(column(h, "normalized_error"), errors, 1e-12)
            close(column(h, "stage_cost")[:-1], stage, 1e-10)
            close(column(h, "cumulative_cost"), np.r_[0, np.cumsum(stage)], 1e-10)
            command = group(commands, method, scale)
            close(column(command, "applied_dwell_us").reshape(9, 100, order="F"), r.dwell * 1e6, 1e-8)
            close(column(command, "raw_dwell_us").reshape(9, 100, order="F"), r.raw_dwell * 1e6, 1e-8)
            dense = group(trajectories, method, scale)
            assert len(dense) == 12 * 9 * 30 + 1
            assert np.all(np.diff(column(dense, "time_ms")) > 0)
            close([float(dense[-1][field]) for field in ("vc1_v", "vc2_v", "il_a")], r.states[:, 12], 1e-9)
    return largest_exact_error, methods


def verify_timing(methods):
    assert methods in (METHODS, LEGACY_METHODS)
    rows = read_rows("timing_samples.csv")
    summary = read_rows("timing.csv")
    states = read_rows("timing_states.csv")
    nstates, nmethods = len(states), len(methods)
    assert nstates == 12 * nmethods
    close(column(states, "state_index"), np.arange(1, nstates + 1))
    assert [row["source_method"] for row in states] == [method for method in methods for _ in range(12)]
    close(column(states, "source_cycle"), np.tile(np.arange(12), nmethods))
    assert [row["method"] for row in summary] == list(methods)
    assert len(rows) == nmethods * nstates * 20
    for method in methods:
        samples = [row for row in rows if row["method"] == method]
        row = next(row for row in summary if row["method"] == method)
        elapsed = column(samples, "elapsed_us")
        assert len(samples) == int(row["samples"]) == nstates * 20
        assert int(row["warmup_calls"]) == nstates * 2
        assert np.all(np.isfinite(elapsed)) and np.min(elapsed) > 0
        close(float(row["median_us"]), np.median(elapsed), 1e-8)
        # MATLAB prctile uses half-sample plotting positions, NumPy's Hazen method.
        close(float(row["p95_us"]), np.percentile(elapsed, 95, method="hazen"), 1e-8)
        pairs = {(int(row["state_index"]), int(row["repeat"])) for row in samples}
        assert pairs == {(i, j) for i in range(1, nstates + 1) for j in range(1, 21)}
    return len(rows), nstates


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write-validation", action="store_true",
                        help="write validation.json after all saved-evidence checks pass")
    args = parser.parse_args()
    synthesis = json.loads((RESULTS / "synthesis.json").read_text(encoding="utf-8"))
    candidates = verify_certificates(synthesis)
    largest_exact_error, methods = verify_simulations(synthesis, candidates)
    timing_samples, timing_states = verify_timing(methods)
    trajectories = 3 * len(methods)
    cycles = trajectories * 100
    sources = [HERE / "analysis.jl", ROOT / "studies/s1-lyapunov/Project.toml",
               ROOT / "studies/s1-lyapunov/Manifest.toml"]
    sources += [HERE / name for name in ("simulate_comparison.m", "benchmark_timing.m", "verify_results.py")]
    result = dict(status="passed", controllers=len(methods), scenarios=3,
                  trajectories=trajectories, completed_exact_cycles=cycles,
                  timing_states=timing_states, matched_timing_samples=timing_samples,
                  maximum_independent_python_one_cycle_state_error=largest_exact_error,
                  checks=["model and gain provenance", "gain recovery and common-P endpoint inequalities",
                          "original rate residuals" + (" and cost candidate raw-policy bound" if "kawa_cost" in candidates else ""),
                          f"independent Python exact propagation of all {cycles} saved cycles",
                          "conditioner arithmetic, dwell and fixed-period feasibility",
                          "CSV/MAT identities/order, history and cost/threshold consistency",
                          "matched timing counts, medians and p95 from raw observations"],
                  source_sha256={path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in sources})
    if args.write_validation:
        (RESULTS / "validation.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Study checks passed: {trajectories} trajectories, {cycles} exact cycles, "
          f"{timing_samples} matched timing samples.")
    print(f"Independent Python one-cycle state agreement: {largest_exact_error:.3e}")


if __name__ == "__main__":
    main()
