function set_verbose(self, value)
    % set_verbose - Set the verbosity level of the BTBroker.
    %
    % Syntax: set_verbose(self, value)
    %
    % Inputs:
    %   self - Instance of the BTBroker class.
    %   value - Boolean value indicating whether to enable (true) or disable (false) verbose mode.
    %
    % Outputs:
    %   None. The function modifies the BTBroker object in place.
    
    if nargin < 2
        error('Not enough input arguments. Usage: set_verbose(self, value)');
    end
    
    if ~islogical(value)
        error('Input "value" must be a boolean (true/false).');
    end
    
    self.verbose = value;
end