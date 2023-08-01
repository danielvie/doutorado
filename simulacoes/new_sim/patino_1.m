
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

c.x0 = c.x0 + [0.1; 0.5];
nsim = 35;
[y,t,u,~] = engine.sim_n(c, nsim);

% plot dos resultados
plot(y(:,1), y(:,2));