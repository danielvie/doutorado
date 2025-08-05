function [y,t,m,dtk_out] = run(self, nsim)
    % Main simulation loop with MPC control
    % Runs nsim simulation cycles with optional MPC control
    
    % ========== INITIALIZATION ==========
    [y, t, m, dtk_out, config, simulation_state] = initialize_simulation(self, nsim);
    
    % ========== SIMULATION LOOP ==========
    for i = 1:nsim
        
        % ========== MPC CONTROL COMPUTATION ==========
        if simulation_state.mpc_on
            [dtk, exitflag, time_qp, simulation_state] = compute_mpc_control_cycle(self, config, simulation_state);
            
            % ========== CONSTRAINT APPLICATION ==========
            [config, time_us] = apply_time_constraints(self, config, dtk);
            
            % ========== DATA LOGGING ==========
            log_simulation_data(self, config, simulation_state, dtk, exitflag, time_qp, time_us);
        else
            dtk = zeros([numel(config.Omega)-1, 1]);
        end
        
        % ========== SIMULATION CYCLE EXECUTION ==========
        [y, t, m, dtk_out, config, simulation_state] = execute_simulation_cycle(self, config, y, t, m, dtk_out, dtk, i, simulation_state);
    end
end

%% ========== HELPER FUNCTIONS ==========

function [y, t, m, dtk_out, config, simulation_state] = initialize_simulation(self, nsim)
    % Initialize all simulation variables and state
    
    % Output array dimensions
    modes_len  = numel(self.m_config.Omega);
    states_len = numel(self.m_config.x0);
    dtk_len = modes_len - 1;
    
    % Initialize output arrays (add +1 to include initial state at t=0)
    y = zeros(nsim*modes_len + 1, states_len); 
    t = zeros(nsim*modes_len + 1, 1);
    m = zeros(nsim*modes_len + 1, 1);
    dtk_out = zeros(dtk_len, nsim);
    
    % Store initial state at t=0
    y(1, :) = self.m_config.x0';
    t(1) = 0.0;
    m(1) = self.m_config.Omega(1); % initial mode
    
    % Initialize configuration
    config = self.m_config;
    
    % Initialize simulation state
    simulation_state = struct();
    simulation_state.t0 = 0.0;
    simulation_state.x0 = config.x0;
    simulation_state.mpc_on = isfield(config, 'mpc') && config.mpc.on == 1;
    simulation_state.Nd = self.m_mpc_config.Nd;
    simulation_state.Nd_counter = 1;
    simulation_state.dtk_prev = zeros([numel(config.Omega)-1, 1]);
end

function [dtk, exitflag, time_qp, simulation_state] = compute_mpc_control_cycle(self, config, simulation_state)
    % Compute MPC control signal for current cycle
    
    time_qp = tic;
    
    if self.m_state_mode == Enums.StateMode.AUGMENTED
        % Augmented state mode with Nd counter
        simulation_state.Nd_counter = simulation_state.Nd_counter + 1;
        
        if simulation_state.Nd_counter < simulation_state.Nd 
            % Repeat previous control until Nd is reached
            dtk = simulation_state.dtk_prev;
            exitflag = 44; % flag indicating value is not computed
        else
            % Compute new control
            [dtk, exitflag] = compute_proportional_control(config, simulation_state.x0);
            simulation_state.Nd_counter = 1;
        end
    else
        % Original state mode
        [dtk, exitflag] = compute_proportional_control(config, simulation_state.x0);
    end
    
    % Update previous control
    simulation_state.dtk_prev = dtk;
end

function [dtk, exitflag] = compute_proportional_control(config, x0)
    % Compute proportional control law
    ek = x0 - config.mpc.x_target;
    k = config.mpc.K;
    dtk = -k * ek;
    exitflag = 1;
end

function [config, time_us] = apply_time_constraints(self, config, dtk)
    % Apply time constraints to control signal and update configuration
    
    % Get base time vector and convert control to microseconds
    time_us = self.get_time_us();
    dtk_us = dtk * 1e6;
    time_constraint_us = self.m_config.c_time(1) * 1e6;
    
    % Apply constraints using fix_dtk function
    dtk_us = fix_dtk(time_us, dtk_us, time_constraint_us);
    
    % Compute new time vector
    Ts = self.compute_ts_from_dtk(self.m_config, dtk_us * 1e-6);
    
    % Validate time vector (ensure no negative time steps)
    ts_us_diff = diff(Ts * 1e6);
    if any(ts_us_diff < 0)
        error("ASSERT :: time cannot be negative!");
    end
    
    % Update configuration with new time vector
    config.Ts = Ts;
    
    % Compute actual time increments for logging
    time_us = arrayfun(@round, diff(Ts * 1e6));
end

function log_simulation_data(self, config, simulation_state, dtk, exitflag, time_qp, time_us)
    % Log all simulation data for current iteration
    
    % Update iteration counter
    if isempty(self.m_log.run.iter)
        self.m_log.run.iter = [self.m_log.run.iter; 1];
    else
        self.m_log.run.iter = [self.m_log.run.iter; self.m_log.run.iter(end)+1];
    end
    
    % Compute error for logging
    ek = simulation_state.x0 - config.mpc.x_target;
    
    % Log all data
    self.m_log.run.exitflag = [self.m_log.run.exitflag; exitflag];
    self.m_log.run.time_us = [self.m_log.run.time_us; time_us];
    self.m_log.run.x0 = [self.m_log.run.x0; simulation_state.x0'];
    self.m_log.run.ek = [self.m_log.run.ek; ek'];
    self.m_log.run.ts = [self.m_log.run.ts; config.Ts];
    self.m_log.run.x_target = [self.m_log.run.x_target; config.mpc.x_target'];
    self.m_log.run.time_qp = [self.m_log.run.time_qp; time_qp];
    self.m_log.run.dtk = [self.m_log.run.dtk; dtk'];
    self.m_log.run.dtk_prev = [self.m_log.run.dtk_prev; simulation_state.dtk_prev'];
end

function [y, t, m, dtk_out, config, simulation_state] = execute_simulation_cycle(self, config, y, t, m, dtk_out, dtk, iteration, simulation_state)
    % Execute one simulation cycle and update all state variables
    
    modes_len = numel(self.m_config.Omega);
    
    % Run simulation cycle
    [y_, t_, m_, ~] = self.sim_cycle2(config);
    
    % Debug: Check if sim_cycle2 returns expected dimensions
    if size(y_, 1) ~= modes_len
        error('sim_cycle2 returned %d modes, expected %d', size(y_, 1), modes_len);
    end
    
    % Store results in output arrays (offset by +1 to account for initial state at t=0)
    ii = (iteration-1) * modes_len + 2; % +2 because index 1 is reserved for initial state
    y(ii:ii+modes_len-1, :) = y_(1:modes_len, :);
    t(ii:ii+modes_len-1) = t_(1:modes_len) + simulation_state.t0;
    m(ii:ii+modes_len-1) = m_(1:modes_len);
    
    % Store control signal
    dtk_out(:, iteration) = dtk(:);
    
    % Update state for next iteration
    % t_ contains absolute times within this cycle (starting from Ts(2) to Ts(end))
    % The next cycle should start where this one ended
    simulation_state.t0 = simulation_state.t0 + t_(end);
    config.x0 = y_(end, :)';
    simulation_state.x0 = config.x0;
end
