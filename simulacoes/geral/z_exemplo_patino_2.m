%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all;
config = engine.init_sim_patino_2();
config.tstep = 1e-7;

%%
% --------------------------------------
% OTMIN
% --------------------------------------

% inicializacao configuracao fmincon
opt    = engine.get_otmin_opt(config);
opt.MaxFunctionEvaluations = 500*12;
opt.Display = 'iter';
opt.ConstraintTolerance = 1e-4;
opt.PlotFcn = 'optimplotfvalconstr';

figure(5);
clf();

% [x, fval] = fmincon(@(x) engine.fun_custo_patino(config, x), x0, A, b, Aeq, beq, lb, ub, [], opt);
[config, x, fval] = engine.otmin(config, opt);

% atualizando valores
dT = x;
config.Ts = engine.get_ts(dT);
config.x0 = engine.get_x0(config);

%%
% --------------------------------------
% SIMULACAO COMPLETA
% -------------------------------------- 
nsim = 50;

config_ = config;

% config_.x0 = x0;
% [y,t,u] = sim_1(config_);

[y, t] = engine.sim_n(config_, nsim);

figure(1);
plot(t, y(:,1));

figure(2);
plot(t, y(:,2));

figure(3);
plot(t, y(:,3));

figure(7);
y1 = engine.sim_n(config_, 30);
plot3(y1(:,1), y1(:,2), y1(:,3), 'k');
grid on;