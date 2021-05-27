%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = doc.init_sim_2();

%%
% --------------------------------------
% PARAMETROS SIMULACAO
% --------------------------------------
[x, fval] = fmincon(@(x) doc.fun_custo_patino(o.config, x), config.x0, o.A, o.b, o.Aeq, o.beq, o.lb, o.ub, @(x) doc.nonlincon_patino(o.config, x), o.opt);

%%
% --------------------------------------
% SIMULACAO COMPLETA
% -------------------------------------- 
nsim = 50;

config_ = config;

config_.x0 = config.xref;
% [y,t,u] = sim_1(config_);

[y, t] = doc.sim_n(config_, nsim);


figure(1);
plot(t, y(:,2));

figure(2);
plot(t, y(:,3));