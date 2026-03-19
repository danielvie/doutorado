function play()
% play - Main function to run the simulation and analyze results.
%
% This function initializes a simulation object, configures its parameters,
% and runs the simulation with and without Model Predictive Control (MPC).
% It then processes and visualizes the results.
%
% Outputs:c
% - None. The function modifies the workspace and generates plots.


% creating simulation object
s = Simulation(Enums.SimName.PATINO_2);
% s.m_state_mode = Enums.StateMode.AUGMENTED;

% compute trajectory with alpha
% s.set_traj_phase_with_alpha(0.3);
s.set_traj_phase_with_alpha(0.8);

% set MPC parameters

config_mpc = s.get_config_mpc();
config_mpc.Nd = 3;
config_mpc.Np = 25;

s.set_config_mpc(config_mpc);
s.set_mpc();

% Setup Controller (Strategy Pattern)
K = s.get_gain_k();
time_us = s.get_time_us();
min_gap_us = s.m_config.c_time(1) * 1e6;
% For original mode, use Nd = 1. For Augmented/Hold mode, use config_mpc.Nd
controller = Controllers.Proportional(K, 1, time_us, min_gap_us); 
% controller = Controllers.MpcController(mpc_data); 
s.set_controller(controller);

% number of simulation cycles
nsim = 100;

% add error in IC
% s.m_config.x0 = s.m_config.x0 + [0.6; 0.1; 0.1];
s.m_config.x0 = [0.0; 0.0; 0.0];

% running simulation
s.m_config.mpc.on = false;
[y_off, t_off, m_off] = s.run(nsim);

s.m_config.mpc.on = true;
[y, t, m] = s.run(nsim);


% getting variables from simulation
vars = Utils.getAllVars();

% --- NEW RESULTS ARCHITECTURE ---
% 1. Create Standardized Data Container
sim_data = Results.SimulationData(vars);

% 2. Create Specialized Plotter
plotter = Results.BuckBoostPlotter(sim_data);

% saving in workspace
assignin('base', 's', s);

% plotting states
figure(1);
plotter.plot_states();

% plotting trajectory
figure(2);
plotter.plot_trajectory_comparison();

% plotting commands
figure(3);
plotter.plot_control_signals(1, 50);

% plotting metrics
stats = sim_data.calculate_metrics();
disp('Simulation Metrics:');
disp(stats);
end
