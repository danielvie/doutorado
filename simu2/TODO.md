# Project Analysis and Update Tasks

## Analysis
Project: Multi-Cell Buck-Boost Converter MPC (MATLAB)
Current docs: README.md, DOCS/API_REFERENCE.md, DOCS/COOKBOOK.md, DOCS/GETTING_STARTED.md, DOCS/THEORY.md

## Tasks

- [x] **Update API_REFERENCE.md** - Add missing `@Simulation` methods:
  - `set_step_strategy()` (Dense vs Switching)
  - `export_python_data()`
  - `project_with_alpha()`
  - `name()`, `quantizacao()`
  - `print_test_values()`, `print_test_values_cpp()`

- [x] **Update API_REFERENCE.md** - Add missing `+Results` methods:
  - `BuckBoostPlotter.plot_trajectory_animated()`
  - `BuckBoostPlotter.plot_trajectory_projections()`
  - `SimulationData.calculate_metrics()`

- [x] **Update API_REFERENCE.md** - Add `Trajectory.Planner` class reference

- [x] **Update API_REFERENCE.md** - Add missing `+Enums`:
  - `QuantType` (Traj, Sim)

- [x] **Update COOKBOOK.md** - Add step strategy selection snippet:
  ```matlab
  s.set_step_strategy(Dynamics.DenseStrategy());   % High-res plots
  s.set_step_strategy(Dynamics.SwitchingStrategy()); % Fast control (default)
  ```

- [x] **Update COOKBOOK.md** - Add visualization snippets:
  - `plotter.plot_trajectory_animated()`
  - `plotter.plot_trajectory_projections()`

- [x] **Update GETTING_STARTED.md** - Expand demo list:
  - `t('demo', 'broker')`
  - `t('demo', 'feasibility')`

- [x] **Update README.md** - Sync demo list with `t.m` actual tasks

- [x] **Update README.md** - Document `DOCS/agent/` and `DOCS/legacy/` subdirectories or remove if obsolete

- [x] **Update t.m** - `run_tests()` only calls 3 tests but `+z_run/+Tests/` contains 12+ files; expand or document subset

- [x] **Review DOCS/THEORY.md** - Verified and added Feasibility Region Projection section

- [x] **Code Analysis Report** - Generate comprehensive code analysis covering:
  - Architecture: Strategy Pattern, OOP design, package organization
  - Security: evalin usage, BLE message handling, path traversal risks
  - Performance: expm in hot loops, quadprog complexity, buffer pre-allocation
  - Maintainability: FIXME/TODO comments, mixed Portuguese/English, dead code
  - Dependencies: MPT3, Optimization Toolbox, Instrument Control Toolbox
