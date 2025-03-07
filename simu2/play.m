function play()
    % setting simulation
    s = Simulation();
    success = s.set_config(Enums.SimName.LAB_CIRCUIT);

    % check if data is loaded
    if (~success)
        disp('ending simulation!!');
        return
    end
    
    % s.set_traj_phase_with_iref(0.07);
    s.set_traj_phase_with_alpha(0.5);
    s.set_mpc();

    % number of cycles
    nsim = 40;

    % add error in IC
    s.config.x0 = s.config.x0 + [0.1; -0.01; 0.01];

    % running simulation
    s.config.mpc.on = true;
    [y, t, m] = s.run(nsim);

    s.config.mpc.on = false;
    [y_off, t_off, m_off] = s.run(nsim);

    % getting variables from simulation
    vars = Utils.getAllVars();

    % creating results object
    res = Results.Patino2(vars);

    % saving in workspace
    assignin('base', 's', s);
    assignin('base', 'res', res);

    % plotting states
    figure(1);
    res.plot_xi();

    % plotting trajectory
    figure(2);
    res.plot_traj();

    % plotting u signals
    figure(3);
    res.plot_u_signals(20);
end