%%
% --------------------------------------
% CONFIG INICIAL
% --------------------------------------
clear all
config = patino.init_sim_1();

config.x0   = [1.8662830, -1.1178948,];
config.Ts   = [0.0000000, 0.2510512, 0.5010512,];
config.Xr   = reshape([1.8662830,  2.1173230,  1.8662811, -1.1178948, -0.8697124, -1.1178922,],[3  2]);

%%
% --------------------------------------
% SIMULACAO COMPLETA
% -------------------------------------- 

nsim = 50;

c = config;
c.x0 = c.x0  + [0.1, 0.5];
[y,t,u] = patino.sim_n(c, nsim);


figure(2);
clf();
hold on;

plot(y(:,1), y(:,2));
plot(c.xref(1), c.xref(2), '+', 'linew', 2, 'markersize', 10, 'color', patino.CORES.VERMELHO);

% ultimo ciclo
c    = config;
c.x0 = y(end,:);
yend = patino.sim_1(c);

plot(yend(:,1), yend(:,2), 'k', 'linew', 2);
axis equal;
fprintf('xend ultimo ciclo: %.6f, %.6f\n', c.x0(1), c.x0(2));
grid on;

