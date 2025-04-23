classdef Simulation < handle
    properties
        config;
        set_alpha_cache;
        log;
    end
    
    methods(Hidden = true)
        set_traj_phase(self, params);
    end

    methods
        % .. constructor
        function self = Simulation(sim_name)

            if nargin < 1
                fprintf('Simulation name not provided. Using default.\n');
            else
                self.set_config(sim_name);
            end

            % log structure
            self.log = struct();
            self.log.iter = [];
            self.log.exitflag = [];
            self.log.time_us = [];
            self.log.x0 = [];
            self.log.x_target = [];
            self.log.time_qp = [];
        end

        % .. preparation
        success = set_config(self, sim_name);

        set_traj_phase_with_iref(self, iref);
        set_traj_phase_with_alpha(self, alpha);
        set_mpc(self);

        set_alpha_and_mpc(self, alpha);
        set_alpha_and_mpc_cached(self, alpha);
        save_set_alpha_cache(self);

        % .. simulation
        [y,t,u,m,dtk_out] = run(self, nsim);
        [y,t,m,xr] = sim_cycle(self, config);
        [y,t,m,xr] = sim_cycle2(self, config);

        time_us = signal_process(self, state);
        
        % .. projection
        fig = project_feasibility_region(self);

        % .. aliases
        alpha(self, value);
        iref(self, value);

        % .. automation
        project_with_alpha(self, alpha, folder, flag_save);
        
        % .. helpers
        name(self);
        [Phi, Gamma] = get_phi_gamma(self);
        c = get_switching_constraints(self);
        Ts_out  = quantizacao(self, Ts, type);
        
        time_us = get_time_us(self);
        modes = get_mode(self);
    end
end