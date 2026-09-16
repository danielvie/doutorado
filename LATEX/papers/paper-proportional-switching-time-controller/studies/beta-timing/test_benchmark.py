"""Checks for the percentile definition and the saved timing evidence."""
import csv
import gzip
import hashlib
import json
from pathlib import Path
import unittest

import run
import export_latex


class TimingEvidenceTests(unittest.TestCase):
    def test_nearest_rank(self):
        self.assertEqual(run.percentile(list(range(1, 101)), .95), 95)
        self.assertEqual(run.percentile([3, 1, 2], .95), 3)
        self.assertEqual(run.percentile([7], .95), 7)

    def test_saved_summary_matches_samples(self):
        groups = {}
        for language in ("matlab", "cpp"):
            with gzip.open(run.RESULTS / f"{language}_samples.csv.gz", "rt", newline="") as f:
                for row in csv.DictReader(f):
                    key = row["implementation"], row["scenario"], row["measurement"]
                    elapsed = float(row["elapsed_ns"])
                    per_call = float(row["per_call_ns"])
                    calls = int(row["calls"])
                    self.assertGreaterEqual(elapsed, 0)
                    self.assertAlmostEqual(per_call, elapsed / calls, places=6)
                    groups.setdefault(key, []).append(per_call)
        with (run.RESULTS / "summary.csv").open(newline="") as f:
            summary = list(csv.DictReader(f))
        self.assertEqual(len(summary), 38)
        for row in summary:
            key = row["implementation"], row["scenario"], row["measurement"]
            samples = groups.pop(key)
            self.assertEqual(len(samples), int(row["samples"]))
            self.assertEqual(float(row["p95_ns"]), run.percentile(samples, .95))
            self.assertEqual(float(row["p99_ns"]), run.percentile(samples, .99))
        self.assertFalse(groups)

    def test_recorded_source_hashes_match(self):
        metadata = json.loads((run.RESULTS / "environment.json").read_text())
        for relative, expected in metadata["source_sha256"].items():
            # Evidence may have been recorded on Windows and inspected elsewhere.
            path = run.PAPER / Path(relative.replace("\\", "/"))
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), expected, str(path))

    def test_publication_macros_match_evidence(self):
        self.assertEqual(export_latex.TARGET.read_text(encoding="utf-8"), export_latex.render())

    def test_successful_numerical_validation(self):
        cpp = (run.RESULTS / "cpp_run.log").read_text()
        matlab = (run.RESULTS / "matlab_run.log").read_text()
        self.assertIn("Validated 100 cases.", cpp)
        self.assertIn("MATLAB validation passed for 100 saved cycles", matlab)


if __name__ == "__main__":
    unittest.main()
