# API Reference

Condensed class and function reference.

## @Simulation

### Constructor
```matlab
s = Simulation(Enums.SimName)  % LAB_CIRCUIT, PATINO_1, PATINO_2, INTEGRADOR_DUPLO
```

### Configuration
```matlab
s.alpha(α)                  % Build nominal schedule from duty ratio
s.iref(i_ref)              % Build nominal schedule from current setpoint
s.set_mpc()                % Configure MPC with default Options.Mpc
s.set_mpc(options)         % Configure MPC from Options.Mpc
s.set_controller(ctrl)     % Assign controller (Strategy pattern)
s.set_control_enabled(flag)% Enable/disable control
s.set_step_strategy(strat) % Dynamics.SwitchingStrategy (default) or DenseStrategy
s.set_offset(delta_x)      % Apply initial-state disturbance
```

### Execution
```matlab
[y, t, m, dtk] = s.run(nsim)   % Run nsim cycles
```

### Getters
```matlab
[Phi, Gamma] = s.get_phi_gamma()      % Linearized model
K = s.get_gain_k()                    % LQR gain
c = s.get_switching_constraints()     % Constraint vector
orbit_anchor = s.get_target()         % Active cycle-boundary setpoint
mode = s.get_mode()                   % Zero-based mode-label sequence
time_us = s.get_time_us()             % Nominal dwell durations [us]
msg = s.get_msg_control_signal()      % BLE formatted message
```

### Visualization
```matlab
fig = s.project_feasibility_region(horizons)  % Default: [1,2,4]
```

### Automation
```matlab
s.project_with_alpha(alpha, folder, flag_save)  % Batch feasibility plots
s.export_python_data(filename)                  % Export data for Python
```

### Helpers
```matlab
name_out = s.name()         % Simulation name string
Ts_out  = s.quantizacao(Ts, type)  % Quantize times (QuantType enum)
```

### Diagnostics
```matlab
s.print_test_values(k, log_source)     % Print state for debugging
s.print_test_values_cpp(k, log_source) % Print C++ compatible values
```

### Properties
```matlab
s.m_config              % Circuit configuration
s.m_config.control      % Runtime control state (.on, .x_target)
s.m_config.mpc          % Built MPC runtime data
s.m_config.orbit_anchor % Nominal cycle-start state
s.m_config.x0           % Simulation initial state
s.m_log.run             % Simulation logs
```

---

## +Controllers

### Base Class
All controllers implement:
```matlab
[dtk, exitflag, info] = compute_control(x, x_target)
reset()
```

### Proportional (LQR)
```matlab
ctrl = Controllers.Proportional(K, Nd, time_us, min_gap_us)
```

### MpcController
```matlab
ctrl = Controllers.MpcController(mpc_data)
ctrl = Controllers.MpcController(mpc_data, 'Nd', 3)
ctrl = Controllers.MpcController(mpc_data, 'StateMode', Enums.StateMode.AUGMENTED)
```

---

## +Dynamics

### Step Strategy (Abstract)
```matlab
[y, t, m, u, xr] = strategy.propagate(config)
```

### SwitchingStrategy (default)
Fast propagation at switching instants only.

### DenseStrategy
High-resolution propagation using `lsim` for detailed plots.

---

## +Results

### SimulationData
```matlab
data = Results.SimulationData(vars)  % vars from Utils.getAllVars()
data.t, data.y, data.m               % Time, states, modes
data.target                          % Target state vector
data.config                          % Simulation configuration
stats = data.calculate_metrics()     % RMSE and final error
```

### BuckBoostPlotter
```matlab
p = Results.BuckBoostPlotter(data)
p.plot_states()
p.plot_trajectory_comparison()
p.plot_control_signals(start, n)
p.plot_trajectory_projections()
p.plot_trajectory_animated()      % Animated 3D phase evolution
```

---

## +Trajectory

### Planner
```matlab
planner = Trajectory.Planner(circuit_params, n, T)
[Omega, Ts, x0] = planner.set_alpha(alpha, config)
[Omega, Ts, x0] = planner.set_reference_current(iref, config)
planner.result   % Last computed struct (.Omega, .Ts, .x0, .alpha)
```

`Omega` is the dynamics-index sequence, `Ts` contains nominal cycle-boundary
times, and `x0` is the cycle-start orbit anchor.

---

## @BTBroker (Hardware)

### Connection
```matlab
b = BTBroker()           % Auto-connect with default UUIDs
```

### Setup
```matlab
b.alpha(α)               % Set simulation config
b.s(α)                   % Same
b.ss(α)                  % Set + send complete signal
```

### Control
```matlab
b.sa()                   % Start
b.so()                   % Stop
b.x()                    % Emergency stop
```

### Queries
```matlab
b.st()                   % Status
b.ma()                   % Matrix A
b.mb()                   % Matrix B
b.last(n)                % Last n calculations
```

---

## +Enums

| Enum | Values |
|------|--------|
| `SimName` | `LAB_CIRCUIT`, `PATINO_1`, `PATINO_2`, `INTEGRADOR_DUPLO` |
| `StateMode` | `ORIGINAL` (held-input block), `AUGMENTED` (experimental delayed block) |
| `QuantType` | `Traj`, `Sim` |

---

## Log Structure

After `s.run(nsim)`, access via `s.m_log.run`:

| Field | Size | Description |
|-------|------|-------------|
| `iter` | nsim×1 | Cycle index |
| `exitflag` | nsim×1 | Controller status (1=accepted, 44=held, -2=infeasible) |
| `x0` | nsim×n | Cycle input state |
| `ek` | nsim×n | Cycle-boundary orbit deviation |
| `dtk` | nsim×p | Applied switching-instant offsets [s] |
| `time_qp` | nsim×1 | QP solve time [s] |

## Options.Mpc

```matlab
mpc_options = Options.Mpc();
mpc_options.Np = 10;  % Prediction-block transitions
mpc_options.Nd = 2;   % Held-input block length [cycles]
mpc_options.Q = diag([10, 10, 1]);
mpc_options.state_mode = Enums.StateMode.ORIGINAL;
mpc_options.solver_algorithm = 'active-set';
mpc_options.solver_display = 'off';
s.set_mpc(mpc_options);
```

`set_mpc()` builds an orbit-deviation controller around
`s.m_config.orbit_anchor`, writes runtime matrices to `s.m_config.mpc`, and
installs `Controllers.MpcController`. Custom `Options.Mpc.x_target` values are
unsupported because the predictor has no affine bias for another setpoint.
