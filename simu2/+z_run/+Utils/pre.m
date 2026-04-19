function pre()
    % setting simulation
    s = Simulation();
    success = s.set_config(Enums.SimName.LAB_CIRCUIT);

    % check if data is loaded
    if (~success)
        disp('ending simulation!!');
        return
    end
    
    % s.set_traj_phase_with_iref(0.07);
    % s.set_traj_phase_with_alpha(0.2);
    % s.set_mpc();

    assignin("base", "s", s);
end