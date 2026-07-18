function [y, t, m, dtk_out] = run(self, nsim)
    % Run control, actuation, and physics cycles from the configured state.

    [config, buffers] = initialize_run(self, nsim);

    cycle_input_state = config.x0;
    elapsed_time = 0.0;
    previous_switching_offsets = zeros(numel(config.Omega) - 1, 1);

    for k = 1:nsim
        % Control and propagation share the same cycle input state.
        config.x0 = cycle_input_state;

        % Control: offset the nominal interior switching instants.
        if config.control.on
            [switching_offsets, exitflag, qp_info] = ...
                self.step_control(cycle_input_state, config.control.x_target);
        else
            switching_offsets = zeros(numel(config.Omega) - 1, 1);
            exitflag = 0;
            qp_info = struct('time_qp', 0);
        end

        % Actuation: apply the offsets to the nominal switching schedule.
        [config, actuation_metrics] = ...
            self.step_actuation(config, switching_offsets);

        % Physics: propagate one complete switching cycle.
        [y_cycle, t_cycle, m_cycle, ~] = ...
            self.m_step_strategy.propagate(config);

        % Append this cycle to the simulated state history.
        n_cycle_samples = size(y_cycle, 1);
        idx_start = buffers.idx_current + 1;
        idx_end = buffers.idx_current + n_cycle_samples;
        buffers = ensure_buffer_capacity(buffers, idx_end, n_cycle_samples);

        buffers.y(idx_start:idx_end, :) = y_cycle;
        buffers.t(idx_start:idx_end) = t_cycle + elapsed_time;
        buffers.m(idx_start:idx_end) = m_cycle;
        buffers.dtk_out(:, k) = switching_offsets;
        buffers.idx_current = idx_end;

        % Log the inputs and decisions for this cycle.
        if isempty(config.control.x_target)
            state_setpoint = nan(size(cycle_input_state));
            tracking_error = nan(size(cycle_input_state));
        else
            state_setpoint = config.control.x_target;
            tracking_error = cycle_input_state - state_setpoint;
        end

        self.m_log.run.iter(k) = k;
        self.m_log.run.exitflag(k) = exitflag;
        self.m_log.run.time_us(k, :) = actuation_metrics.time_us;
        self.m_log.run.x0(k, :) = cycle_input_state';
        self.m_log.run.ek(k, :) = tracking_error';
        self.m_log.run.ts(k, :) = config.Ts;
        self.m_log.run.x_target(k, :) = state_setpoint';
        self.m_log.run.time_qp(k) = qp_info.time_qp;
        self.m_log.run.dtk(k, :) = switching_offsets';
        self.m_log.run.dtk_prev(k, :) = previous_switching_offsets';

        % The cycle output becomes the next cycle input.
        elapsed_time = elapsed_time + t_cycle(end);
        cycle_input_state = y_cycle(end, :)';
        previous_switching_offsets = switching_offsets;
    end

    y = buffers.y(1:buffers.idx_current, :);
    t = buffers.t(1:buffers.idx_current);
    m = buffers.m(1:buffers.idx_current);
    dtk_out = buffers.dtk_out;
end

function [config, buffers] = initialize_run(self, nsim)
    config = self.m_config;
    modes_len = numel(config.Omega);
    states_len = numel(config.x0);
    control_len = modes_len - 1;

    if config.control.on
        if isempty(self.m_controller)
            error(['Control is enabled, but no controller is configured. ', ...
                'Call set_mpc(options) or set_control_enabled(false).']);
        end
        if isempty(config.control.x_target)
            error(['Control is enabled, but config.control.x_target is empty. ', ...
                'Call set_mpc(options).']);
        end
    end

    initial_size = max(nsim * modes_len + 1, 1000);
    buffers.y = zeros(initial_size, states_len);
    buffers.t = zeros(initial_size, 1);
    buffers.m = zeros(initial_size, 1);
    buffers.dtk_out = zeros(control_len, nsim);
    buffers.idx_current = 1;

    buffers.y(1, :) = config.x0';
    buffers.t(1) = 0.0;
    buffers.m(1) = config.Omega(1);

    log_run = struct();
    log_run.iter = zeros(nsim, 1);
    log_run.exitflag = zeros(nsim, 1);
    log_run.time_us = zeros(nsim, modes_len);
    log_run.x0 = zeros(nsim, states_len);
    log_run.ek = zeros(nsim, states_len);
    log_run.ts = zeros(nsim, modes_len + 1);
    log_run.x_target = zeros(nsim, states_len);
    log_run.time_qp = zeros(nsim, 1);
    log_run.dtk = zeros(nsim, control_len);
    log_run.dtk_prev = zeros(nsim, control_len);
    self.m_log.run = log_run;

    if ~isempty(self.m_controller)
        self.m_controller.reset();
    end
end

function buffers = ensure_buffer_capacity(buffers, required_size, cycle_size)
    if required_size <= size(buffers.y, 1)
        return;
    end

    growth = max(1000, cycle_size * 2);
    buffers.y = [buffers.y; zeros(growth, size(buffers.y, 2))];
    buffers.t = [buffers.t; zeros(growth, 1)];
    buffers.m = [buffers.m; zeros(growth, 1)];
end
