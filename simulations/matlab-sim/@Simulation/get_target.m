function orbit_anchor = get_target(self)
    orbit_anchor = self.m_config.control.x_target;
    if isempty(orbit_anchor)
        error('Cycle-boundary orbit target is not configured. Call set_mpc(options).');
    end
end
