function set_traj_phase(self, params)

    [Omega,dT] = Helpers.industrial_solution(params.alpha, params.n, params.T);

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
    self.config.Ts = Helpers.get_ts(dT);
    self.config.x0 = Helpers.get_x0(self.config);
    
    % printing result
    time_us = self.config.Ts*1e6;
    dt_time_us = diff(time_us);

    disp('Omega: ');
    disp(Omega - 1);
    disp('time_us: ');
    disp(time_us);
    disp('dt_time_us: ');
    disp(dt_time_us);
    disp('x0: ');
    disp(self.config.x0);

end