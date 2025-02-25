function set_traj_phase_with_alpha(self, alpha)
    disp(['set traj phase with alpha: ', num2str(alpha)]);
    % disp(['set traj phase with alpha: ', num2str(iref)]);

	% dynamics of the system (Buck-Boost converter)
	params = self.config.circuit_params;
    
    params.alpha = alpha;
    params.iMax = params.E/params.R;
    params.iLref = params.alpha * params.iMax;

    params.n = 3; % number of switching cells
    params.T = 0.28*1e-3; % period of the complete cycle
    
    self.set_traj_phase(params);

end