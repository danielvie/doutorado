classdef Controller < handle
    methods (Abstract)
        % Computes the control action
        % Inputs:
        %   x: Current state vector
        %   x_target: Target state vector
        % Outputs:
        %   dtk: Control action
        %   exitflag: Solver status
        %   info: additional info struct (time_qp, etc)
        [dtk, exitflag, info] = compute_control(self, x, x_target)
        
        % Reset internal state (for new simulation)
        reset(self)
    end
end
