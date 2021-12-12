%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = engine.get_config_sim_patino_1();

%% Otimizacao

[config, x, fval] = engine.otmin(config);

% --------------------------------------
% RESULTADOS
% --------------------------------------

% otimizacao
disp('-----------------------------------')
fprintf('RESULTADOS:\n');
disp(['x    : [', num2str(x, '%.7f, ') ']']);
disp(['dT   : [', num2str(x(1:2), '%.7f, ') ']']);
disp(['Ts   : [', num2str(engine.get_ts(x), '%.7f, ') ']']);
disp(['fval : ', num2str(fval)]);

%%
% --------------------------------------
% SIMULACAO COMPLETA
% -------------------------------------- 

nsim = 50;

c = config;
% c.x0 = c.x0 + [0., 0.];

c.x0 = c.x0 + [0.1; 0.5];
[y,t,u] = engine.sim_n(c, nsim);


figure(2);
clf();
hold on;

plot(y(:,1), y(:,2));
plot(c.xref(1), c.xref(2), '+', 'linew', 2, 'markersize', 10, 'color', engine.CORES.VERMELHO);

% ultimo ciclo
c    = config;
c.x0 = y(end,:);
yend = engine.sim_1(c);

plot(yend(:,1), yend(:,2), 'k', 'linew', 2);
axis equal;
fprintf('xend ultimo ciclo: %.6f, %.6f\n', c.x0(1), c.x0(2));
grid on;

