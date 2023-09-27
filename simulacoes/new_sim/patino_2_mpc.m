%% init
clear all;

% get configuration
config = engine.get_config_sim_patino_2();
config.tstep = 1e-7;

%% calculo da trajetoria

% get custom options for the fmincon
opt = engine.get_otmin_opt(config);
opt.MaxFunctionEvaluations = 500*12;
opt.Display = 'iter';
opt.ConstraintTolerance = 1e-4;
% opt.PlotFcn = 'optimplotfvalconstr';

% open figure
% figure(5);
% clf();

[config, x, fval] = engine.otmin(config, opt);


%% construindo MPC
% montando valores de referencia
tr  = config.Ts(2:end);
ur  = [1, 0];
dtr = diff(config.Ts);
xr  = engine.get_xr(config);

[Phi, Gamma] = mpc.construcao_modelo_instantes(config.Ac, config.Bc, tr, xr);

N  = numel(config.Ac);
p  = N - 1;
Q  = diag([1,1,1]);
R  = eye(p);
Np = 2;

% parametros das restricoes de chaveamento
t_on  = 0.25;
t_off = 0.25;

c = [
    -dtr(1) + t_on;
    -dtr(2) + t_off;
    -dtr(3) + t_on;
    -dtr(4) + t_off;
    -dtr(5) + t_on;
    -dtr(6) + t_off;
    -dtr(7) + t_on;
    -dtr(8) + t_off;
];

[H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
    mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

% criando estrutura com dados MPC
mpc          = struct();
mpc.on       = 1;

mpc.x_target = config.x0;
mpc.H        = H;
mpc.Hf       = Hf;
mpc.Phi1Np   = Phi1Np;
mpc.Qbar     = Qbar;
mpc.Rbar     = Rbar;
mpc.Lbar     = Lbar;
mpc.cbar     = cbar;
mpc.Pf       = Pf;
mpc.Sf       = Sf;
mpc.bf       = bf;
mpc.PhiNp    = PhiNp;
mpc.p        = p;



%% rodando simulacao como resultado da trajetoria
cfg = config;

cfg.mpc = mpc;
cfg.mpc.on = true;


nsim = 50;

% cfg.x0 = cfg.x0 + [4.5; 1.1; 3.1];
% cfg.x0 = [0.0, 0.0, 0.0];
% cfg.x0 = [19.2928,9.9247,0.9823];


% config_.x0 = x0;
% [y,t,u] = sim_1(config_);

[y, t] = engine.sim_n(cfg, nsim);

% renomeando variaveis
vc1 = y(:,1);
vc2 = y(:,2);
i_l = y(:,3);


% plot dos resultados
close all;

f1 = figure(1);
plot(t, vc1);

grid on;
xlabel('t - time(s)');
ylabel('V_{c1} [V]');
set(gca,'fontsize', 15);


f2 = figure(2);
plot(t, vc2);

grid on;
xlabel('t - time(s)');
ylabel('V_{c2} [V]');
set(gca,'fontsize', 15);

f3 = figure(3);
plot(t, i_l);

grid on;
xlabel('t - time(s)');
ylabel('i_L [A]');
set(gca,'fontsize', 15);

f4 = figure(4);
y1 = engine.sim_n(cfg, 30);

vc1_ = y1(:,1);
vc2_ = y1(:,2);
i_l_ = y1(:,3);

% plot3(y1(:,1), y1(:,2), y1(:,3), 'k');
plot3(vc1_, vc2_, i_l_, 'k');

grid on;
xlabel('V_{c1} [V]');
ylabel('V_{c2} [V]');
zlabel('i_L [A]');
set(gca,'fontsize', 15);

%% saving figures
% save_figure(f1, "graf_ex2_1.pdf")
% save_figure(f2, "graf_ex2_2.pdf")
% save_figure(f3, "graf_ex2_3.pdf")
% save_figure(f4, "graf_ex2_4.pdf")

%% copy figures
% copyfile('graf_ex2_*.pdf', "../../LATEX_tese/Cap2/fig/");
