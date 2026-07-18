classdef Controller < handle
    methods (Abstract)
        % Computes the control action
        % Inputs:
        %   x: Cycle input state
        %   x_target: Orbit anchor at the controlled cycle boundary
        % Outputs:
        %   dtk: Switching-instant offsets
        %   exitflag: Solver status
        %   info: additional info struct (time_qp, etc)
        [dtk, exitflag, info] = compute_control(self, x, x_target)
        
        % Reset internal state (for new simulation)
        reset(self)
    end
end
