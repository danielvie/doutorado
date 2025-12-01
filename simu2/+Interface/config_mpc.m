classdef config_mpc
    properties
        Np double = 5;  % Np - Prediction horizon
        Nd double = 15; % Nd - Number of delays in the block (repeated control)
    end
end