function set_traj_phase(self, params)
    % set_traj_phase - Set the trajectory phase for the simulation.
    % 
    % Syntax: set_traj_phase(self, params)
    %
    % Inputs:
    %   self - Instance of the Simulation class.
    %   params - Structure containing the following fields:
    %       alpha - Alpha value for the simulation.
    %       n - Number of switching cells.
    %       T - Period of the complete cycle.
    %       iMax - Maximum current (optional).
    %       iLref - Reference inductor current (optional).
    %       E - Voltage (optional).
    %       R - Resistance (optional).
    %
    % Outputs:
    %   None. The function modifies the simulation object in place.
    
    if ~self.can_compute_phase()
        fprintf(2, 'CANNOT COMPUTE PHASE. EXPECTED PATINO_2 OR LAB_CIRCUIT.\n');
        return;
    end

    [Omega,dT] = Utils.industrial_solution(params.alpha, params.n, params.T);

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
    self.m_config.Omega = Omega;
    self.m_config.Ts = Utils.get_ts(dT);
    self.m_config.x0 = Utils.get_x0(self.m_config);
    
    % printing result
    % time_us = self.m_config.Ts*1e6;
    % dt_time_us = diff(time_us);

    % disp('Omega: ');
    % disp(Omega - 1);
    % disp('time_us: ');
    % disp(time_us);
    % disp('dt_time_us: ');
    % disp(dt_time_us);
    % disp('x0: ');
    % disp(self.m_config.x0);

end