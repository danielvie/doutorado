# Getting Started

Step-by-step tutorial for first-time users.

## Quick Run (Using Task Runner)

The fastest way to run pre-configured simulations:

```matlab
t('play')              % Main LAB_CIRCUIT simulation
t('play_patino1')      % Patino 1 benchmark
t('play_patino2')      % Patino 2 benchmark
t('play_integrador')   % Double integrator example
t('test')              % Run test suite
t('demo', 'projection') % Feasibility projection demo
t('demo', 'broker')    % Bluetooth broker demo
t('demo', 'feasibility') % Feasibility region demo
```

Scripts are organized in `+z_run` package:
- `z_run.Scripts.*` - Simulation entry points
- `z_run.Tests.*` - Test suite
- `z_run.Demos.*` - Interactive demos

## 1. Your First Simulation (Manual)

```matlab
% Create simulation object
s = Simulation(Enums.SimName.LAB_CIRCUIT);

% Set duty cycle (0.5 = 50%)
s.alpha(0.5);

% Configure MPC matrices
s.set_mpc();

% Run simulation
[y, t, m] = s.run(1000);
```

**Outputs:**
- `y`: States $[v_{C1}, v_{C2}, i_L]$ at each time step
- `t`: Time vector
- `m`: Mode sequence

## 2. Visualizing Results

```matlab
vars = Utils.getAllVars();
sim_data = Results.SimulationData(vars);
plotter = Results.BuckBoostPlotter(sim_data);

plotter.plot_states();                  % Time evolution
plotter.plot_trajectory_comparison();   % 3D phase space
```

## 3. Understanding Controllers

**Proportional (LQR):** Simple feedback $\delta t_k = -K \cdot e_k$

```matlab
K = s.get_gain_k();
ctrl = Controllers.Proportional(K, 1);  % Nd=1: every cycle
s.set_controller(ctrl);
```

**MPC:** Solves QP at each step

```matlab
mpc_data = s.m_config.mpc;
ctrl = Controllers.MpcController(mpc_data);
s.set_controller(ctrl);
```

## 4. MPC vs Open Loop Comparison

```matlab
% MPC ON
s.m_config.mpc.on = true;
[y, t, m] = s.run(1000);

% Open Loop (no control)
s.m_config.mpc.on = false;
s.m_config.x0 = s.m_config.x0 + [-1; -1; -0.5];  % Add disturbance
[y_off, t_off, m_off] = s.run(1000);
```

## 5. Trying Different Circuits

```matlab
% Simpler 2-mode system
s = Simulation(Enums.SimName.PATINO_1);
s.alpha(0.5);
[y, t, m] = s.run(500);

% Academic double integrator
s = Simulation(Enums.SimName.INTEGRADOR_DUPLO);
[y, t, m] = s.run(500);  % No alpha needed for this config
```

## 6. Common Exit Flags

| Flag | Meaning | Action |
|------|---------|--------|
| 1 | Optimal | Normal |
| 44 | Held (downsampling) | Normal if `Nd > 1` |
| 0 | Max iterations | Check constraints |
| -2 | Infeasible | State outside feasibility region |

Check logs: `s.m_log.run.exitflag`

## Next Steps

- [`COOKBOOK.md`](COOKBOOK.md): Command reference
- [`THEORY.md`](THEORY.md): How MPC works mathematically
- [`API_REFERENCE.md`](API_REFERENCE.md): All classes and methods
