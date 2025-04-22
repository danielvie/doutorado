function play()
    % setting simulation
    s = Simulation();
    success = s.set_config(Enums.SimName.PATINO_2);

    % check if data is loaded
    if (~success)
        disp('ending simulation!!');
        return
    end
    
    %s.set_traj_phase_with_iref(0.07);
    s.set_traj_phase_with_alpha(0.4);
    s.set_mpc();
    %s.set_alpha_and_mpc_cached(0.5);

    % number of cycles
    nsim = 100;

    % add error in IC
    s.config.x0 = s.config.x0;

    % running simulation
    s.config.mpc.on = true;
    [y, t, m] = s.run(nsim);
    disp("x0_on:");
    disp(s.config.x0);

    s.config.mpc.on = false;
    [y_off, t_off, m_off] = s.run(nsim);
    disp("x0_off:");
    disp(s.config.x0);

    % getting variables from simulation
    vars = Helpers.getAllVars();

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