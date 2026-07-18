function lower_bound = get_switching_constraints(self)
    % Compatibility accessor for minimum dwell-duration changes.
    lower_bound = Dynamics.minimum_dwell_change(self.m_config);
end
