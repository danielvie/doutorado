# Tripled initial-error trial

Reproduce from the paper directory with:

```sh
matlab -batch "addpath('studies/marcolino-conditioning-comparison'); run_comparison([],3);"
```

The experiment triples the article's original state displacement from the orbit anchor, not the preceding 2× trial:

```text
x0_trial = orbit_anchor + 3 * (x0_article - orbit_anchor)
         = [2.6935; 23.8777; -1.8704]
```

The initial normalized error is 2.951839, three times 0.983946. The nominal schedule, model, LQR gain, 3 µs minimum dwell, and 100-cycle horizon are unchanged. The run has its own `setup.csv` and does not overwrite either earlier case or the article outputs.

| Measure | Daniel | Marcolino |
| --- | ---: | ---: |
| Minimum realized dwell | 3 µs | 3 µs |
| Cycles with conditioning | 10 | 5 |
| Cycles longer than 286 µs | 0 | 4 |
| Longest cycle | 286 µs | 462.479 µs |
| Cycle length from cycle 5 onward | 286 µs | 286 µs |
| First sustained moving-anchor error below 0.01 | cycle 12, 3.432 ms | cycle 7, 2.293 ms |
| First sustained original-clock error below 0.01 at actual cycle starts | cycle 12 | cycle 8 |
| Final moving-anchor error | about 2e-15 | about 2e-15 |
| Final original-clock error | about 2e-15 | 0.004936 |

Daniel's conditioner is active for **10 cycles** in this trial, versus **3** for the article initial state. Its first-cycle beta falls from 0.293978 to 0.097993. The first-cycle applied dwell vector is nevertheless exactly the same in both original-policy runs: tripling the initial error triples the raw offset vector, while the active dwell bound reduces beta by a factor of three. The article's fixed-period common-`P` certificate applies to Daniel's linearized conditioned family, not to Marcolino's extended-cycle rule.

Marcolino's first four cycles last 462.479, 363.032, 318.219, and 291.308 µs. They then return to the nominal 286 µs duration. The early extensions accumulate 291.038 µs, which is **one nominal 286 µs period plus 5.038 µs**. Thus the small original-clock error here is partly a consequence of a near-complete phase wrap, not evidence that the controller shortened later cycles to recover the original schedule. The original-clock metric uses the periodic reference modulo 286 µs. Its 0.01 crossing is measured at each method's actual cycle start, not on a shared physical-time sampling grid.

This starts with a **negative inductor current of −1.8704 A**. The switched-affine mathematical model can propagate this state, but the trial does not establish physical validity for hardware that forbids reverse current. It is a numerical stress test from one initial condition, not a global nonlinear guarantee.

Files comparing both policies: [cycle-duration figure](comparison.pdf), [duration values](cycle_duration.csv), [state trajectories](state_trajectories.pdf), [article-style early response](article_response_with_marcolino.pdf), [metrics](metrics.csv), [cycle history](cycle_history.csv), [first-cycle dwells](first_cycle_dwell.csv), and [dense trajectory samples](trajectory_samples.csv).
