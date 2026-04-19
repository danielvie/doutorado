# API Reference

Condensed class and function reference.

## @Simulation

### Constructor
```matlab
s = Simulation(Enums.SimName)  % LAB_CIRCUIT, PATINO_1, PATINO_2, INTEGRADOR_DUPLO
```

### Configuration
```matlab
s.alpha(α)                  % Set trajectory from duty cycle (0-1)
s.iref(i_ref)              % Set trajectory from reference current
s.set_mpc()                % Compute MPC matrices
s.set_controller(ctrl)     % Assign controller (Strategy pattern)
s.set_config_mpc(cfg)      % Set MPC parameters (Np, Nd, Q)
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
target = s.get_target()               % Target state
```

### Visualization
```matlab
fig = s.project_feasibility_region(horizons)  % Default: [1,2,4]
```

### Properties
```matlab
s.m_config              % Circuit configuration
s.m_config_mpc          % MPC parameters
s.m_config.mpc.on       % Enable/disable control
s.m_config.x0           % Initial state
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

## +Results

### SimulationData
```matlab
data = Results.SimulationData(vars)  % vars from Utils.getAllVars()
data.t, data.y, data.m               % Time, states, modes
```

### BuckBoostPlotter
```matlab
p = Results.BuckBoostPlotter(data)
p.plot_states()
p.plot_trajectory_comparison()
p.plot_control_signals(start, n)
p.plot_trajectory_projections()
```

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
| `StateMode` | `ORIGINAL`, `AUGMENTED` |

---

## Log Structure

After `s.run(nsim)`, access via `s.m_log.run`:

| Field | Size | Description |
|-------|------|-------------|
| `iter` | nsim×1 | Cycle index |
| `exitflag` | nsim×1 | Solver status (1=ok, 44=held, -2=infeasible) |
| `x0` | nsim×n | State at end of each cycle |
| `ek` | nsim×n | Error $e_k = x_0 - x_{target}$ |
| `dtk` | nsim×p | Applied control |
| `time_qp` | nsim×1 | QP solve time [s] |
