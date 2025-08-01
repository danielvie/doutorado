function mpc_config = get_mpc_config(self)
    mpc_config = struct();
    mpc_config.Np = 5; % Np - Prediction horizon
    mpc_config.Nd = 15; % Nd - Number of delays in the block (repeated control)
end