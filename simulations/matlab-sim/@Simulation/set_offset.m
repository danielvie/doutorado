function set_offset(self, offset)
    % set_offset - Configures the offset for the simulation.
    %
    % This function sets the offset value in the simulation configuration.
    %
    % Inputs:
    %   self   - Instance of the Simulation class.
    %   offset - Offset value to be set.
    %
    % Outputs:
    %   None. The function modifies the simulation object's configuration in place.

    % Set the offset in the simulation configuration
    offset_shaped = reshape(offset, size(self.m_config.x0));
    self.m_config.x0 = self.m_config.x0 + offset_shaped;
end