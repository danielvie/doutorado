classdef StepStrategy < handle
    methods (Abstract)
        [y, t, m, u, xr] = propagate(self, config)
    end
end
