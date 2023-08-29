
%% clear values
% clear

% get configuration
config = engine.get_config_sim_patino_1();

% calculo da trajetoria
[config, x, fval] = engine.otmin(config);
disp(x);
disp(fval);

%% rodando simulacao como resultado da trajetoria
c = config;

c.x0 = c.x0;
nsim = 30;
[y,t,u,~] = engine.sim_n(c, nsim);

%% plot dos resultados
figure(1);
hold off;
f = plot(y(:,1), y(:,2), 'LineWidth', 2);
hold on;
plot(c.xref(1), c.xref(2), 'rx');
axis equal;
grid on;
xlabel('x1 - xapacitor voltage');
ylabel('x2 - inductor current');
set(gca,'fontsize', 15);

figure(2);
hold off;

i = t < c.Ts(end);
f = plot(t(i), u(i), 'linew', 2);
grid on;
xlabel('t - time(s)');
ylabel('u - input command');
set(gca,'fontsize', 15);
