classdef DenseStrategy < Dynamics.StepStrategy
    methods
        function [y, t, m, u, xr] = propagate(~, config)
            [y, t, m, u, xr] = Dynamics.propagate_dense(config);
        end
    end
end
