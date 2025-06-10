function play()
    % play - Main function to run the simulation and analyze results.
    %
    % This function initializes a simulation object, configures its parameters,
    % and runs the simulation with and without Model Predictive Control (MPC).
    % It then processes and visualizes the results.
    %
    % Outputs:
    % - None. The function modifies the workspace and generates plots.


    % creating simulation object
    s = Simulation(Enums.SimName.LAB_CIRCUIT);
    s.m_state_mode = Enums.StateMode.AUGMENTED;
    
    % compute trajectory with alpha
    s.set_traj_phase_with_alpha(0.5);
    % s.set_alpha_and_mpc_cached(0.5);

    % set MPC parameters

    mpc_config = s.get_mpc_config();
    mpc_config.Nd = 5;
    mpc_config.Np = 25;
    s.set_mpc_config(mpc_config)

    s.set_mpc();

    % number of simulation cycles
    nsim = 1000;

    % add error in IC
    s.m_config.x0 = s.m_config.x0 + [0.6; 0.1; 0.1];
    % s.set_offset([0.6, 0.2, 0.1]);

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

    % plotting states
    % figure(1);
    % res.plot_xi();

    % plotting trajectory
    figure(2);
    res.plot_traj();

    % plotting u signals
    % figure(3);
    % res.plot_u_signals(20);
end