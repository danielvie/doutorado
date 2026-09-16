# Host beta computation timing

These are desktop MATLAB and native C++ timings, not ESP32 timings or a WCET certificate.

## Individual-call p95

Each entry is the nearest-rank p95 of 10,000 separately timed calls, in microseconds. Input selection and result consumption are outside each interval. Timer and call overhead remain included; no baseline subtraction was applied.

| Implementation | Mixed 100 cycles | Conditioned 3 cycles | Unconditioned 97 cycles |
| --- | ---: | ---: | ---: |
| matlab_existing_conditioner | 5.300000 | 3.900000 | 4.800000 |
| matlab_beta_only | 3.600000 | 3.200000 | 3.500000 |
| cpp_double_conditioner | 0.100000 | 0.100000 | 0.100000 |
| cpp_double_beta_only | 0.100000 | 0.100000 | 0.100000 |
| cpp_float_us_conditioner | 0.100000 | 0.100000 | 0.100000 |
| cpp_float_us_beta_only | 0.100000 | 0.100000 | 0.100000 |

## Batched cross-check

Each entry is the p95 of 500 batch-average costs, in microseconds per call. Each batch contains 200 calls. This is **not** a p95 of individual-call latency. Loop, input selection, output reduction, and accumulation are included; timer overhead is amortized.

| Implementation | Mixed | Conditioned | Unconditioned |
| --- | ---: | ---: | ---: |
| matlab_existing_conditioner | 4.586000 | 4.338500 | 4.500000 |
| matlab_beta_only | 3.266000 | 2.862000 | 2.981500 |
| cpp_double_conditioner | 0.025500 | 0.025000 | 0.025000 |
| cpp_double_beta_only | 0.007500 | 0.007000 | 0.007500 |
| cpp_float_us_conditioner | 0.021500 | 0.031500 | 0.032000 |
| cpp_float_us_beta_only | 0.006500 | 0.006500 | 0.006500 |

## Timer-only baselines

- matlab_timer_only: median 0.200000 µs; p95 0.200000 µs.
- cpp_timer_only: median 0.000000 µs; p95 0.100000 µs.

## Scope and validation

- Existing MATLAB conditioner is unchanged and returns all three outputs, including both feasibility assertions.
- Beta-only variants exclude offset scaling, applied-dwell reconstruction, and feasibility assertions. They recompute nominal margins rather than assuming a cached margin vector.
- C++ double uses seconds; C++ float uses microseconds. The full C++ conditioners retain explicit checks with tolerances of 1e-12 s and 1e-4 µs, respectively. Fixed-size stack storage differs from MATLAB arrays.
- All 100 saved article cases were checked against saved beta, offsets, and dwells before measurement. Zero-action, zero-margin, and invalid-schedule cases are also checked by the benchmark code.
- No gain multiplication, ADC acquisition, firmware scheduling, tick quantization, waveform rendering, or plant propagation is timed. The C++ float version is not the ESP32 binary.
- There are only three beta<1 cases in the saved 100-cycle trajectory. Reporting them separately avoids hiding them in a mixed p95. The workload is repeated warm inputs, not a distribution of arbitrary controller states.
- Warm-up: 5,000 calls per implementation. Scenarios repeat their saved inputs in deterministic cycle order. One sequential benchmark run; no CPU affinity, frequency lock, or real-time scheduling was imposed.
- Do not interpret a ratio near the timer floor as a precise algorithm speedup. Use the batch-average cross-check to see amortized cost, without relabeling it as individual-call p95.

## Evidence

- [Summary CSV](summary.csv), including median, p95, p99 and maximum.
- Lossless raw samples: `matlab_samples.csv.gz` and `cpp_samples.csv.gz`.
- [Environment and source hashes](environment.json), [MATLAB metadata](matlab_environment.json).
- [C++ validation/run log](cpp_run.log), [MATLAB validation/run log](matlab_run.log).
- [Method and reproduction instructions](../README.md).
