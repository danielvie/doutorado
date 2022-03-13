%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = engine.get_config_sim_patino_1();

%% otimizacao
% --------------------------------------
% FMINCON
% --------------------------------------
[config, x, fval] = engine.otmin(config);

% --------------------------------------
% RESULTADOS
% --------------------------------------

%
% otimizacao
disp(['x    : [', num2str(x, '%.7f, ') ']']);
disp(['dT   : [', num2str(x(1:2), '%.7f, ') ']']);
disp(['Ts   : [', num2str(config.Ts, '%.7f, ') ']']);
disp(['fval : ', num2str(fval)]);