# Code Analysis Report

**Project:** Multi-Cell Buck-Boost Converter MPC (MATLAB)  
**Scope:** Architecture, Security, Performance, Maintainability  
**Date:** 2025

---

## 1. Executive Summary

This is a MATLAB research framework for Model Predictive Control (MPC) of switched DC-DC converters. It implements a Strategy-pattern architecture for controllers and physics propagation, supports hardware-in-the-loop via Bluetooth, and provides visualization tools. Overall code quality is **good for research software**, with clean separation of concerns in the core engine. Primary risks are **mixed-language technical debt**, **incomplete/abandoned modules**, and **workspace introspection security patterns** typical of MATLAB scientific computing.

---

## 2. Architecture Analysis

### 2.1 Design Patterns

| Pattern              | Implementation                                                      | Assessment                                                   |
| -------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------ |
| **Strategy**         | `Controllers.Controller` → `MpcController` / `Proportional`         | Strong. Clean swap at runtime via `set_controller()`.        |
| **Strategy**         | `Dynamics.StepStrategy` → `SwitchingStrategy` / `DenseStrategy`     | Strong. Separates fast control loops from high-res plotting. |
| **Facade**           | `t.m` task runner                                                   | Good. Simple entry point hiding `+z_run` complexity.         |
| **Template Method**  | `Simulation.run()` orchestrates Control → Actuation → Physics → Log | Good. Fixed pipeline with overridable strategies.            |
| **Handle Semantics** | `@Simulation`, `@BTBroker`, most classes inherit `handle`           | Appropriate for MATLAB reference semantics.                  |

### 2.2 Package Organization

```
+Controllers/   - Control algorithms (Strategy interface)
+Data/          - Configuration factories per circuit
+Dynamics/      - Physics propagation strategies
+Enums/         - Type-safe enumerations
+Hardware/      - BLE message formatting (separated from broker)
+Interface/     - Config structs (config_mpc)
+Mpc/           - QP matrix builders and dual-mode solver
+Results/       - Data containers and plotters
+Trajectory/    - Reference orbit planner
+Utils/         - Math helpers and signal utilities
+z_run/         - Scripts, Tests, Demos, Experiments
@Simulation/    - Core orchestrator class
@BTBroker/      - Hardware BLE client
```

**Assessment:** Cohesive. The separation of `+Hardware` (message formatting) from `@BTBroker` (connection logic) is a nice touch. `+z_run` acts as a lightweight task layer.

### 2.3 Core Data Flow

```
Data.* config  →  Trajectory.Planner (alpha/iref)  →  Simulation.set_mpc()
                                                            ↓
[Run Loop]  Controller.compute_control()  →  step_actuation()  →  StepStrategy.propagate()
                                                            ↓
                                              Results.SimulationData / BuckBoostPlotter
```

### 2.4 SOLID Score

- **Single Responsibility:** Mostly good. `Simulation` is slightly a "god class" (orchestration + visualization + export + diagnostics + quantization), but acceptable for a research monolith.
- **Open/Closed:** Excellent. New controllers and propagation strategies require zero changes to `Simulation.run()`.
- **Liskov Substitution:** Good. `Proportional` and `MpcController` transparently replace each other.
- **Interface Segregation:** Good. `Controller` and `StepStrategy` are minimal, focused interfaces.
- **Dependency Inversion:** Good. High-level `Simulation` depends on abstractions, not concrete implementations.

**Overall Architecture Grade: B+**

---

## 3. Security Assessment

> _Note: This is a MATLAB research framework, not a networked service. Security risks are primarily about code safety and data integrity._

### 3.1 High-Risk Findings

| Risk                           | Location                                     | Severity | Details                                                                                                                                                                                |
| ------------------------------ | -------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Workspace Introspection**    | `+Utils/getAllVars.m`                        | Medium   | Uses `evalin('caller', 'who')` and `evalin('caller', vi)` to blindly capture caller variables. This breaks encapsulation and can leak sensitive workspace state into `SimulationData`. |
| **Unvalidated BLE Input**      | `@BTBroker/msg_handle_process.m` (not shown) | Medium   | Incoming BLE messages are parsed without apparent length/type validation. A malformed message could crash the MATLAB session or corrupt `simulation` state.                            |
| **File Deletion**              | `t.m` → `clean_files()`                      | Low      | Deletes `outputs/*.mat`. Path is hardcoded and relative, but scope is limited.                                                                                                         |
| **External Program Execution** | `t.m` → `open_docs()`                        | Low      | Uses `winopen()` / `system()` to open markdown files. If path were manipulated, could open unexpected files.                                                                           |

### 3.2 Recommendations

- Replace `evalin` in `getAllVars` with explicit parameter passing (`Results.SimulationData(t, y, m, ...)`).
- Add message length and CRC checks in `BTBroker` before `msg_handle_process`.
- Use `fullfile(pwd, 'outputs')` with validation instead of relative paths for cleanup.

---

## 4. Performance Analysis

### 4.1 Hot Paths

| Component                         | Complexity                | Bottleneck                      | Mitigation                                                         |
| --------------------------------- | ------------------------- | ------------------------------- | ------------------------------------------------------------------ |
| `MpcController.compute_control()` | O(Np³ · p³) per step      | `quadprog` active-set solver    | `Nd` downsampling reduces calls; fallback to LQR on infeasibility. |
| `propagate_switching()`           | O(N_modes · n³) per cycle | `expm()` on augmented [A,b;0,0] | N_modes ≈ 6–9, n=3. Negligible cost.                               |
| `propagate_dense()`               | O(T/tstep · n³)           | `lsim` + dense time vector      | Only used for visualization, not control loop.                     |
| `Simulation.run()` loop           | O(nsim · cost_above)      | Buffer reallocation (rare)      | Pre-allocated buffers with exponential padding fallback.           |

### 4.2 Good Practices Observed

- **Pre-allocation:** `run.m` pre-allocates `buffers.y`, `buffers.t`, `buffers.m`, and all log arrays. Dynamic reallocation only triggers if dense mode exceeds estimates.
- **Downsampling:** `Nd` parameter skips QP solves, trading performance for control bandwidth.
- **Matrix Caching:** `Phi`, `Gamma`, `H_qp`, `K` are computed once in `set_mpc()` and cached in `config.mpc`.

### 4.3 Risks

- **Active-Set Algorithm:** `quadprog` uses `'active-set'`, which is deprecated in newer MATLAB releases. Consider `'interior-point-convex'` for stability, though active-set can be faster for small QPs.
- **`expm` in Loops:** For larger state spaces (>10 states), per-mode `expm` in the run loop would dominate. Currently fine for 3-state buck-boost.
- **No Parallelism:** The `run()` loop is serial. For batch parameter sweeps, `parfor` could be added at the script level.

---

## 5. Maintainability & Code Quality

### 5.1 Language & Documentation Debt

- **Mixed Portuguese/English:** Widespread. Examples:
  - `eh preciso`, `monta vetor`, `USANDO MODELO EXTENDIDO`, `calculando`, `constraing` (typo).
  - Impact: Reduces accessibility for international collaborators.
- **Placeholder Comments:** `QuantType.m` contains `%UNTITLED Summary of this class goes here`.
- **Dead Code:** `build_switching_model.m` has large commented blocks (`%{ ... %}`) containing alternative implementations and debugging fragments.

### 5.2 Naming & Magic Values

| Issue            | Example                                        | Suggestion                                                   |
| ---------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| Unclear flag     | `config.kawa` toggles extended model           | Rename to `use_extended_model`                               |
| Magic numbers    | `1e-16`, `1e-9`, `2.2e-5` in QPs               | Define as named constants (`MIN_DT_FILTER`, `QP_LB_DEFAULT`) |
| Hardcoded period | `Planner.T = 0.28e-3`                          | Pull from `config.Tpmax` or circuit params                   |
| Mixed units      | `us` vs `s` vs `ms` without Hungarian notation | Use `_us`, `_s` suffixes consistently (partially done)       |

### 5.3 Error Handling Inconsistencies

- **Fatal errors:** `set_controller()` throws `error()` on bad type.
- **Silent failures:** `set_config()` prints `disp('ERROR: ...')` and returns `false`.
- **Warnings:** `BuckBoostPlotter` uses `warning()` for invalid ranges.
- **Recommendation:** Standardize on `error()` for programmer errors and `warning()` + graceful degradation for runtime issues.

### 5.4 Incomplete Modules

- **`project_feasibility_region.m`:** Truncated implementation (`% ...`). Only dispenses inputs and retrieves `Phi/Gamma`.
- **`+Mpc/build_switching_model.m`:** Contains a `FIXME` comment and extensive dead code paths.
- **`test_basic.m`:** Not a self-contained unit test; appears to be a hardware integration script that mixes workspace manipulation with broker commands.

### 5.5 Test Coverage

- **14 test/check files** exist in `+z_run/+Tests/`, but they are mostly **diagnostic scripts**, not automated assertions.
- `test_dlqr_behavior.m` lacks assertions; it just prints values.
- `test_industrial_solution.m` prints binary strings without validation.
- **Recommendation:** Adopt MATLAB's `assert()` or `matlab.unittest` framework for true regression testing.

---

## 6. Dependency Analysis

### 6.1 Required Toolboxes

| Toolbox                | Usage                                     | Risk if Missing                                   |
| ---------------------- | ----------------------------------------- | ------------------------------------------------- |
| **Control System**     | `dlqr`, `c2d`, `lsim`                     | Critical. Core MPC and propagation fail.          |
| **Optimization**       | `quadprog`                                | Critical. MPC controller fails entirely.          |
| **MPT3**               | `LTISystem`, `Polyhedron`, `QuadFunction` | High. Feasibility regions and terminal sets fail. |
| **Instrument Control** | BLE in `@BTBroker`                        | Medium. Only affects hardware experiments.        |

### 6.2 External Coupling

- `python/` directory contains `export_data.m` that attempts to auto-locate project root via `which('Simulation')`. This creates a brittle dependency on MATLAB path state.
- `figures/` and `outputs/` directories are assumed to exist at runtime but are not validated.

---

## 7. Refactoring Recommendations (Prioritized)

### Quick Wins

1. **Standardize language** to English for all new code; add `TODO(i18n)` markers on legacy Portuguese comments.
2. **Remove dead code** from `build_switching_model.m` (move to `archive/` if historically relevant).
3. **Add assertions** to `test_industrial_solution.m`, `test_dlqr_behavior.m`, and `test_mpc_on.m`.
4. **Replace `evalin`** in `getAllVars` with explicit constructor args.

### Medium Effort

5. **Complete or remove** `project_feasibility_region.m` stub.
6. **Refactor `Simulation`** into smaller mixins or helper classes (e.g., `SimulationLogger`, `SimulationExporter`).
7. **Add input validation** to `BTBroker` message parser.
8. **Standardize error handling** across `Data.*` config loaders.

### Strategic

9. **Upgrade `quadprog` algorithm** to `interior-point-convex` and benchmark against active-set.
10. **Introduce `matlab.unittest`** test classes in `+z_run/+Tests/` for CI compatibility.
11. **Separate hardware logic** from `Simulation` entirely (already mostly done; finish the job).

---

## 8. Overall Grade

| Category            | Grade | Notes                                                                   |
| ------------------- | ----- | ----------------------------------------------------------------------- |
| **Architecture**    | B+    | Clean Strategy patterns, slightly heavy orchestrator.                   |
| **Security**        | C+    | Research-code risks (`evalin`, BLE trust). No critical vulnerabilities. |
| **Performance**     | B     | Good caching and pre-allocation; `quadprog` is inherent bottleneck.     |
| **Maintainability** | C+    | Language debt, dead code, inconsistent error handling drag score down.  |
| **Testability**     | C     | Diagnostic scripts present, but few true automated tests.               |

**Project Health:** Suitable for PhD research and small-team collaboration. Would benefit from a 1–2 day cleanup sprint before public release or handoff.

---

_Report generated via static analysis of the `simu2` MATLAB project._
