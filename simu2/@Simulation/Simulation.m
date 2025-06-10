classdef Simulation < handle
    properties
        m_config;
        m_set_alpha_cache;
        m_mpc_config;
        m_state_mode;
        m_log;
    end

    methods(Hidden = true)
        set_traj_phase(self, params);
        res = can_compute_phase(self);
    end

    methods
        % .. constructor
        function self = Simulation(sim_name)

            if nargin < 1
                fprintf('Simulation name not provided. Using default.\n');
            else
                self.set_config(sim_name);
            end
            
            % default mpc_config
            self.m_mpc_config = self.get_mpc_config();
            
            % default state mode
            self.m_state_mode = Enums.StateMode.ORIGINAL;

            % log structure
            log_struct = struct();
            log_struct.iter = [];
            log_struct.exitflag = [];
            log_struct.time_us = [];
            log_struct.x0 = [];
            log_struct.x_target = [];
            log_struct.time_qp = [];
            log_struct.dtk = [];
            log_struct.dtk_prev = [];
            
            self.m_log.run = log_struct;
            self.m_log.signal = log_struct;
        end

        % .. setters
        success = set_config(self, sim_name);

        set_offset(self, offset);

        set_traj_phase_with_iref(self, iref);
        set_traj_phase_with_alpha(self, alpha);
        set_mpc(self, Np);

        set_alpha_and_mpc(self, alpha);
        set_alpha_and_mpc_cached(self, alpha, Np);
        save_set_alpha_cache(self);
        
        % .. getters
        mpc_config = get_mpc_config(self);

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
        name_out = name(self);
        [Phi, Gamma] = get_phi_gamma(self);
        c = get_switching_constraints(self);
        Ts_out  = quantizacao(self, Ts, type);

        time_us = get_time_us(self);
        modes = get_mode(self);
    end
end
