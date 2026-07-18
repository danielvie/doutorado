function model = get_cycle_linear_model(self)
    % Return the nominal one-cycle orbit-deviation equation.
    model = Dynamics.linearize_cycle(self.m_config);
end
