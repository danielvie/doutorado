# Beta computation timing

Question: how much host execution time does the article's dwell conditioner take, and how does a compiled C++ port compare?

[Measured results](results/report.md) include p95, timer baselines, batch-average cross-checks, environment details, and raw samples. These are **desktop measurements, not ESP32 measurements**.

## Reproduce

From the paper root:

```sh
task beta-timing
# Or:
python studies/beta-timing/run.py
```

Requires MATLAB on PATH, Python 3.10+, and a GCC-compatible C++17 compiler. The default compiler is `g++`; `CXX` can name another compatible executable. The recorded run used MATLAB R2025b and MinGW GCC 13.2.0 on Windows with an AMD Ryzen 7 7800X3D.

The runner compiles with `-O3 -std=c++17 -fno-lto`, runs MATLAB and C++ sequentially, validates numerical results, and writes evidence into this study's `results/`. No article inputs or production controller functions are modified. Binaries and the derived C++ input CSV go into ignored `build/`.

Recalculate summaries from existing compressed samples without rerunning either benchmark:

```sh
python studies/beta-timing/run.py --summarize-only
```

Export the saved values for the article without retiming:

```sh
python studies/beta-timing/export_latex.py
python studies/beta-timing/export_latex.py --check
```

`task beta-timing` performs this export after measuring. `latex/beta_timing_metrics.tex` is a tracked publication input, generated from the summary CSV and environment records. The exporter checks the measured source hashes, sample counts, and the timer-floor interpretation used in the manuscript. It does not rerun the simulation or change its numerical evidence.

Check saved evidence and percentile implementation:

```sh
python -m unittest discover -s studies/beta-timing -p "test_*.py"
```

## What is timed

| Variant | Included |
| --- | --- |
| MATLAB existing conditioner | Unmodified `scripts/condition_dwell_times.m`, all three outputs, reshaping, nominal margins, beta, scaling, dwell reconstruction, both assertions |
| MATLAB beta only | Arithmetic extraction that calculates nominal margins and beta; no scaling, assertions, or output schedule |
| C++ double conditioner | Fixed-size port returning beta, offsets, and dwells with explicit feasibility checks; seconds and double precision |
| C++ double beta only | Nominal margins and beta arithmetic; seconds and double precision |
| C++ float conditioner | Same port in microseconds and single precision; no firmware tick conversion |
| C++ float beta only | Nominal margins and beta arithmetic in microseconds and single precision |

The C++ port uses fixed-size arrays rather than MATLAB array allocation. Its dimensions are compile-time constants for the article's nine intervals. It is not a MATLAB-to-C++ language-only comparison, and the float port is not the complete firmware function. It excludes ESP32 timing probes, tick rounding, ADC work, and waveform generation. Full-conditioner feasibility tolerances are 1e-12 seconds for double and 1e-4 microseconds for float.

The beta-only MATLAB extraction is deliberately separate from production. It reproduces the formula and is checked against the unchanged conditioner for all saved inputs. Nominal margins are recomputed in every variant, not cached offline.

## Inputs and validation

The benchmark reads the current article's `results/conditioned_control_response.csv` and `results/reference_schedule_orbit.csv`. It removes the terminal state row, whose action is NaN, leaving 100 actual actions.

Three workloads repeat those inputs in deterministic cycle order:

- `mixed_100`: all 100 saved actions.
- `conditioned_3`: the three actions with beta below one.
- `unconditioned_97`: the remaining 97 actions.

This separation matters because conditioned actions are only 3% of the mixed workload. A mixed p95 need not represent their latency. None of these workloads is a random sample of all reachable converter states.

Before timing, both languages compare beta, offsets, and dwells against saved article evidence. The C++ tolerances are 1e-12 for double beta and 1e-6 for float beta, 1e-14 seconds for double schedules, and 1e-3 microseconds for float schedules. Extra tests cover zero action, zero available margin, and rejection of an infeasible nominal schedule. Checks use explicit code and remain enabled in optimized C++ builds.

## Measurement method

- 5,000 warm-up calls per implementation.
- 10,000 separately timed calls per implementation and workload.
- 500 batches of 200 calls as an additional throughput cross-check.
- MATLAB uses `tic`/`toc`; C++ uses `std::chrono::steady_clock` with compiler fences.
- The C++ conditioner is in a separate translation unit, marked non-inline, with link-time optimization disabled. Inputs come from a runtime CSV. All returned values contribute to an observed checksum, preventing dead-code elimination.
- Individual intervals exclude input selection, checksum reduction, and file I/O. They include timer and function-call overhead. Baselines are reported without subtraction.
- Batch intervals include looping, input selection, and result reduction. Their elapsed duration divided by 200 estimates amortized cost. A p95 of these means is **not** individual-call p95.
- p95 is the sorted observation at one-based index `ceil(0.95 * N)`. It is not an interpolated percentile or a confidence bound.

The saved C++ individual-call p95 reaches the timer-only p95 of 0.1 microseconds. Treat it as timer-limited, not a precise statement that each conditioner takes 100 ns. The batch measurements resolve smaller amortized costs, but cannot recover the distribution of individual-call latency below that timer floor.

One run is recorded, with no CPU pinning, frequency lock, or real-time scheduling. JIT, caches, power management, scheduling, and background load affect these numbers. The maximum observed duration is not a worst-case execution-time guarantee. MATLAB startup and file loading are excluded from the measured intervals.

## Files

- `benchmark_matlab.m`: original-function timing plus isolated beta extraction.
- `conditioner.hpp`, `conditioner.cpp`: standalone C++ API and port.
- `benchmark.cpp`: correctness checks, warm-up, and measurement harness.
- `run.py`: build/run orchestration, sample compression, summaries, provenance.
- `export_latex.py`: checked export of saved timings to article macros; not part of the timed workload.
- `results/summary.csv`: counts, median, p95, p99, minimum, maximum, mean.
- `results/*_samples.csv.gz`: lossless raw observations, including total batch duration and calls per sample.
- `results/environment.json`: host, compiler flags, binary hash, and hashes of measured sources and article inputs.

The short [visual timing guide](../../docs/tutorials/conditioning-execution-timing.html) explains when beta executes relative to the signal. This study measures only computation cost, not hardware application deadlines.
