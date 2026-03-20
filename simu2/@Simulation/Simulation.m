classdef Simulation < handle
    properties
        m_config;
        m_config_mpc;
        m_set_alpha_cache;
        m_state_mode;
        m_log;
        m_controller;  % Controllers.Controller instance
        m_planner;     % Trajectory.Planner instance
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

            % default config_mpc
            self.m_config_mpc = self.get_config_mpc();

            % default state mode
            self.m_state_mode = Enums.StateMode.ORIGINAL;

            % initialize Trajectory.Planner (only for Buck-Boost configs)
            if self.can_compute_phase()
                self.m_planner = Trajectory.Planner(self.m_config.circuit_params);
            end

            % log structure
            log_struct = struct();
            log_struct.iter = [];
            log_struct.exitflag = [];
            log_struct.time_us = [];
            log_struct.x0 = [];
            log_struct.ek = [];
            log_struct.ts = [];
            log_struct.x_target = [];
            log_struct.time_qp = [];
            log_struct.dtk = [];
            log_struct.dtk_prev = [];

            self.m_log.run = log_struct;
            self.m_log.signal = log_struct;
        end

        % .. setters
        success = set_config(self, sim_name);

        set_config_mpc(self, config_mpc);

        set_offset(self, offset);

        set_traj_phase_with_iref(self, iref);
        set_traj_phase_with_alpha(self, alpha);
        set_mpc(self, config_mpc);

        set_traj_phase_alpha_and_mpc(self, alpha);
        save_set_alpha_cache(self);

        set_controller(self, controller);

        % .. getters
        config_mpc = get_config_mpc(self);
        [Phi, Gamma] = get_phi_gamma(self);
        c = get_switching_constraints(self);

        msg_gain_k = get_msg_control_signal(self);
        gain_k = get_gain_k(self);
        mode = get_mode(self);
        [d1, d2, d3, d4] = get_mode_bin(self);
        time_us = get_time_us(self);
        target = get_target(self);

        % .. simulation
        [y,t,u,m,dtk_out] = run(self, nsim);

        [dtk, exitflag, info] = step_control(self, x0, x_target);
        [config, metrics] = step_actuation(self, config, dtk);

        [dtk, exitflag, time_qp] = run_mpc(self, state_run, config, x0, dtk_prev);
        [y, t, m, xr] = sim_cycle_switching(self, config);
        [y, t, m, u, xr] = sim_cycle_dense(self, config);

        [time_us, dtk] = signal_process(self, state, dtk_prev);

        % .. projection
        fig = project_feasibility_region(self, horizons, x_eq_in);

        % .. aliases
        alpha(self, value);
        iref(self, value);

        % .. automation
        project_with_alpha(self, alpha, folder, flag_save);

        % .. helpers
        name_out = name(self);
        Ts_out  = quantizacao(self, Ts, type);

        % .. diagnostics
        print_test_values(self, k, log_source);
        print_test_values_cpp(self, k, log_source);
    end
end
