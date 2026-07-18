function set_traj_phase_with_alpha(self, alpha)

    if ~self.can_compute_phase()
        fprintf(2, ['NOMINAL SCHEDULE PLANNING REQUIRES ', ...
            'PATINO_2 OR LAB_CIRCUIT.\n']);
        return;
    end

    disp(['set nominal duty ratio: ', num2str(alpha)]);

    % Build the nominal schedule and cycle-start orbit anchor.
    [Omega, Ts, x0] = self.m_planner.set_alpha(alpha, self.m_config);

    % Apply the nominal schedule and use its anchor as the initial state.
    self.m_config.Omega = Omega;
    self.m_config.Ts = Ts;
    self.m_config.orbit_anchor = x0;
    self.m_config.x0 = x0;

    % Update the desired operating point.
    params = self.m_config.circuit_params;
    params.iMax  = params.E / params.R;
    params.iLref = alpha * params.iMax;

    self.m_config.xref = [1/3*params.E; 2/3*params.E; params.iLref];
end
