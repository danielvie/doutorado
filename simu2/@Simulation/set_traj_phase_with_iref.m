function set_traj_phase_with_iref(self, iref)

    if ~self.can_compute_phase()
        fprintf(2, 'CANNOT COMPUTE PHASE. EXPECTED PATINO_2 OR LAB_CIRCUIT.\n');
        return;
    end

    disp(['set traj phase with iref: ', num2str(iref)]);

	% dynamics of the system (Buck-Boost converter)
	params = self.m_config.circuit_params;
    
    params.iLref = iref;
    params.iMax = params.E/params.R;
    params.alpha = params.iLref / params.iMax;

    params.n = 3; % number of switching cells
    params.T = 0.28*1e-3; % period of the complete cycle
    
    self.set_traj_phase(params);
end