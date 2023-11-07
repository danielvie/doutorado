
%% clear values
clear

% get configuration
config = engine.get_config_sim_patino_1();

%% calculo da trajetoria
[config, x, fval] = engine.otmin(config);

%% construindo MPC
% montando valores de referencia
tr  = config.Ts(2:end);
ur  = [1, 0];
dtr = diff(config.Ts);
xr  = engine.get_xr(config);

[Phi, Gamma] = mpc.construcao_modelo_instantes(config.A, config.b, tr, xr, config);

N  = numel(tr);
p  = N - 1;
Q  = diag([10,1]); % por que 10???
R  = eye(p);
Np = 2;

% parametros das restricoes de chaveamento
t_on  = 0.25;
t_off = 0.25;

c = [
    -dtr(1) + t_on;
    -dtr(2) + t_off;
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

%% rodando simulacao com o resultado da trajetoria
cfg     = config;
cfg.mpc = mpc;
cfg.x0  = config.x0 + [0.2; 0.5];
nsim    = 40;

% simulacao com controle mpc
[y,t,u,m,dtk_out] = engine.sim_n(cfg, nsim);

% simulacao sem controle mpc
cfg.mpc.on = 0;
[y_off,t_off,u_off,m_off] = engine.sim_n(cfg, nsim);


% plot dos resultados
f1 = figure(1);

plot(y_off(:,1), y_off(:,2), 'linew', 1.2);
hold on;
plot(y(:,1), y(:,2), 'linew', 1.2);
hold off;

legend('mpc off', 'mpc on');
grid on;
axis equal;
xlabel('v_c');
ylabel('i_L');
set(gca,'fontsize', 15);


%% plot
m1     = m + 1;
m1_off = m_off + 1;

f2 = figure(2);
stairs(t_off, m1_off, 'linew', 2);
hold on;
stairs(t, m1, 'linew', 2, 'linestyle', '--');
hold off;
xlim([0, 5]);
grid on;
xlabel('time (s)');
ylabel('mode');
set(gca,'fontsize', 15);
legend('modes target trajectory', 'modes simulation');


%% save figures
save_figure(f1, "graf_ex1_1.pdf")
save_figure(f2, "graf_ex1_2.pdf")

%% copy files
% copyfile("graf_ex1_1.pdf", "../../LATEX_tese/Cap4/fig/");
% copyfile("graf_ex1_2.pdf", "../../LATEX_tese/Cap4/fig/");