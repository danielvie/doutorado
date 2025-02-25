function set_traj_phase_with_iref(self, iref)
    disp(['set traj phase with iref: ', num2str(iref)]);

	% dynamics of the system (Buck-Boost converter)
	params = self.config.circuit_params;
    
    params.iLref = iref;
    params.iMax = params.E/params.R;
    params.alpha = params.iLref / params.iMax;

    params.n = 3; % number of switching cells
    params.T = 0.28*1e-3; % period of the complete cycle
    
    self.set_traj_phase(params);
end