%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = patino.init_sim_1();

%%
% --------------------------------------
% FMINCON
% --------------------------------------
opt    = patino.get_otmin_opt(config);
opt.ConstraintTolerance = 1e-8;
opt.PlotFcn = 'optimplotfvalconstr';

% x0     = [0.25, 0.25, config.x0];
% lb     = [0.25, 0.25, config.x0 - 2.0];
% ub     = [1.50, 1.50, config.x0 + 2.0];
x0     = [0.25, 0.25];
lb     = [0.25, 0.25];
ub     = [1.50, 1.50];
A      = [];
b      = [];
Aeq    = [];
beq    = [];

[x, fval] = fmincon(@(x) patino.fun_custo_patino(config, x), x0, A, b, Aeq, beq, lb, ub, [], opt);

% --------------------------------------
% RESULTADOS
% --------------------------------------

% otimizacao
disp('-----------------------------------')
fprintf('RESULTADOS:\n');
disp(['x    : [', num2str(x, '%.7f, ') ']']);
disp(['dT   : [', num2str(x(1:2), '%.7f, ') ']']);
disp(['Ts   : [', num2str(patino.get_ts(x), '%.7f, ') ']']);
disp(['fval : ', num2str(fval)]);

%%
% --------------------------------------
% SIMULACAO COMPLETA
% -------------------------------------- 

nsim = 50;

c = config;
c.x0 = c.x0 + [0., 0.];
[y,t,u] = patino.sim_n(c, nsim);


figure(2);
clf();
hold on;

plot(y(:,1), y(:,2));
plot(c.xref(1), c.xref(2), '+', 'linew', 2, 'markersize', 10, 'color', patino.CORES.VERMELHO);

% ultimo ciclo
c    = config;
c.x0 = y(end,:);
yend = patino.sim_1(c);

plot(yend(:,1), yend(:,2), 'k', 'linew', 2);
axis equal;
fprintf('xend ultimo ciclo: %.6f, %.6f\n', c.x0(1), c.x0(2));
grid on;

