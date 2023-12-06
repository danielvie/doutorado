%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = engine.get_config_sim_patino_1();

%%
% --------------------------------------
% OTIMIZACAO - Calculo Trajetoria
% --------------------------------------

[config, x, fval] = engine.otmin(config);

%%
% --------------------------------------
% SIMULACAO COM CONTROLADOR MPC
% --------------------------------------

z_exemplo_patino_1_mpc;