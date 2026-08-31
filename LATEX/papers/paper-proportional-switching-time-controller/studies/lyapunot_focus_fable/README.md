# Lyapunov focus (fable): proving stability with convex optimization

A self-contained tutorial on turning "is this system stable?" into a semidefinite
program, written for a reader with no prior Lyapunov background.

Start here: **[tutor-stability-via-convex-optimization.html](tutor-stability-via-convex-optimization.html)**
(open directly in a browser; no dependencies, equations in native MathML).

## Contents

| file | what it is |
|---|---|
| `tutor-stability-via-convex-optimization.html` | The tutorial: Lyapunov's idea, why the search is convex (LMIs/SDP), a 9-step recipe, both worked examples with real solver output. |
| `lab1_quadratic_certificate.html` | Interactive lab for Example 1: hunt a valid quadratic `P` with three sliders; live grading of both Lyapunov conditions, level ellipses, trajectory. |
| `lab2_switched_certificate.html` | Interactive lab for Example 2: drive the switching yourself (manual / adversarial / periodic) and watch `|x|²` fail while the degree-8 certificate decreases monotonically. |
| `matlab/ex1_simple_quadratic.m` | Example 1: Lyapunov equation by hand vs. CVX LMI feasibility vs. decay-rate bisection. |
| `matlab/ex2_switched_degree_escalation.m` | Example 2: no-common-quadratic proof (analytic + CVX infeasibility), SOS degree escalation (2, 4, 6 fail; 8 solves), independent grid verification, worst-case switching check, difficulty sweep over `a`. |

## The two examples

1. **Simple:** `xdot = [0 1; -2 -3] x` (eigenvalues -1, -2). Solved twice: classical
   Lyapunov *equation* by hand (`P = [5/4 1/4; 1/4 1/4]`) and Lyapunov *inequality*
   via CVX (`P = [1.8 0.4; 0.4 1.2]`), to expose the difference in process. Extended
   to a certified decay rate `alpha ≈ 1` by bisection over an LMI.

2. **Complex:** switched system `A1 = [-1 -1; 1 -1]`, `A2 = [-1 -10; 0.1 -1]`, arbitrary
   switching. Both modes have eigenvalues `-1 ± i`, yet no common quadratic V exists
   (CVX returns a certified `Infeasible`; analytically the quadratic template dies at
   `a = 3 + 2*sqrt(2)`). Degrees 4 and 6 also fail — lossless conclusions in 2D, since
   nonnegative binary forms are exactly sums of squares — and the first success is a
   homogeneous degree-8 polynomial found by the same generic CVX code.

## Reproducing the numbers

Both scripts run as-is with CVX on the path (this repo has it under
`z_dependencies/cvx`). Every solver output quoted in the tutorial came from running
these scripts on MATLAB R2025b:

```bash
matlab -batch "cd('matlab'); ex1_simple_quadratic; ex2_switched_degree_escalation"
```

Note: this study was written from scratch and deliberately does not reuse the
mass-spring example from `studies/lyapunov_focus/`.
