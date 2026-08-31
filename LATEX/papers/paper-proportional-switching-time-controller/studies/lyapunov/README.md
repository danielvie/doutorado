# studies/lyapunov

Computing Lyapunov functions by convex optimization: an interactive study document
plus the MATLAB scripts that produce every number in it.

Read: **`lyapunov-convex-optimization.html`** — open it directly in a browser, no
server needed. It is self-contained (no external scripts, stylesheets or fonts)
and draws all six laboratories in the browser from embedded data.

## What the document covers

1. **Motivation** — what a Lyapunov certificate proves that simulation cannot.
2. **Lyapunov theory for discrete-time systems** — the direct method, quadratic
   `V(x) = x'Px`, why `P > 0` and `A'PA - P < 0` are linear matrix inequalities,
   the *P*-norm and contraction factor, and the common-*P* condition.
3. **Worked example: a two-mode switched system** — a pair for which `P = I`,
   either mode's own Lyapunov matrix, and every diagonal *P* provably fail, while
   an SDP returns a common *P* with `q = 0.914931`. Also a pair for which no
   common quadratic *V* exists at all.
4. **Solving the LMI in MATLAB** — YALMIP + SeDuMi, the Robust Control Toolbox
   LMI Lab, CVX, and how to re-verify a returned certificate without trusting the
   solver.
5. **Stability proof of the switching-time controller** — the one-cycle model, the
   dwell conditioner, why `A(β) = (1-β)Φ + βA_cl` is a segment, Proposition 2,
   the certificate computed for the converter benchmark, and a quantitative
   comparison against per-component clipping.
6. **Scope of the result** — what is proved, what is not, how to reproduce it.

## Files

| File | Purpose |
| --- | --- |
| `lyapunov-convex-optimization.html` | the study document (generated — do not edit) |
| `parts/*.html` | the document source, one region per file |
| `build.py` | assembles the parts, substitutes `{{data.path\|fmt}}` placeholders, injects the data |
| `generic_example.m` | the worked example of §3–4, runnable, prints everything |
| `paper_certificate.m` | rebuilds the paper's certificate from `results/paper_results.mat` |
| `export_study_data.m` | writes `study_data.json`, the data the document embeds |
| `study_data.json` | matrices, scalars and sequences (generated) |

## Rebuilding

From this directory, with YALMIP and a conic solver on the MATLAB path
(SeDuMi ships with the MPT bundle already on the repository's path), and after
`scripts/generate_results.m` has been run at least once:

```matlab
generic_example        % §3–4, prints to the console
paper_certificate      % §5, re-solves the SDP and checks it against the stored P
export_study_data      % writes study_data.json
```

then

```bash
python build.py
```

`build.py` uses the standard library only. It fails loudly if any placeholder in
`parts/` cannot be resolved, so the prose and the figures cannot drift apart from
the generated data.

## One result worth flagging

§5.7 is not in the manuscript. Enumerating the 2⁸ = 256 vertices of the polytope
that *per-component* clipping would reach shows that 4 of them have spectral
radius ≥ 1 (worst 1.000422) and that no common quadratic Lyapunov function exists
for that set. Uniform scaling by a single β is therefore not merely convenient for
the proof — it is the difference between a certifiable family and one containing
unstable members. `paper_certificate.m`, section 4, computes this.

## Related documents

- `docs/choosing-lyapunov-functions.html` — physics, the Lyapunov equation, and
  optimization compared as three routes to a *V*.
- `docs/lyapunov-stability.html` — a longer conceptual treatment of the paper's
  stability argument.
- `docs/dwell-time-conditioning.html`, `docs/computing-beta.html` — the
  conditioner in detail.
- `article.tex` §3 — the propositions as published.
