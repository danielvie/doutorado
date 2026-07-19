classdef Mpc
    properties
        Np (1,1) double {mustBeInteger, mustBePositive} = 5;  % Prediction-model transitions
        Nd (1,1) double {mustBeInteger, mustBePositive} = 15; % Held-input block length [cycles]
        Q double = [];        % Custom weighting matrix for MPC
        x_target double = []; % Deprecated: cycle target is the orbit anchor
        linearization_method = Enums.LinearizationMethod.SWITCHING_TIME;
        state_mode = Enums.StateMode.ORIGINAL;
        solver_algorithm = 'active-set';
        solver_display = 'off';
    end
end
