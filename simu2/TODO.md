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

- [x] **Analyze lookup generation flow** - Compare `+z_run/+Demos/z_create_lookup.m` with embedded `helper_datasetter.cpp/.h`
- [x] **Design compact generated format** - Replace verbose per-alpha generated code with table-driven/indexed output
- [x] **Update z_create_lookup.m** - Generate both `helper_datasetter.cpp` and `helper_datasetter.h`
- [x] **Add alpha computation logic** - Compute lookup index/selection in C++ instead of storing large dispatch code
- [x] **Regenerate embedded lookup files** - Sync generated files with current simulation outputs
- [x] **Validate generated interface** - Confirm generated files still match embedded `DataSet` layout and expected alpha range

## Current Request: Project Design Analysis

- [x] Inventory project structure and entry points
- [x] Inspect core modules for architectural boundaries
- [x] Identify scaling, safety, observability, and maintainability risks
- [x] Summarize complexity debt and recommended next steps

## Current Request: Persist Design Analysis

- [x] Create a living design analysis document under `DOCS/`
- [x] Capture complexity debt, risks, and recommended fixes
- [x] Mark persistence task complete

## Current Request: Add Note Identifiers

- [x] Add stable identifiers to design-analysis findings
- [x] Add stable identifiers to priority fixes
- [x] Mark identifier task complete

## Current Request: Cross-Reference Fixes

- [x] Update fix items to cite related finding identifiers
- [x] Document cross-reference convention
- [x] Mark cross-reference task complete

## Current Request: Rename Interface Package

- [x] Rename `+Interface` package to `+Options`
- [x] Update code and docs references to `Options.config_mpc`
- [x] Verify references and mark task complete

## Current Request: Rename MPC Options Class

- [x] Rename `Options.config_mpc` class/file to `Options.Mpc`
- [x] Update code and docs references
- [x] Verify MATLAB can instantiate `Options.Mpc`

## Current Request: Run MATLAB Tests

- [x] Run `t('test')`
- [x] Fix failing issue
- [x] Re-run relevant MATLAB test

## Current Request: Avoid BLE Startup in Default Tests

- [x] Make hardware test sections opt-in
- [x] Re-run `t('test')`
- [x] Report hardware opt-in command

## Current Request: Review t.m Commands

- [x] Reproduce `t('play')` failure
- [x] Review task mappings against existing scripts/demos
- [x] Fix incorrect task mapping
- [x] Re-run affected task

## Current Request: Add Projection Tasks

- [x] Add projection task mappings to `t.m`
- [x] Fix projection script entry-point mismatch
- [x] Verify projection command listing

## Current Request: Add Play Subcommands

- [x] Add `t('play', name)` dispatch syntax
- [x] Keep existing direct play aliases working
- [x] Verify play command listing

## Current Request: Fix t.m Helper Comments

- [x] Update `t.m` task list comments
- [x] Update `t.m` examples for subcommand syntax
- [x] Verify help comments reflect current commands

## Current Request: Simplify Play Commands

- [x] Remove direct `play` and `play_*` task dispatch
- [x] Keep only `play <name>` syntax
- [x] Verify play command listing

## Current Request: Add Control Toggle API

- [x] Add `Simulation.set_control_enabled(flag)`
- [x] Update active scripts/tests to use the method
- [x] Verify MATLAB tests pass

## Current Request: Implement MPC Setup Decisions

- [x] Remove `m_config_mpc`, `get_config_mpc`, and `set_config_mpc`
- [x] Make `set_mpc(options)` build controller and runtime config atomically
- [x] Add `Options.Mpc` target and local validation fields
- [x] Update active scripts/tests/docs to new MPC setup API
- [x] Run `t('test')`

## Current Request: Move StateMode to Options.Mpc

- [x] Add `state_mode` to `Options.Mpc`
- [x] Use `options.state_mode` in `set_mpc`
- [x] Update active scripts to set state mode through options
- [x] Run `t('test')`

## Current Request: Implement Completed MPC Architecture Grilling

- [x] Add generic `config.control` runtime state
- [x] Move target/control enabled usage from `mpc` to `control`
- [x] Apply remaining `Options.Mpc` naming/solver metadata decisions
- [x] Update runtime guards, controller reset, docs, and active call sites
- [x] Run `t('test')`
