# Superseded article experiments

These files are preserved historical evidence, not inputs to the current article pipeline.

- `design_robust_controllers.m` contains earlier guaranteed-cost and H-infinity synthesis, requiring YALMIP and an SDP solver.
- `results/` contains older gains, linear models, region records, and local/robust response data.
- `figures/` contains figures no longer generated or consumed by the current article pipeline.

In particular, `results/gain_matrix.csv` must not be used as the current aggressive gain. That gain is stored in `results.controller.K_aggressive_physical` inside the paper-root `results/paper_results.mat`.

These files were not deleted or regenerated. Some earlier generators and assumptions may no longer match the current manuscript. Recover the corresponding historical revision before attempting to reproduce an old experiment.
