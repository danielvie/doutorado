# Figure 3 comparison with MPC-5

Standalone one-page landscape report: `figure3-mpc5-comparison.pdf`.
The main manuscript and all existing numerical evidence are read-only inputs.

## Reproduce

Requires the article's MATLAB R2025b setup, Control System Toolbox, Optimization Toolbox, MPT3, Go Task, and LaTeX with latexmk.

```sh
cd 'C:/Users/daniel/Documents/doutorado.git/LATEX/papers/paper-proportional-switching-time-controller/studies/mpc-trajectory-comparison'
task run   # Fresh 100-cycle proposed/MPC-5, validate, plot, compile
task test  # Saved evidence checks only, no QP solves
task plot  # Validate and redraw saved evidence
task build # Compile saved figure into the standalone report
```

All outputs, including simulation logs and LaTeX intermediates in `build/`, stay here. `task clean` removes only local LaTeX intermediates. No long MPC run or new long open-loop simulation is performed.

## Source and evidence

- `run_study.m`: fresh original-1x simulation with the article benchmark, analytical model and aggressive feedback gain; reuses the existing five-cycle `mpc_problem.m` builder. A failed QP stops immediately and saves local partial evidence, without fallback.
- `check_study.m`: checks 100 completed cycles, 100 successful MPC QPs, initial state, dwell feasibility, fixed period, normalization, all dense interval boundaries and cycle endpoints, each controller's own switching times, and saved-reference agreement.
- `plot_comparison.m`: isolated Figure 3 adaptation, retaining the article view, physical units, logarithmic error axes and threshold conventions. Limits include every MPC sample. Both controllers use 27001 dense samples over 100 cycles, without a common switching grid.
- `evidence.mat`: benchmark, model, gain, QP, fresh physical boundary states, eight interior offsets per cycle, applied dwells, exact dense samples, normalized errors, checked 1x reference and unchanged saved publication trajectories.
- `validation.csv`, `validation.txt`: focused numerical results.
- `trajectory-comparison.pdf`: vector figure; `figure3-mpc5-comparison.tex`: report source; `compiled-preview.png`: visually inspected rendering of the final LaTeX PDF.
- `input-sha256.txt`, `integrity-check.txt`: before/after integrity check of existing tracked paper files, including already modified manuscript files.

The saved 1x study at `../mpc-comparison/results/error-scale-1x/study.mat` first passes `paper.mpc_comparison_data` against the current plant, reconciled schedule, scales, weights, model, gain, terminal-set constraints and recorded response. Its saved offset schema has a leading fixed zero; this is removed explicitly. Fresh offsets always contain only the eight interior offsets expected by `paper.sample_cycle`.
The original `results/publication_trajectories.mat` supplies the nominal reference, first-100-cycle open-loop path and saved 100000-cycle open-loop errors. The local checker independently reconstructs its normalized errors from saved physical states.

## Results

Both fresh runs completed 100 cycles; all 100 MPC QPs returned exitflag 1.
Minimum applied dwell is 3 microseconds for both methods, within the article's 1e-12 s feasibility tolerance. Period residual is zero; maximum dense interval endpoint residual is 3.55e-15 in physical coordinates.
Fresh MPC versus saved 1x maximum physical-state difference is 1.39e-17, with zero offset difference. Proposed differences are 3.55e-15 in state and 3.39e-20 s in offsets.
Regression tolerances are 1e-8 in physical and normalized state coordinates and 1e-11 s in offsets, allowing solver/BLAS roundoff far below graphical resolution. Dense propagation uses the article's tighter 1e-11 physical-coordinate check.

Threshold markers use actual samples. First crossings below 0.01 are k=6 for the proposed controller and k=5 for MPC-5. The saved open-loop persistent crossing is k=22009. The controller curves end at k=100; errors below the displayed 1e-8 floor are neither altered nor clamped.

Executed successfully: the direct fresh `run_study` MATLAB command, `task plot`, `task build`, `task test`, `task --list`, and the tracked-file SHA-256 integrity check. The final PDF has one A4 landscape page, inspected at twice PDF-point resolution. Header flow and one annotation placement were corrected after the first inspection; the final rendering has no clipped or overlapping labels.

The preview can be regenerated with:

```sh
uv run --no-project --with pymupdf python -c "import pymupdf; d=pymupdf.open('figure3-mpc5-comparison.pdf'); assert len(d)==1; d[0].get_pixmap(matrix=pymupdf.Matrix(2,2)).save('compiled-preview.png')"
```

This is exact switched-affine simulation evidence. It establishes neither global nonlinear stability nor embedded deadline guarantees. No timing benchmark was run.
