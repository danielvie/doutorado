function set_traj_phase_with_alpha(self, alpha)
    % set_traj_phase_with_alpha - Set the trajectory phase with a given alpha value.
    %
    % Syntax: set_traj_phase_with_alpha(self, alpha)
    %
    % Inputs:
    %   self - Instance of the Simulation class.
    %   alpha - Alpha value for the simulation.
    %
    % Outputs:
    %   None. The function modifies the simulation object in place.

    if ~self.can_compute_phase()
        fprintf(2, 'CANNOT COMPUTE PHASE. EXPECTED PATINO_2 OR LAB_CIRCUIT.\n');
        return;
    end

    disp(['set traj phase with alpha: ', num2str(alpha)]);

	% dynamics of the system (Buck-Boost converter)
	params = self.config.circuit_params;
    
    params.alpha = alpha;
    params.iMax = params.E/params.R;
    params.iLref = params.alpha * params.iMax;

    params.n = 3; % number of switching cells
    params.T = 0.28*1e-3; % period of the complete cycle
    
    self.set_traj_phase(params);

end