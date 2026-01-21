function set_controller(self, controller)
    % Assigns a controller strategy to the simulation
    if ~isa(controller, 'Controllers.Controller')
        error('Input must be a subclass of Controllers.Controller');
    end
    self.m_controller = controller;
end
