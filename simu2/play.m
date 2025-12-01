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
    s = Simulation(Enums.SimName.LAB_CIRCUIT);
    % s.m_state_mode = Enums.StateMode.AUGMENTED;
    
    % compute trajectory with alpha
    % s.set_traj_phase_with_alpha(0.3);
    s.set_traj_phase_with_alpha(0.5);

    % set MPC parameters

    config_mpc = s.get_config_mpc();
    config_mpc.Nd = 3;
    config_mpc.Np = 25;

    s.set_config_mpc(config_mpc);
    s.set_mpc();

    % number of simulation cycles
    nsim = 500;

    % add error in IC
    % s.m_config.x0 = s.m_config.x0 + [0.6; 0.1; 0.1];
    s.m_config.x0 = [0.0; 0.0; 0.0];

    % running simulation
    s.m_config.mpc.on = true;
    [y, t, m] = s.run(nsim);

    s.m_config.mpc.on = false;
    [y_off, t_off, m_off] = s.run(nsim);

    % getting variables from simulation
    vars = Utils.getAllVars();

    % creating results object
    res = Results.Patino2(vars);

    % saving in workspace
    assignin('base', 's', s);
    assignin('base', 'res', res);

    assignin('base', 'log', s.m_log);


    % plotting states
    figure(1);
    res.plot_xi();

    % plotting trajectory
    figure(2);
    res.plot_traj();
   
    
    % plotting u signals
    figure(3);
    res.plot_u_signals(50);
end