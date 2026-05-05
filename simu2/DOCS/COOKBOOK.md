# Command Cookbook

Copy-paste snippets for common tasks.

## Quick Tasks (t.m)

```matlab
t('play', 'lab')        % Run main simulation
t('play', 'patino1')    % Patino 1 benchmark
t('play', 'patino2')    % Patino 2 benchmark
t('play', 'integrador') % Double integrator
t('test')           % Run tests
t('demo', 'broker') % Run broker demo
t('projection', 'patino1') % Run projection script
t('clean')          % Clean outputs
t('docs')           % Open documentation
```

## Simulation Setup

```matlab
% Load circuit
s = Simulation(Enums.SimName.LAB_CIRCUIT);

% Set trajectory
s.alpha(0.5);                    % Duty cycle 50%
% OR
s.iref(0.1);                     % Reference current 0.1A

% Configure MPC (required before run)
mpc_options = Options.Mpc();
s.set_mpc(mpc_options);

% Run
[y, t, m] = s.run(1000);
```

## Controllers

```matlab
% Proportional (LQR)
K = s.get_gain_k();
ctrl = Controllers.Proportional(K, 1);  % Nd=1
s.set_controller(ctrl);

% MPC basic
mpc_data = s.m_config.mpc;
ctrl = Controllers.MpcController(mpc_data);
s.set_controller(ctrl);

% MPC with downsampling (compute every N cycles)
ctrl = Controllers.MpcController(mpc_data, 'Nd', 3);

% MPC with augmented state (delay compensation)
mpc_options = Options.Mpc();
mpc_options.state_mode = Enums.StateMode.AUGMENTED;
s.set_mpc(mpc_options);

% Disable controller (open loop)
s.set_control_enabled(false);
```

## Step Strategies

```matlab
% Fast propagation at switching instants (default, control loops)
s.set_step_strategy(Dynamics.SwitchingStrategy());

% High-resolution propagation for detailed plots
s.set_step_strategy(Dynamics.DenseStrategy());
```

## Visualization

```matlab
vars = Utils.getAllVars();
sim_data = Results.SimulationData(vars);
plotter = Results.BuckBoostPlotter(sim_data);

```matlab
plotter.plot_states();                          % vC1, vC2, iL vs time
plotter.plot_trajectory_comparison();           % MPC vs open loop 3D
plotter.plot_control_signals(1, 50);            % First 50 cycles
plotter.plot_trajectory_projections();          % 2D projections
plotter.plot_trajectory_animated();             % Animated 3D evolution
```

## Feasibility Regions

```matlab
% Plot feasibility region
s.alpha(0.5);
s.set_mpc(Options.Mpc());
fig = s.project_feasibility_region();

% Try different horizons
fig = s.project_feasibility_region([1, 2, 4, 8]);
```

## Hardware (BTBroker)

```matlab
b = BTBroker();          % Connect

% Setup
b.alpha(0.5);            % Set duty cycle and upload
b.s(0.5);                % Alias for above
b.ss(0.5);               % Set + send complete signal

% Control
b.sa();                  % Start (alias: start)
b.so();                  % Stop (alias: stop, x)
b.x();                   % Emergency stop

% Status
b.st();                  % Get status
b.ma();                  % Get matrix A
b.mb();                  % Get matrix B

% Verbose mode
b.v_on();                % Enable debug output
b.v_off();               % Disable
```

## Custom MPC Parameters

```matlab
mpc_options = Options.Mpc();
mpc_options.Np = 10;              % Prediction horizon
mpc_options.Nd = 2;               % Downsampling
mpc_options.Q = diag([10, 10, 1]); % State weights [vC1, vC2, iL]
mpc_options.state_mode = Enums.StateMode.ORIGINAL;
mpc_options.solver_algorithm = 'active-set';
mpc_options.solver_display = 'off';
s.set_mpc(mpc_options);
```

## State Manipulation

```matlab
% Set initial condition
s.m_config.x0 = [4.0; 3.0; 0.05];  % [vC1; vC2; iL]

% Add offset to equilibrium
s.set_offset([0.5; 0; 0]);

% Get target state
target = s.get_target();  % Where controller tries to go
```

## Quick Aliases

```matlab
s.alpha(0.5);     % s.set_traj_phase_with_alpha(0.5)
s.iref(0.1);      % s.set_traj_phase_with_iref(0.1)
```
