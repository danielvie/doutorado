function [y,t,m,dtk_out] = run(self, nsim)
    % Main simulation loop
    % Orchestrates the Control -> Actuation -> Physics -> Logging cycle.
    
    % --- 1. Initialization ---
    [buffers, current_config, state] = initialize_run(self, nsim);
    
    % --- 2. Simulation Loop ---
    for k = 1:nsim
        
        % A. Control Step: Compute dtk (timing deviation)
        [dtk, exitflag, qp_info] = self.step_control(state.x0, current_config.mpc.x_target);
        
        % B. Actuation Step: Convert dtk to cycle timings (Ts)
        [current_config, time_metrics] = self.step_actuation(current_config, dtk);
        
        % C. Physics Step: Simulate the cycle
        [y_cycle, t_cycle, m_cycle] = self.sim_cycle2(current_config);
        
        % D. Storage & State Update
        [state, buffers] = update_and_log(self, state, buffers, current_config, ...
                                          y_cycle, t_cycle, m_cycle, ...
                                          dtk, time_metrics, qp_info, exitflag, k);
                                          
        % E. Propagate State to Config (for next cycle physics)
        current_config.x0 = state.x0;
    end
    
    % --- 3. Output Formatting ---
    y = buffers.y;
    t = buffers.t;
    m = buffers.m;
    dtk_out = buffers.dtk_out;
end

% -------------------------------------------------------------------------
% Helper Functions (Internal)
% -------------------------------------------------------------------------

function [buffers, config, state] = initialize_run(self, nsim)
    % Initialize simulation configuration, state, and memory buffers
    
    config = self.m_config;
    modes_len = numel(config.Omega);
    states_len = numel(config.x0);
    
    % Memory Allocation
    buffers.y = zeros(nsim*modes_len + 1, states_len); 
    buffers.t = zeros(nsim*modes_len + 1, 1);
    buffers.m = zeros(nsim*modes_len + 1, 1);
    buffers.dtk_out = zeros(modes_len - 1, nsim);
    
    % Initial Conditions (t=0)
    buffers.y(1, :) = config.x0';
    buffers.t(1) = 0.0;
    buffers.m(1) = config.Omega(1); 
    
    % Simulation State
    state.x0 = config.x0;
    state.t0 = 0.0;
    state.dtk_prev = zeros(modes_len-1, 1);
    
    % Reset Controller
    if ~isempty(self.m_controller)
        self.m_controller.reset();
    end
end

function [state, buffers] = update_and_log(self, state, buffers, config, y_cycle, t_cycle, m_cycle, dtk, time_metrics, qp_info, exitflag, k)
    % Updates buffers, simulation state, and internal logger
    
    modes_len = numel(config.Omega);
    
    % 1. Update Result Buffers
    idx_start = (k-1) * modes_len + 2; 
    idx_end   = idx_start + modes_len - 1;
    
    buffers.y(idx_start:idx_end, :) = y_cycle;
    buffers.t(idx_start:idx_end)    = t_cycle + state.t0; % Absolute time
    buffers.m(idx_start:idx_end)    = m_cycle;
    buffers.dtk_out(:, k)           = dtk;
    
    % 2. Update Simulation State for next iteration
    state.t0 = state.t0 + t_cycle(end);
    state.x0 = y_cycle(end, :)';
    state.dtk_prev = dtk;
    
    % 3. Detailed Logging (Internal structure)
    % Helper to append to self.m_log (keeping existing structure)
    log = self.m_log.run;
    
    % Append logic (simplified for readability, could be optimized)
    new_iter      = k;
    if isempty(log.iter), new_iter = 1; else, new_iter = log.iter(end)+1; end
    
    log.iter      = [log.iter;      new_iter];
    log.exitflag  = [log.exitflag;  exitflag];
    log.time_us   = [log.time_us;   time_metrics.time_us];
    log.x0        = [log.x0;        state.x0']; 
    log.ek        = [log.ek;        (state.x0 - config.mpc.x_target)'];
    log.ts        = [log.ts;        config.Ts];
    log.x_target  = [log.x_target;  config.mpc.x_target'];
    log.time_qp   = [log.time_qp;   qp_info.time_qp];
    log.dtk       = [log.dtk;       dtk'];
    log.dtk_prev  = [log.dtk_prev;  state.dtk_prev'];
    
    self.m_log.run = log;
end
