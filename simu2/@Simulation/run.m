function [y,t,m,dtk_out] = run(self, nsim)
    % Main simulation loop
    % Orchestrates the Control -> Actuation -> Physics -> Logging cycle.

    % --- 1. Initialization ---
    [buffers, current_config, state] = initialize_run(self, nsim);

    % --- 2. Simulation Loop ---
    for k = 1:nsim

        % A. Control Step: Compute dtk (timing deviation)
        if current_config.mpc.on
            [dtk, exitflag, qp_info] = self.step_control(state.x0, current_config.mpc.x_target);
        else
            dtk = zeros(numel(current_config.Omega)-1, 1);
            exitflag = 0;
            qp_info = struct('time_qp', 0);
        end

        % B. Actuation Step: Convert dtk to cycle timings (Ts)
        [current_config, time_metrics] = self.step_actuation(current_config, dtk);

        % C. Physics Step: Simulate the cycle
        [y_cycle, t_cycle, m_cycle] = self.sim_cycle_switching(current_config);

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
    p = modes_len - 1; % number of control variables

    % Memory Allocation (main simulation buffers)
    buffers.y       = zeros(nsim*modes_len + 1, states_len);
    buffers.t       = zeros(nsim*modes_len + 1, 1);
    buffers.m       = zeros(nsim*modes_len + 1, 1);
    buffers.dtk_out = zeros(p, nsim);

    % Initial Conditions (t=0)
    buffers.y(1, :) = config.x0';
    buffers.t(1)    = 0.0;
    buffers.m(1)    = config.Omega(1);

    % Pre-allocate log arrays (avoids O(n^2) concatenation in hot loop)
    log_pre          = struct();
    log_pre.iter     = zeros(nsim, 1);
    log_pre.exitflag = zeros(nsim, 1);
    log_pre.time_us  = zeros(nsim, modes_len);
    log_pre.x0       = zeros(nsim, states_len);
    log_pre.ek       = zeros(nsim, states_len);
    log_pre.ts       = zeros(nsim, modes_len + 1);
    log_pre.x_target = zeros(nsim, states_len);
    log_pre.time_qp  = zeros(nsim, 1);
    log_pre.dtk      = zeros(nsim, p);
    log_pre.dtk_prev = zeros(nsim, p);
    self.m_log.run   = log_pre;

    % Simulation State
    state.x0       = config.x0;
    state.t0       = 0.0;
    state.dtk_prev = zeros(p, 1);

    % Reset Controller
    if ~isempty(self.m_controller)
        self.m_controller.reset();
    end
end

function [state, buffers] = update_and_log(self, state, buffers, config, ...
    y_cycle, t_cycle, m_cycle, dtk, time_metrics, qp_info, exitflag, k)
    % Updates buffers, simulation state, and internal logger

    modes_len = numel(config.Omega);

    % 1. Update Result Buffers
    idx_start = (k-1) * modes_len + 2;
    idx_end   = idx_start + modes_len - 1;

    buffers.y(idx_start:idx_end, :) = y_cycle;
    buffers.t(idx_start:idx_end)    = t_cycle + state.t0;
    buffers.m(idx_start:idx_end)    = m_cycle;
    buffers.dtk_out(:, k)           = dtk;

    % 2. Update Simulation State for next iteration
    state.t0       = state.t0 + t_cycle(end);
    state.x0       = y_cycle(end, :)';
    state.dtk_prev = dtk;

    % 3. Detailed Logging (pre-allocated, index-based insertion)
    self.m_log.run.iter(k)        = k;
    self.m_log.run.exitflag(k)    = exitflag;
    self.m_log.run.time_us(k, :)  = time_metrics.time_us;
    self.m_log.run.x0(k, :)       = state.x0';
    self.m_log.run.ek(k, :)       = (state.x0 - config.mpc.x_target)';
    self.m_log.run.ts(k, :)       = config.Ts;
    self.m_log.run.x_target(k, :) = config.mpc.x_target';
    self.m_log.run.time_qp(k)     = qp_info.time_qp;
    self.m_log.run.dtk(k, :)      = dtk';
    self.m_log.run.dtk_prev(k, :) = state.dtk_prev';
end
