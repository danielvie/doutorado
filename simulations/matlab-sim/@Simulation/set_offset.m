function set_offset(self, initial_state_disturbance)
    % Apply an additive disturbance to the simulation initial state.

    disturbance = reshape(initial_state_disturbance, size(self.m_config.x0));
    self.m_config.x0 = self.m_config.x0 + disturbance;
end