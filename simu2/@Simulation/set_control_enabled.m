function set_control_enabled(self, flag)
    if ~isscalar(flag) || ~(islogical(flag) || isnumeric(flag))
        error('set_control_enabled expects a scalar logical or numeric flag.');
    end

    enabled = logical(flag);
    if enabled
        if isempty(self.m_controller)
            error('Cannot enable control without a controller. Call set_mpc(options) or set_controller(controller) first.');
        end
        if ~isprop(self.m_config, 'control') || isempty(self.m_config.control.x_target)
            error('Cannot enable control without config.control.x_target. Call set_mpc(options) first.');
        end
    end

    self.m_config.control.on = enabled;
end
