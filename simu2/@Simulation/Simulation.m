classdef Simulation < handle
    properties
        config;
        mpc;
    end

    methods
        % .. constructor
        function self = Simulation()
            % disp('starting `Simulacao` class')
        end

        % .. preparation
        success = set_config(self, sim_name);
        set_traj_phase(self, params);
        set_traj_phase_with_iref(self, iref);
        set_traj_phase_with_alpha(self, alpha);
        set_mpc(self);

        set_alpha_and_mpc(self, alpha);
        set_alpha_and_mpc_cached(self, alpha);

        % .. simulation
        [y,t,u,m,dtk_out] = run(self, nsim);
        [y,t,m,xr] = sim_cycle(self, config);
        [y,t,m,xr] = sim_cycle2(self, config);

        time_us = signal_process(self, state);
        
        % .. helpers
        Ts_out  = quantizacao(self, Ts, type);
        
        time_us = get_time_us(self);
        modes = get_mode(self);
    end
end