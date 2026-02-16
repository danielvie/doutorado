function set_traj_phase_with_iref(self, iref)

    if ~self.can_compute_phase()
        fprintf(2, 'CANNOT COMPUTE PHASE. EXPECTED PATINO_2 OR LAB_CIRCUIT.\n');
        return;
    end

    disp(['set traj phase with iref: ', num2str(iref)]);

    % Delegate to Trajectory.Planner
    [Omega, Ts, x0] = self.m_planner.set_reference_current(iref, self.m_config);

    % Apply computed trajectory to config
    self.m_config.Omega = Omega;
    self.m_config.Ts    = Ts;
    self.m_config.x0    = x0;

    % Update derived params
    params = self.m_config.circuit_params;
    params.iMax = params.E / params.R;
    alpha = iref / params.iMax;

    self.m_config.xref = [1/3*params.E; 2/3*params.E; iref];
    self.m_config.mpc.x_target = self.m_config.xref;
end