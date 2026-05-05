classdef Mpc
    properties
        Np (1,1) double {mustBeInteger, mustBePositive} = 5;  % Prediction horizon
        Nd (1,1) double {mustBeInteger, mustBePositive} = 15; % Control hold/downsampling factor
        Q double = [];        % Custom weighting matrix for MPC
        x_target double = []; % Optional target override
        state_mode = Enums.StateMode.ORIGINAL;
        solver_algorithm = 'active-set';
        solver_display = 'off';
    end
end
