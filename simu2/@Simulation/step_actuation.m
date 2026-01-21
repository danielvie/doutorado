function [config, metrics] = step_actuation(self, config, dtk)
    % Calculates actuation timings based on control signal (dtk)
    
    % Get base time vector and convert control to microseconds
    time_us = self.get_time_us();
    dtk_us = dtk * 1e6;
    time_constraint_us = self.m_config.c_time(1) * 1e6;
    
    % Apply constraints
    dtk_us = self.condition_dtk_signal(time_us, dtk_us, time_constraint_us);
    dtk_us = round(dtk_us);

    % Compute new time vector
    Ts = self.compute_ts_from_dtk(self.m_config, dtk_us * 1e-6);
    
    % Validate
    ts_us_diff = diff(Ts * 1e6);
    assert(all(ts_us_diff > 0), "step_actuation :: time cannot be negative!");
    
    % Update configuration
    config.Ts = Ts;
    
    % Metrics
    metrics.time_us = arrayfun(@round, diff(Ts * 1e6));
    metrics.time_us_diff = metrics.time_us; % alias
end
