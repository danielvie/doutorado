%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
% clear all
config = patino.init_sim_2();
config.tstep = 1e-7;

%%
% --------------------------------------
% OTMIN
% --------------------------------------

% inicializacao configuracao fmincon
opt    = patino.get_otmin_opt(config);
opt.MaxFunctionEvaluations = 500*12;
opt.Display = 'iter';
% opt.PlotFcn = 'optimplotx';
opt.ConstraintTolerance = 1e-4;
opt.PlotFcn = 'optimplotfvalconstr';

% x0     -> [...dT, ...x0]

ndt    = numel(config.Ts) - 1;

tmin   = 0.022*1e-3;
tmax   = 0.400*1e-3;
% x0     = [diff(config.Ts), config.x0];
% lb     = [ones(1, ndt)*0.022*1e-3, config.x0 - [1, 1, 0.1]];
% ub     = [ones(1, ndt)*0.088*1e-3, config.x0 + [1, 1, 0.1]];
x0     = diff(config.Ts);
lb     = ones(1, ndt)*0.022*1e-3;
ub     = ones(1, ndt)*0.088*1e-3;
A      = [];
b      = [];
Aeq    = [];
beq    = [];


figure(5);
clf();

[x, fval] = fmincon(@(x) patino.fun_custo_patino(config, x), x0, A, b, Aeq, beq, lb, ub, [], opt);

% atualizando valores
dT = x;
config.Ts = patino.get_ts(dT);
config.x0 = patino.get_x0(config);

%%
% --------------------------------------
% SIMULACAO COMPLETA
% -------------------------------------- 
nsim = 50;

config_ = config;

% config_.x0 = x0;
% [y,t,u] = sim_1(config_);

[y, t] = patino.sim_n(config_, nsim);


figure(1);
plot(t, y(:,1));

figure(2);
plot(t, y(:,2));

figure(3);
plot(t, y(:,3));

figure(7);
y1 = patino.sim_n(config_, 30);
plot3(y1(:,1), y1(:,2), y1(:,3), 'k');
grid on;