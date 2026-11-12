# Doubled initial-error trial

This is a separate run of the Daniel-versus-Marcolino comparison. Reproduce it from the paper root with:

```sh
matlab -batch "addpath('studies/marcolino-conditioning-comparison'); run_comparison([],2);"
```

The only changed simulation input is the cycle-zero state. The script sets

```text
x0_trial = orbit_anchor + 2 * (x0_article - orbit_anchor)
         = [5.1039; 22.3494; -0.9195]
```

The normalized initial error doubles from 0.983946 to 1.967893. Both runs retain the article's converter, nine-mode schedule, aggressive LQR gain, 286 µs nominal period, 3 µs minimum dwell, and 100-cycle horizon. Daniel keeps the period fixed; Marcolino delays switches sequentially. No publication result is overwritten. The explicit state and multiplier are recorded in [setup.csv](setup.csv).

| Measure | Daniel | Marcolino |
| --- | ---: | ---: |
| Cycles with conditioning | 6 | 4 |
| Cycles extended beyond 286 µs | 0 | 3 |
| Longest cycle | 286 µs | 397.2618 µs |
| Cycle length from cycle 4 onward | 286 µs | 286 µs |
| First sustained moving-anchor error below 0.01 | cycle 8, 2.288 ms | cycle 5, 1.5968 ms |
| Final moving-anchor error | below 2e-15 | below 2e-15 |
| Final original-clock error | below 2e-15 | 0.106130 |
| Sustained original-clock error below 0.01 | cycle 8 | not reached in 100 cycles |
| Minimum realized dwell | 3 µs | 3 µs |

The first raw requested final dwell is −108.2618 µs. Marcolino's first three cycle durations are 397.2618, 331.1015, and 296.4005 µs; from cycle 4 onward each lasts 286 µs. At Marcolino's fifth boundary (1.5968 ms), its error to the anchor is 0.00875, but its error to the original fixed-clock reference at that same time is 0.11349. Only the first number has crossed 0.01. Returning to a 286 µs period does not cancel earlier extensions, and the fixed-clock error remains 0.106130 at cycle 100. This is a phase mismatch, not evidence of divergent physical states. Daniel keeps the prescribed period; it first stays below 0.01 against the fixed-clock target at its eighth boundary.

The new starting current is **negative**. The exact switched-affine equations can be evaluated there, but this trial alone does not establish that a physical converter with unidirectional-current hardware can realize that state or the predicted switching response. It is a numerical stress test along the original initial-error direction. Neither response is a global nonlinear stability guarantee. The article's fixed-period common-`P` result does not cover Marcolino's extended cycles.

Inspect [the comparison figure](comparison.pdf), [all per-cycle durations](cycle_duration.csv), [the article-style first-25-cycle comparison with Marcolino](article_response_with_marcolino.pdf), [the continuous-time trajectories](state_trajectories.pdf), [the cycle history](cycle_history.csv), [the first-cycle dwell table](first_cycle_dwell.csv), [the metrics](metrics.csv), and [the dense samples](trajectory_samples.csv). The article-style figure uses an open-loop trajectory started from this trial's **negative-current state**. It is not the supplied screenshot of the article's original Figure 4. The trajectory plot overlays both exact simulated responses with the original fixed-clock reference over the first 12 nominal periods. Its curves use each method's own switching-time grid, without interpolating one onto the other.
