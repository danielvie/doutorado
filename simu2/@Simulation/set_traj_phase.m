function set_traj_phase(self, iref)
    % disp(['set traj phase with alpha: ', num2str(alpha)]);
    disp(['set traj phase with alpha: ', num2str(iref)]);

	% dynamics of the system (Buck-Boost converter)
	param = self.config.circuit_params;
    
    % param.iMax = param.E/param.R;
    % param.iLref = alpha * param.iMax;
    
    param.iMax = param.E/param.R;
    param.iLref = iref;
    alpha = param.iLref / param.iMax;

    param.n = 3; % number of switching cells
    param.T = 0.28*1e-3; % period of the complete cycle
    
    [Omega,dT] = Helpers.industrial_solution(alpha, param.n, param.T);

    % removendo elementos com dT muito pequeno (< 1e-16)
    EPS = 1e-16;
    I = [];
    for i = 1:numel(dT)
        if dT(i) >= EPS
            I = [I;i];
        end
    end

    Omega = Omega(I);
    dT = dT(I);

    % updating config values
    self.config.Omega = Omega;
    self.config.Ts = self.calc_ts(dT);
    self.config.x0 = self.get_x0();

end