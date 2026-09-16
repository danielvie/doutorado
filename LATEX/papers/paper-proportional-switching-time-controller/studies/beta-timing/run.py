"""Run sequential host benchmarks, retain samples, and report nearest-rank p95."""
from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import io
import json
import math
import os
from pathlib import Path
import platform
import shutil
import statistics
import subprocess
import sys
from datetime import datetime, timezone

STUDY = Path(__file__).resolve().parent
PAPER = STUDY.parents[1]
BUILD = STUDY / "build"
RESULTS = STUDY / "results"


def execute(command: list[str], log_name: str) -> str:
    print("Running:", subprocess.list2cmdline(command), flush=True)
    result = subprocess.run(command, cwd=STUDY, capture_output=True, text=True,
                            encoding="utf-8", errors="replace")
    text = result.stdout + result.stderr
    (RESULTS / log_name).write_text(text, encoding="utf-8")
    print(text, flush=True)
    result.check_returncode()
    return text


def prepare_inputs() -> Path:
    with (PAPER / "results/reference_schedule_orbit.csv").open(newline="") as f:
        schedule = list(csv.DictReader(f))
    nominal = [float(schedule[0]["start_us"])] + [float(r["end_us"]) for r in schedule]
    with (PAPER / "results/conditioned_control_response.csv").open(newline="") as f:
        response = [r for r in csv.DictReader(f) if math.isfinite(float(r["beta"]))]
    assert len(response) == 100
    output = BUILD / "inputs.csv"
    with output.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["cycle", "beta"] + [f"nominal_{i}_us" for i in range(10)] +
                        [f"raw_{i}_us" for i in range(1, 9)] +
                        [f"applied_{i}_us" for i in range(1, 9)] +
                        [f"dwell_{i}_us" for i in range(1, 10)])
        for r in response:
            writer.writerow([r["cycle"], r["beta"]] + nominal +
                            [r[f"raw_offset_{i}_us"] for i in range(1, 9)] +
                            [r[f"applied_offset_{i}_us"] for i in range(1, 9)] +
                            [r[f"applied_dwell_{i}_us"] for i in range(1, 10)])
    return output


def percentile(values: list[float], probability: float) -> float:
    """Nearest rank, sorted one-based index ceil(p*N); no interpolation."""
    ordered = sorted(values)
    return ordered[max(0, math.ceil(probability * len(ordered)) - 1)]


def summarize() -> None:
    groups: dict[tuple[str, str, str], list[float]] = {}
    call_counts: dict[tuple[str, str, str], set[int]] = {}
    for language in ("matlab", "cpp"):
        path = RESULTS / f"{language}_samples.csv"
        if path.exists():
            # Keep lossless raw timing evidence without a large uncompressed CSV.
            compressed = gzip.compress(path.read_bytes(), mtime=0)
            path.with_suffix(".csv.gz").write_bytes(compressed)
            path.unlink()
        with gzip.open(path.with_suffix(".csv.gz"), "rt", newline="") as f:
            for r in csv.DictReader(f):
                key = (r["implementation"], r["scenario"], r["measurement"])
                ns = float(r["per_call_ns"])
                assert math.isfinite(ns) and ns >= 0
                groups.setdefault(key, []).append(ns)
                call_counts.setdefault(key, set()).add(int(r["calls"]))
    rows = []
    for key, values in groups.items():
        assert len(call_counts[key]) == 1
        calls = next(iter(call_counts[key]))
        assert len(values) == (10000 if key[2] == "individual" else 500)
        assert calls == (1 if key[2] == "individual" else 200)
        rows.append(dict(implementation=key[0], scenario=key[1], measurement=key[2],
                         samples=len(values), calls_per_sample=calls,
                         min_ns=min(values), median_ns=statistics.median(values),
                         p95_ns=percentile(values, .95), p99_ns=percentile(values, .99),
                         max_ns=max(values), mean_ns=statistics.mean(values)))
    assert len(rows) == 38
    with (RESULTS / "summary.csv").open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    lookup = {(r["implementation"], r["scenario"], r["measurement"]): r for r in rows}
    variants = ["matlab_existing_conditioner", "matlab_beta_only", "cpp_double_conditioner",
                "cpp_double_beta_only", "cpp_float_us_conditioner", "cpp_float_us_beta_only"]
    report = ["# Host beta computation timing", "",
              "These are desktop MATLAB and native C++ timings, not ESP32 timings or a WCET certificate.", "",
              "## Individual-call p95", "",
              "Each entry is the nearest-rank p95 of 10,000 separately timed calls, in microseconds. "
              "Input selection and result consumption are outside each interval. Timer and call overhead remain included; "
              "no baseline subtraction was applied.", "",
              "| Implementation | Mixed 100 cycles | Conditioned 3 cycles | Unconditioned 97 cycles |",
              "| --- | ---: | ---: | ---: |"]
    for name in variants:
        vals = [lookup[(name, group, "individual")]["p95_ns"] / 1000
                for group in ("mixed_100", "conditioned_3", "unconditioned_97")]
        report.append("| " + name + " | " + " | ".join(f"{v:.6f}" for v in vals) + " |")
    report += ["", "## Batched cross-check", "",
               "Each entry is the p95 of 500 batch-average costs, in microseconds per call. "
               "Each batch contains 200 calls. This is **not** a p95 of individual-call latency. "
               "Loop, input selection, output reduction, and accumulation are included; timer overhead is amortized.", "",
               "| Implementation | Mixed | Conditioned | Unconditioned |",
               "| --- | ---: | ---: | ---: |"]
    for name in variants:
        vals = [lookup[(name, group, "batch_mean")]["p95_ns"] / 1000
                for group in ("mixed_100", "conditioned_3", "unconditioned_97")]
        report.append("| " + name + " | " + " | ".join(f"{v:.6f}" for v in vals) + " |")
    report += ["", "## Timer-only baselines", ""]
    for name in ("matlab_timer_only", "cpp_timer_only"):
        r = lookup[(name, "baseline", "individual")]
        report.append(f"- {name}: median {r['median_ns'] / 1000:.6f} µs; p95 {r['p95_ns'] / 1000:.6f} µs.")
    report += ["", "## Scope and validation", "",
               "- Existing MATLAB conditioner is unchanged and returns all three outputs, including both feasibility assertions.",
               "- Beta-only variants exclude offset scaling, applied-dwell reconstruction, and feasibility assertions. "
               "They recompute nominal margins rather than assuming a cached margin vector.",
               "- C++ double uses seconds; C++ float uses microseconds. The full C++ conditioners retain explicit checks "
               "with tolerances of 1e-12 s and 1e-4 µs, respectively. Fixed-size stack storage differs from MATLAB arrays.",
               "- All 100 saved article cases were checked against saved beta, offsets, and dwells before measurement. "
               "Zero-action, zero-margin, and invalid-schedule cases are also checked by the benchmark code.",
               "- No gain multiplication, ADC acquisition, firmware scheduling, tick quantization, waveform rendering, or "
               "plant propagation is timed. The C++ float version is not the ESP32 binary.",
               "- There are only three beta<1 cases in the saved 100-cycle trajectory. Reporting them separately avoids "
               "hiding them in a mixed p95. The workload is repeated warm inputs, not a distribution of arbitrary controller states.",
               "- Warm-up: 5,000 calls per implementation. Scenarios repeat their saved inputs in deterministic cycle order. "
               "One sequential benchmark run; no CPU affinity, frequency lock, or real-time scheduling was imposed.",
               "- Do not interpret a ratio near the timer floor as a precise algorithm speedup. Use the batch-average "
               "cross-check to see amortized cost, without relabeling it as individual-call p95.",
               "", "## Evidence", "",
               "- [Summary CSV](summary.csv), including median, p95, p99 and maximum.",
               "- Lossless raw samples: `matlab_samples.csv.gz` and `cpp_samples.csv.gz`.",
               "- [Environment and source hashes](environment.json), [MATLAB metadata](matlab_environment.json).",
               "- [C++ validation/run log](cpp_run.log), [MATLAB validation/run log](matlab_run.log).",
               "- [Method and reproduction instructions](../README.md).", ""]
    (RESULTS / "report.md").write_text("\n".join(report), encoding="utf-8")
    print("\n".join(report[:17]), flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summarize-only", action="store_true")
    args = parser.parse_args()
    RESULTS.mkdir(exist_ok=True)
    BUILD.mkdir(exist_ok=True)
    if args.summarize_only:
        summarize()
        return
    cxx = shutil.which(os.environ.get("CXX", "g++"))
    matlab = shutil.which("matlab")
    if not cxx or not matlab:
        raise RuntimeError("Both g++ (or CXX) and MATLAB must be available on PATH")
    started = datetime.now(timezone.utc).isoformat()
    inputs = prepare_inputs()
    binary = BUILD / ("beta_benchmark.exe" if os.name == "nt" else "beta_benchmark")
    compile_command = [cxx, "-O3", "-std=c++17", "-fno-lto", "-Wall", "-Wextra", "-Wpedantic",
                       "conditioner.cpp", "benchmark.cpp", "-o", str(binary)]
    compiler_version = execute([cxx, "--version"], "compiler_version.log")
    execute(compile_command, "compile.log")
    # Do not run language benchmarks concurrently: competition would distort tails.
    matlab_command = [matlab, "-batch", "benchmark_matlab('" + RESULTS.as_posix().replace("'", "''") + "')"]
    execute(matlab_command, "matlab_run.log")
    execute([str(binary), str(inputs), str(RESULTS / "cpp_samples.csv")], "cpp_run.log")
    source_paths = [PAPER / "scripts/condition_dwell_times.m",
                    PAPER / "results/conditioned_control_response.csv",
                    PAPER / "results/reference_schedule_orbit.csv",
                    STUDY / "benchmark_matlab.m", STUDY / "conditioner.hpp",
                    STUDY / "conditioner.cpp", STUDY / "benchmark.cpp", Path(__file__).resolve()]
    cpu = platform.processor()
    if os.name == "nt":
        result = subprocess.run(["powershell.exe", "-NoProfile", "-Command",
                                 "Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed | ConvertTo-Json -Compress"],
                                capture_output=True, text=True, encoding="utf-8", errors="replace")
        if result.returncode == 0:
            cpu = json.loads(result.stdout)
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=PAPER, text=True).strip()
    metadata = dict(started_utc=started, completed_utc=datetime.now(timezone.utc).isoformat(),
                    platform=platform.platform(), python=sys.version, cpu=cpu,
                    git_head=revision, compiler_version=compiler_version.strip(),
                    compile_command=compile_command, matlab_command=matlab_command,
                    percentile="nearest rank: sorted one-based index ceil(p*N)",
                    affinity="not pinned", frequency="not locked", warmup_calls=5000,
                    individual_samples_per_scenario=10000, batch_samples_per_scenario=500,
                    calls_per_batch=200, runs=1,
                    source_sha256={str(p.relative_to(PAPER)): hashlib.sha256(p.read_bytes()).hexdigest()
                                   for p in source_paths},
                    binary_sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
                    input_sha256=hashlib.sha256(inputs.read_bytes()).hexdigest())
    (RESULTS / "environment.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    summarize()


if __name__ == "__main__":
    main()
