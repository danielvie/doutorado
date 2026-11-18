"""Focused verifier regressions. Temporary files only; no production output writes."""

import copy
import json
import tempfile
import unittest
from pathlib import Path

import numpy as np
from scipy.linalg import null_space

import verify_results as v


def method_fixture(model):
    legacy = v.read_json(v.OLD / "synthesis.json")["current"]
    K, P = np.array(legacy["K"]), np.array(legacy["P"])
    P = 3*P/np.trace(P)
    margins = [v.mineig(P-M.T @ P @ M) for M in (model.A, model.A-model.B @ K)]
    return dict(K=K, P=P, Kphysical=model.ts*np.linalg.solve(model.S.T, K.T).T,
                certificate=dict(min_eigenvalue_P=v.mineig(P), endpoint_decreases=margins,
                                 trace_P=float(np.trace(P)), condition_number_P=float(np.linalg.cond(P)),
                                 raw_radius=float(max(abs(np.linalg.eigvals(model.A-model.B @ K))))))


def response_fixture(model, K, case, policy="uniform"):
    states = np.empty((3, 101))
    states[:, 0] = model.anchor + model.S @ case["z"]
    raw, applied, dwell = np.empty((8, 100)), np.empty((8, 100)), np.empty((9, 100))
    beta, stage = np.ones(100), np.empty(100)
    for k in range(100):
        z = np.linalg.solve(model.S, states[:, k]-model.anchor)
        raw[:, k] = -model.ts*K @ z
        if policy == "marcolino":
            # A direct boundary recursion, separate from the verifier helper.
            nominal = np.r_[0., np.cumsum(model.dwell)]
            actual = np.zeros(10)
            for i in range(1, 9):
                actual[i] = max(nominal[i]+raw[i-1, k], actual[i-1]+3e-6)
            actual[-1] = max(nominal[-1], actual[-2]+3e-6)
            applied[:, k] = actual[1:-1]-nominal[1:-1]
            dwell[:, k] = np.diff(actual)
            state = np.r_[states[:, k], 1.]
            for generator, duration in zip(model.F, dwell[:, k]):
                state = v.expm(generator*duration) @ state
            states[:, k+1] = state[:3]
        else:
            q = model.D @ raw[:, k]
            bounds = [(model.dwell[i]-3e-6)/-value for i, value in enumerate(q) if value < 0]
            beta[k] = min([1.] + bounds)
            applied[:, k] = beta[k]*raw[:, k]
            dwell[:, k] = model.dwell + model.D @ applied[:, k]
            states[:, k+1] = model.propagate(model.cycle, states[:, k], applied[:, k])
        stage[k] = z @ z + .001*np.sum((applied[:, k]/model.ts)**2)
    errors = np.linalg.norm(np.linalg.solve(model.S, states-model.anchor[:, None]), axis=0)
    first, sustained = v.thresholds(errors)
    response = dict(policy=policy, states=states, errors=errors, raw_offsets=raw, applied_offsets=applied,
                dwells=dwell, beta=beta, stage_cost=stage, cost=float(stage.sum()),
                first_cycle=first, sustained_cycle=sustained, final_error=errors[-1],
                minimum_dwell_us=float(dwell.min()*1e6),
                minimum_raw_dwell_us=float((model.dwell[:, None]+model.D @ raw).min()*1e6),
                minimum_beta=float(beta.min()), conditioned_cycles=int(np.count_nonzero(beta < 1-1e-12)),
                cycle_sample_minimum_state=states.min(axis=1))
    response.update(v.timing_values(model, states, dwell, sustained))
    if policy == "marcolino":
        response.update(beta=None, minimum_beta=None,
                        conditioned_cycles=int(np.count_nonzero(np.any(abs(applied-raw) > 1e-12, axis=0) |
                                                               (response["terminal_extensions"] > 1e-12))))
    return response


class VerifierTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.model = v.load_model()
        cls.method = method_fixture(cls.model)
        cls.case = v.expected_cases(cls.model)[0]
        cls.response = response_fixture(cls.model, cls.method["K"], cls.case)
        cls.marcolino = response_fixture(cls.model, cls.method["K"], cls.case, "marcolino")
        cls.marcolino_method = dict(K=cls.method["K"].copy(), Kphysical=cls.method["Kphysical"].copy(),
                                   P=None, certificate=None, policy="marcolino",
                                   certificate_status="not-covered-variable-period")

    def reject_certificate(self, mutation):
        method = copy.deepcopy(self.method)
        mutation(method)
        with self.assertRaises(v.VerificationError):
            v.verify_certificate(method, self.model, v.Checks())

    def reject_response(self, mutation):
        response = copy.deepcopy(self.response)
        mutation(response)
        with self.assertRaises(v.VerificationError):
            v.verify_response(response, self.method["K"], self.case, self.model, v.Checks())

    def reject_marcolino(self, mutation):
        response = copy.deepcopy(self.marcolino)
        mutation(response)
        with self.assertRaises(v.VerificationError):
            v.verify_response(response, self.method["K"], self.case, self.model, v.Checks(), "marcolino")

    def test_saved_baseline_certificate_accepted(self):
        v.verify_certificate(self.method, self.model, v.Checks())

    def test_negative_P_rejected(self):
        self.reject_certificate(lambda m: m.update(P=-np.eye(3)))

    def test_positive_but_invalid_P_rejected(self):
        self.reject_certificate(lambda m: m.update(P=np.eye(3)))

    def test_asymmetric_P_rejected(self):
        def mutate(m):
            m["P"][0, 1] += .001
        self.reject_certificate(mutate)

    def test_unnormalized_P_rejected_not_silently_repaired(self):
        self.reject_certificate(lambda m: m.update(P=2*m["P"]))

    def test_tampered_physical_gain_rejected(self):
        def mutate(m):
            m["Kphysical"][0, 0] += 1e-8
        self.reject_certificate(mutate)

    def test_tampered_normalized_gain_rejected(self):
        self.reject_certificate(lambda m: m.update(K=-100*m["K"]))

    def test_nonfinite_gain_rejected(self):
        self.reject_certificate(lambda m: m.update(K=np.full((8, 3), np.nan)))

    def test_stale_certificate_metadata_rejected(self):
        def mutate(m):
            m["certificate"]["endpoint_decreases"][1] += .001
        self.reject_certificate(mutate)

    def test_independent_model_rejects_altered_matrices(self):
        m = self.model
        saved = dict(A=m.A.copy(), B=m.B.copy(), S=m.S.copy(), timing_scale=m.ts,
                     anchor=m.anchor.copy(), nominal_dwell=m.dwell.copy(), D=m.D.copy(),
                     generators=np.array(m.F))
        v.verify_model(saved, m, v.Checks())
        for key in ("A", "B", "generators"):
            altered = copy.deepcopy(saved)
            altered[key].flat[0] += .01
            with self.assertRaises(v.VerificationError):
                v.verify_model(altered, m, v.Checks())

    def test_full_exact_fixture_accepted_and_counts_100_cycles(self):
        checks = v.Checks()
        v.verify_response(self.response, self.method["K"], self.case, self.model, checks)
        self.assertEqual(checks.counts["exact one-cycle state"], 100)
        self.assertLess(checks.max_errors["exact one-cycle state"], 1e-12)

    def test_raw_command_tampering_rejected(self):
        def mutate(r):
            r["raw_offsets"][0, 0] += 1e-6
        self.reject_response(mutate)

    def test_applied_command_tampering_rejected(self):
        def mutate(r):
            r["applied_offsets"][0, 0] += 1e-6
        self.reject_response(mutate)

    def test_feasible_but_nonmaximal_beta_rejected(self):
        def mutate(r):
            r["beta"][0] *= .5
            r["applied_offsets"][:, 0] = r["beta"][0]*r["raw_offsets"][:, 0]
            r["dwells"][:, 0] = self.model.dwell + self.model.D @ r["applied_offsets"][:, 0]
        self.reject_response(mutate)

    def test_dwell_tampering_rejected(self):
        def mutate(r):
            r["dwells"][0, 0] += 1e-6
        self.reject_response(mutate)

    def test_exact_state_tampering_rejected(self):
        def mutate(r):
            r["states"][0, -1] += .01
            # Also change derived errors, so exact propagation must reject it.
            z = np.linalg.solve(self.model.S, r["states"]-self.model.anchor[:, None])
            r["errors"] = np.linalg.norm(z, axis=0)
        self.reject_response(mutate)

    def test_terminal_penalty_or_wrong_weights_rejected(self):
        self.reject_response(lambda r: r.update(cost=r["cost"]+.1))
        self.reject_response(lambda r: r.update(stage_cost=2*r["stage_cost"]))

    def test_wrong_threshold_rejected(self):
        self.reject_response(lambda r: r.update(sustained_cycle=r["sustained_cycle"]+1))

    def test_horizon_shape_rejected(self):
        self.reject_response(lambda r: r.update(states=r["states"][:, :-1]))

    def test_first_and_sustained_strict_thresholds(self):
        self.assertEqual(v.thresholds(np.array([.02, .009, .01, .008])), (1, 3))
        self.assertEqual(v.thresholds(np.array([.02, .009, .01])), (1, None))
        self.assertEqual(v.thresholds(np.array([.02, .01])), (None, None))
        self.assertEqual(v.thresholds(np.array([.009, .008])), (0, 0))

    def test_case_contract(self):
        cases = v.expected_cases(self.model)
        self.assertEqual(len(cases), 20)
        self.assertEqual([sum(c["split"] == split for c in cases) for split in
                          ("training", "withheld", "historical-stress")], [6, 12, 2])
        np.testing.assert_allclose(cases[1]["z"], -cases[0]["z"])
        np.testing.assert_allclose(cases[-1]["z"], 3*cases[0]["z"])
        self.assertTrue(all(np.min(self.model.anchor+self.model.S @ c["z"]) > 0 for c in cases[:18]))
        self.assertTrue(all((self.model.anchor+self.model.S @ c["z"])[2] < 0 for c in cases[18:]))

    def test_stale_and_missing_source_hashes_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "source.jl"
            source.write_text("original", encoding="utf-8")
            manifest = {"source.jl": v.digest(source)}
            v.verify_hashes(manifest, root, v.Checks(), ["source.jl"])
            source.write_text("altered", encoding="utf-8")
            with self.assertRaises(v.VerificationError):
                v.verify_hashes(manifest, root, v.Checks())
            with self.assertRaises(v.VerificationError):
                v.verify_hashes(manifest, root, v.Checks(), ["omitted.jl"])
            with self.assertRaises(v.VerificationError):
                v.verify_hashes({"../outside": "0"*64}, root, v.Checks())

    def test_invalid_json_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "evidence.json"
            for content in ('{"K":1,"K":2}', '{"P":NaN}'):
                path.write_text(content, encoding="utf-8")
                with self.assertRaises(v.VerificationError):
                    v.read_json(path)

    def test_csv_identity_and_cost_tampering_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "metrics.csv"
            path.write_text("method,cost\ncurrent-lqr,1.0\n", encoding="utf-8")
            expected = [dict(method="current-lqr", cost=1.)]
            v.verify_csv(path, expected, ("method", "cost"), v.Checks())
            for content in ("method,cost\nother,1.0\n", "method,cost\ncurrent-lqr,2.0\n"):
                path.write_text(content, encoding="utf-8")
                with self.assertRaises(v.VerificationError):
                    v.verify_csv(path, expected, ("method", "cost"), v.Checks())

    def test_strategy4_independent_nullspace_recovery_and_rejection(self):
        old = v.read_json(v.OLD / "synthesis.json")
        K0, P0 = (np.array(old["candidates"]["decay"][k]) for k in ("K", "P"))
        N, Z = null_space(self.model.B), np.full((5, 3), .1)
        result = dict(name="strategy-4", K0=K0, N=N, Z=Z, K=K0+N @ Z,
                      P=3*P0/np.trace(P0))
        v.verify_strategy_extras(result, self.model, old, v.Checks())
        result["K"][0, 0] += .01
        with self.assertRaises(v.VerificationError):
            v.verify_strategy_extras(result, self.model, old, v.Checks())

    def test_marcolino_fixture_accepted_and_exact_cycles_counted(self):
        checks = v.Checks()
        v.verify_marcolino(self.marcolino_method, self.method["K"], self.model, checks)
        values = v.verify_response(self.marcolino, self.method["K"], self.case, self.model, checks, "marcolino")
        self.assertEqual(checks.counts["exact one-cycle state"], 100)
        self.assertGreater(values["total_boundary_delay_us"], 0)
        self.assertGreater(values["clocked_error_sum"], np.sum(self.marcolino["errors"][:-1]**2))
        self.assertIsNone(values["minimum_beta"])
        self.assertEqual(v.METHODS[-1], "strategy-marcolino")
        self.assertEqual(len(v.METHODS), 8)

    def test_marcolino_sequential_rule_hand_checks(self):
        raw = np.zeros(8)
        raw[-1] = 100e-6
        dwell, applied, extension = v.sequential_dwells(self.model, raw)
        self.assertAlmostEqual(applied[-1], raw[-1])
        self.assertAlmostEqual(dwell[-1], 3e-6)
        self.assertGreater(extension, 0)
        self.assertAlmostEqual(dwell.sum(), sum(self.model.dwell)+extension)
        raw = np.full(8, -1.)
        dwell, _, extension = v.sequential_dwells(self.model, raw)
        np.testing.assert_allclose(dwell[:-1], 3e-6, atol=1e-15)
        self.assertAlmostEqual(extension, 0.)

    def test_marcolino_silent_period_truncation_rejected(self):
        def mutate(r):
            r["dwells"][-1] -= r["terminal_extensions"]
            r["terminal_extensions"][:] = 0
        self.reject_marcolino(mutate)
        self.reject_marcolino(lambda r: r.update(cycle_times=np.arange(101)*sum(self.model.dwell)))

    def test_marcolino_forged_certificate_and_altered_gain_rejected(self):
        for mutation in (lambda m: m.update(P=self.method["P"]),
                         lambda m: m.update(certificate=self.method["certificate"]),
                         lambda m: m.update(certificate_status="covered"),
                         lambda m: m.update(policy="uniform"),
                         lambda m: m.update(K=1.01*m["K"]),
                         lambda m: m.update(Kphysical=1.01*m["Kphysical"])):
            method = copy.deepcopy(self.marcolino_method)
            mutation(method)
            with self.assertRaises(v.VerificationError):
                v.verify_marcolino(method, self.method["K"], self.model, v.Checks())

    def test_marcolino_fake_beta_rejected(self):
        self.reject_marcolino(lambda r: r.update(beta=np.ones(100)))
        self.reject_marcolino(lambda r: r.update(minimum_beta=1.))

    def test_marcolino_phase_reset_reference_rejected(self):
        self.reject_marcolino(lambda r: r.update(reference_errors=r["errors"].copy()))

    def test_marcolino_wrong_common_grid_state_rejected(self):
        self.reject_marcolino(lambda r: r.update(clocked_states=r["states"].copy()))
        def mutate(r):
            r["clocked_states"][0, 1] += .01
            r["clocked_errors"] = np.linalg.norm(np.linalg.solve(
                self.model.S, r["clocked_states"]-self.model.anchor[:, None]), axis=0)
        self.reject_marcolino(mutate)
        self.reject_marcolino(lambda r: r.update(clocked_times=r["cycle_times"].copy()))

    def test_marcolino_clocked_sum_and_thresholds_rejected(self):
        self.reject_marcolino(lambda r: r.update(clocked_error_sum=float(np.sum(r["errors"][:-1]**2))))
        self.reject_marcolino(lambda r: r.update(clocked_error_sum=float(np.sum(r["clocked_errors"]**2))))
        self.reject_marcolino(lambda r: r.update(clocked_error_sum=r["cost"]))
        self.reject_marcolino(lambda r: r.update(cost=r["clocked_error_sum"]))
        self.reject_marcolino(lambda r: r.update(policy="uniform"))
        for key in ("anchor_sustained_time_ms", "clocked_sustained_time_ms", "final_reference_error"):
            self.reject_marcolino(lambda r, key=key: r.update({key: 123.}))

    def test_exact_partial_propagation_on_common_grid(self):
        model, response = self.model, self.marcolino
        period = float(sum(model.dwell))
        # At T the first realized cycle is still running. Propagate from its
        # preceding mode boundary, rather than from a resampled cycle state.
        boundaries = np.r_[0., np.cumsum(response["dwells"][:, 0])]
        interval = int(np.searchsorted(boundaries, period, side="right")-1)
        state = np.r_[response["states"][:, 0], 1.]
        for i in range(interval):
            state = v.expm(model.F[i]*response["dwells"][i, 0]) @ state
        state = v.expm(model.F[interval]*(period-boundaries[interval])) @ state
        np.testing.assert_allclose(response["clocked_states"][:, 1], state[:3], atol=1e-12, rtol=0)
        self.assertGreater(np.linalg.norm(state[:3]-response["states"][:, 1]), .01)
        self.assertEqual(response["sustained_cycle"], 4)
        self.assertIsNone(response["clocked_sustained_sample"])

    def test_marcolino_all_three_saved_matlab_histories_reproduced(self):
        responses = []
        for scale in (1, 2, 3):
            case = dict(self.case, z=scale*np.array(self.case["z"]))
            response = (copy.deepcopy(self.marcolino) if scale == 1 else
                        response_fixture(self.model, self.method["K"], case, "marcolino"))
            v.verify_response(response, self.method["K"], case, self.model, v.Checks(), "marcolino")
            response.update(method="strategy-marcolino", case=f"article-{scale}x")
            responses.append(response)
        v.verify_marcolino_history(responses, v.Checks())
        responses[0]["reference_errors"][1] += .001
        with self.assertRaises(v.VerificationError):
            v.verify_marcolino_history(responses, v.Checks())

    def test_five_optimization_results_bound_to_comparison_manifest(self):
        comparison = v.read_json(v.HERE / "results/comparison.json")
        required = [f"studies/s3-gain-strategies/results/strategy-{i}.json" for i in range(1, 6)]
        manifest = comparison["source_sha256"]
        v.verify_hashes(manifest, v.ROOT, v.Checks(), required)

    def test_regenerated_result_requires_renewed_manifest_not_original_bytes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            result = root / "strategy-1.json"
            result.write_text(json.dumps(dict(elapsed_seconds=1.)), encoding="utf-8")
            manifest = {result.name: v.digest(result)}
            v.verify_hashes(manifest, root, v.Checks(), [result.name])
            result.write_text(json.dumps(dict(elapsed_seconds=2.)), encoding="utf-8")
            with self.assertRaises(v.VerificationError):
                v.verify_hashes(manifest, root, v.Checks())
            manifest[result.name] = v.digest(result)
            v.verify_hashes(manifest, root, v.Checks(), [result.name])

    def test_available_strategy2_accepted_cost_variables_and_tampered_P(self):
        path = v.HERE / "results/strategy-2.json"
        if not path.is_file():
            self.skipTest("strategy-2 saved evidence pending")
        result = v.read_json(path)
        candidates = [r["synthesis"] for r in result["candidate_log"] if r.get("accepted") and "synthesis" in r]
        if not candidates:
            self.skipTest("no accepted strategy-2 synthesis variables")
        raw = copy.deepcopy(candidates[0])
        v.verify_strategy2(raw, self.model, v.Checks())
        raw["P_cost"] = -np.eye(3)
        with self.assertRaises(v.VerificationError):
            v.verify_strategy2(raw, self.model, v.Checks())

    def test_available_strategy3_accepted_variables_and_tampered_effort(self):
        path = v.HERE / "results/strategy-3.json"
        if not path.is_file():
            self.skipTest("strategy-3 saved evidence pending")
        result = v.read_json(path)
        candidates = [r["synthesis"] for r in result["candidate_log"] if r.get("verification", {}).get("accepted")]
        if not candidates:
            self.skipTest("no accepted strategy-3 synthesis variables")
        raw = copy.deepcopy(candidates[0])
        v.verify_strategy3(raw, self.model, v.Checks())
        for key, value in (("U", -np.eye(8)), ("t", -1.)):
            altered = copy.deepcopy(raw)
            altered[key] = value
            with self.assertRaises(v.VerificationError):
                v.verify_strategy3(altered, self.model, v.Checks())


if __name__ == "__main__":
    unittest.main()
