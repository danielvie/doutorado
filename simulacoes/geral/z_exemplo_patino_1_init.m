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

% atualizando valores
dT = x;
config.Ts = patino.get_ts(dT);
config.x0 = patino.get_x0(config);
% Xr        = get_xr(config);
Xr        = patino.get_xr_1();
Xr_       = sim.get_xr(config);

% calculando `xr`
[~,~,~,~,xr] = patino.sim_1(config);

% --------------------------------------
% RESULTADOS
% --------------------------------------

%%
% otimizacao
disp('-----------------------------------')
fprintf('RESULTADOS:\n');
disp(['config.x0   = [', num2str(config.x0, '%.7f, ') '];']);
disp(['config.Ts   = [', num2str(config.Ts, '%.7f, ') '];']);

[i,j] = size(xr);
disp(['config.Xr   = reshape([',num2str(xr(:)', '%.7f, ') '],[' num2str([i, j]) ']);']);

% fprintf('config.Xr = [\n');

% disp(num2str(xr(:)'))

