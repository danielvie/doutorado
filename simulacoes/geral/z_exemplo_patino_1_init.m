%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = engine.get_config_sim_patino_1();

%%
% --------------------------------------
% FMINCON
% --------------------------------------

[config, x, fval] = engine.otmin(config);

% --------------------------------------
% RESULTADOS
% --------------------------------------

%%
% otimizacao
disp('-----------------------------------')
fprintf('RESULTADOS:\n');
disp(['x    : [', num2str(x, '%.7f, ') ']']);
disp(['dT   : [', num2str(x(1:2), '%.7f, ') ']']);
disp(['Ts   : [', num2str(engine.get_ts(x), '%.7f, ') ']']);
disp(['fval : ', num2str(fval)]);