
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

% plot dos resultados
hold off;
f = plot(y(:,1), y(:,2), 'LineWidth', 2);
hold on;
plot(c.xref(1), c.xref(2), 'rx');
axis equal;
grid on;
xlabel('x1 - Capacitor voltage');
ylabel('x2 - Inductor current');
set(gca,'fontsize', 15);