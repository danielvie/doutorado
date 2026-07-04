function target = get_target(self)
    target = self.m_config.control.x_target;
    if isempty(target)
        error('Control target is not configured. Call set_mpc(options) first or set config.control.x_target explicitly.');
    end
end
