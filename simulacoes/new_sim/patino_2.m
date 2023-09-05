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
opt.PlotFcn = 'optimplotfvalconstr';

% open figure
figure(5);
clf();

[config, x, fval] = engine.otmin(config, opt);


%% rodando simulacao como resultado da trajetoria
c = config;

dT = x;
c.Ts = engine.get_ts(dT);
c.x0 = engine.get_x0(config);
nsim = 50;

c.x0 = c.x0 + [4.5; 1.1; 3.1];

% config_.x0 = x0;
% [y,t,u] = sim_1(config_);

[y, t] = engine.sim_n(c, nsim);

% plot dos resultados
figure(1);
plot(t, y(:,1));

figure(2);
plot(t, y(:,2));

figure(3);
plot(t, y(:,3));

figure(7);
y1 = engine.sim_n(c, 30);
plot3(y1(:,1), y1(:,2), y1(:,3), 'k');
grid on;
