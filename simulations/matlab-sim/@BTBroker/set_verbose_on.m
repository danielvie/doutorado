function set_verbose_on(self)
    % set_verbose_on - Set the verbosity level of the BTBroker.
    %
    % Syntax: set_verbose(self, value)
    %
    % Inputs:
    %   self - Instance of the BTBroker class.
    %   value - Boolean value indicating whether to enable (true) or disable (false) verbose mode.
    %
    % Outputs:
    %   None. The function modifies the BTBroker object in place.
    
    self.set_verbose(true)
end