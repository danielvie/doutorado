function [config, metrics] = step_actuation(self, config, dtk)
    % step_actuation - Convert control signal (dtk) to switching times.
    %
    % The dtk is assumed to be already conditioned by the controller
    % (e.g., Proportional applies constraint conditioning internally,
    %  MPC handles it via QP constraints).

    % Compute new time vector
    Ts = self.compute_ts_from_dtk(self.m_config, dtk);

    % Validate: all intervals must be positive
    ts_us_diff = diff(Ts * 1e6);
    assert(all(ts_us_diff > 0), "step_actuation :: time cannot be negative!");

    % Update configuration
    config.Ts = Ts;

    % Metrics
    metrics.time_us = arrayfun(@round, diff(Ts * 1e6));
    metrics.time_us_diff = metrics.time_us; % alias
end
