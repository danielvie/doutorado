
%% init
% clear

% get configuration
config = engine.get_config_sim_patino_1();

%% calculo da trajetoria
[config, x, fval] = engine.otmin(config);
disp(x);
disp(fval);

%% rodando simulacao como resultado da trajetoria
c = config;

c.x0 = c.x0;
nsim = 30;
[y,t,u,~] = engine.sim_n(c, nsim);

%% plot dos resultados

% grafico 1
f1 = figure(1);
hold off;

plot(y(:,1), y(:,2), 'LineWidth', 2); hold on;
plot(c.xref(1), c.xref(2), 'rx');

axis equal;
grid on;
xlabel('x1 - capacitor voltage');
ylabel('x2 - inductor current');
set(gca,'fontsize', 15);

% grafico 2
f2 = figure(2);
hold off;

i = t < c.Ts(end);
plot(t(i), u(i), 'linew', 3); hold on;
grid on;
xlabel('t - time(s)');
ylabel('u - input command');
set(gca,'fontsize', 15);


%% saving figures
save_figure(f1, "graf_ex1_1.pdf")
save_figure(f2, "graf_ex1_2.pdf")

%% copy figures
% copyfile('graf_ex1_*.pdf', "../../LATEX_tese/Cap2/fig/");
