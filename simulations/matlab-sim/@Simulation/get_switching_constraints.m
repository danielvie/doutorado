function c = get_switching_constraints(self)
    % get_switching_constraints - Delegates to Dynamics.switching_constraints
    c = Dynamics.switching_constraints(self.m_config);
end
