%% rodando simulacao como resultado da trajetoria


% bla = load('bla.mat');
% config = bla.config;

cfg = config;

cfg.mpc.on = true;


nsim = 50;

% estados
% 1. vc1
% 2. vc2
% 3. i

cfg.x0  = config.x0 + [-2;1;-1];
% cfg.x0 = config.x0 + [0.5; 1.1; 3.1];
% cfg.x0 = [0.0, 0.0, 0.0];
% cfg.x0 = [19.2928,9.9247,0.9823];


% config_.x0 = x0;
% [y,t,u] = sim_1(config_);

[y,t,u,m,dtk_out] = engine.sim_n(cfg, nsim);

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
y1 = engine.sim_n(cfg, nsim);

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
