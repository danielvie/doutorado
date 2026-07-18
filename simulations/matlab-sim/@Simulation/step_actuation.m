function [cycle_config, metrics] = step_actuation( ...
    self, cycle_config, switching_offsets)
    % Apply switching-instant offsets to the nominal switching schedule.
    % Offsets are absolute corrections, not cumulative cycle-to-cycle changes.

    nominal_boundary_times = self.m_config.Ts;
    applied_boundary_times = self.compute_ts_from_dtk( ...
        nominal_boundary_times, switching_offsets);

    applied_dwell_us = diff(applied_boundary_times * 1e6);
    assert(all(applied_dwell_us > 0), ...
        "step_actuation :: dwell duration must be positive!");

    cycle_config.Ts = applied_boundary_times;
    metrics.time_us = arrayfun(@round, applied_dwell_us);
    metrics.time_us_diff = metrics.time_us;
end
