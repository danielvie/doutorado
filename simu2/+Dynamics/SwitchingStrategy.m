classdef SwitchingStrategy < Dynamics.StepStrategy
    methods
        function [y, t, m, u, xr] = propagate(~, config)
            [y, t, m, xr] = Dynamics.propagate_switching(config);
            u = zeros(size(t)); % Dummy values for inputs
        end
    end
end
