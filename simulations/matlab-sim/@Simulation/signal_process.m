function [dwell_us, switching_offsets] = signal_process( ...
    self, measured_state, previous_switching_offsets)
    % Compute and log one hardware-facing control action.

    config = self.m_config;
    cycle_input_state = measured_state(:);
    orbit_anchor = config.control.x_target;
    if isempty(orbit_anchor) || isempty(self.m_controller)
        error('signal_process requires a configured controller. Call set_mpc(options).');
    end

    [switching_offsets, exitflag, control_info] = ...
        self.m_controller.compute_control(cycle_input_state, orbit_anchor);

    applied_boundary_times = self.quantizacao( ...
        config.Ts, Enums.QuantType.Sim);
    for boundary = 1:numel(switching_offsets)
        applied_boundary_times(boundary + 1) = ...
            applied_boundary_times(boundary + 1) + switching_offsets(boundary);
    end
    applied_dwell_us = diff(applied_boundary_times * 1e6);
    assert(all(applied_dwell_us > 0), ...
        'signal_process :: dwell duration must be positive!');
    dwell_us = arrayfun(@round, applied_dwell_us);

    if isempty(self.m_log.signal.iter)
        iteration = 1;
    else
        iteration = self.m_log.signal.iter(end) + 1;
    end
    orbit_deviation = cycle_input_state - orbit_anchor;

    self.m_log.signal.iter = [self.m_log.signal.iter; iteration];
    self.m_log.signal.exitflag = [self.m_log.signal.exitflag; exitflag];
    self.m_log.signal.time_us = [self.m_log.signal.time_us; dwell_us];
    self.m_log.signal.x0 = [self.m_log.signal.x0; cycle_input_state'];
    self.m_log.signal.ek = [self.m_log.signal.ek; orbit_deviation'];
    self.m_log.signal.x_target = ...
        [self.m_log.signal.x_target; orbit_anchor'];
    self.m_log.signal.time_qp = ...
        [self.m_log.signal.time_qp; control_info.time_qp];
    self.m_log.signal.dtk = [self.m_log.signal.dtk; switching_offsets'];
    self.m_log.signal.dtk_prev = ...
        [self.m_log.signal.dtk_prev; previous_switching_offsets'];
end
