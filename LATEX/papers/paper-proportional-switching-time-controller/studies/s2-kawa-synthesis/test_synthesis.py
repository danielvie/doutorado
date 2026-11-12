"""Focused Julia synthesis/export checks. All generated output stays temporary."""

import copy
import csv
import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import numpy as np
from scipy.linalg import eigvalsh, solve_discrete_lyapunov

from verify_results import HERE, ROOT, close, verify_certificates


class JuliaSynthesisTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.output = tempfile.TemporaryDirectory(prefix="kawa-julia-test-")
        cls.addClassCleanup(cls.output.cleanup)
        subprocess.run([
            "julia", f"--project={ROOT / 'studies/lyapunov'}", "--startup-file=no",
            "-e", "include(ARGS[1]); main(output_dir=ARGS[2])",
            str(HERE / "analysis.jl"), cls.output.name,
        ], check=True)
        cls.synthesis = json.loads((Path(cls.output.name) / "synthesis.json").read_text())

    def test_gain_and_certificate(self):
        s = self.synthesis
        candidates = verify_certificates(s)
        self.assertEqual(set(candidates), {"current", "kawa_decay"})
        self.assertEqual(s["solver"]["interface"], "Convex.jl")
        A, B = np.array(s["A"]), np.array(s["B"])
        c = s["candidates"]["decay"]
        K, P, X = (np.array(c[key]) for key in ("K", "P", "X"))
        self.assertEqual(A.shape, (3, 3))
        self.assertEqual(B.shape, (3, 8))
        self.assertEqual(K.shape, (8, 3))
        self.assertEqual(P.shape, (3, 3))
        self.assertGreaterEqual(eigvalsh(X)[0], 1e-7 - 1e-9)
        for beta in np.linspace(0, 1, 21):
            M = A - beta * B @ K
            self.assertGreater(eigvalsh(c["rate"]**2 * P - M.T @ P @ M)[0], 1e-9)
        # The rate can be compared across frontends; the feasible gain is nonunique.
        legacy = json.loads((HERE / "results/synthesis.json").read_text())["candidates"]["decay"]
        self.assertLessEqual(abs(c["rate"] - legacy["rate"]),
                             2 * max(c["bisection_tolerance"], legacy["bisection_tolerance"]))
        self.assertTrue(all(row["status"] in ("OPTIMAL", "ALMOST_OPTIMAL")
                            for row in c["bisection_history"] if row["accepted"]))
        zero_P = solve_discrete_lyapunov((A / c["rate"]).T, np.eye(3))
        zero_P *= np.trace(np.linalg.inv(zero_P)) / 3
        self.assertGreater(eigvalsh(c["rate"]**2 * zero_P - A.T @ zero_P @ A)[0], 0)

    def test_csv_matches_row_oriented_json(self):
        with (Path(self.output.name) / "gains_normalized.csv").open(newline="") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(len(rows), 16)
        for i, key in enumerate(("current", "kawa_decay")):
            candidate = (self.synthesis["current"] if key == "current" else
                         self.synthesis["candidates"]["decay"])
            section = rows[8*i:8*(i+1)]
            self.assertEqual([row["method"] for row in section], [key] * 8)
            self.assertEqual([int(row["switching_instant"]) for row in section], list(range(1, 9)))
            close([[float(row[k]) for k in ("k_z1", "k_z2", "k_z3")] for row in section],
                  candidate["K"], 1e-12)

    def test_julia_source_and_environment_are_hashed(self):
        for path in (HERE / "analysis.jl", ROOT / "studies/lyapunov/Project.toml",
                     ROOT / "studies/lyapunov/Manifest.toml"):
            key = path.relative_to(ROOT.parents[2]).as_posix()
            self.assertEqual(self.synthesis["source_sha256"][key],
                             hashlib.sha256(path.read_bytes()).hexdigest())

    def test_bad_certificate_and_provenance_are_rejected(self):
        bad = copy.deepcopy(self.synthesis)
        bad["candidates"]["decay"]["P"] = (-np.eye(3)).tolist()
        with self.assertRaises(AssertionError):
            verify_certificates(bad)
        bad = copy.deepcopy(self.synthesis)
        bad["candidates"]["decay"]["Kphysical"][0][0] += 1
        with self.assertRaises(AssertionError):
            verify_certificates(bad)
        bad = copy.deepcopy(self.synthesis)
        key = (HERE / "analysis.jl").relative_to(ROOT.parents[2]).as_posix()
        bad["source_sha256"][key] = "0" * 64
        with self.assertRaisesRegex(AssertionError, "Stale synthesis input"):
            verify_certificates(bad)


if __name__ == "__main__":
    unittest.main(verbosity=2)
