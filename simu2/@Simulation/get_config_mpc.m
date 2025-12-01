function config = get_config_mpc(~)
    config = Interface.config_mpc();

    config.Np = 5; % Np - Prediction horizon
    config.Nd = 15; % Nd - Number of delays in the block (repeated control)
end