

% Phi
%   1, 6
%   0, 1

% Gamma
%   4, 3, -1
%   1, 1, -1

clear mpc;

bla = load('bla.mat');
config = bla.config;
cfg = config;
cfg.x0 = config.x0 + [0.1; 1.9; -1];
nsim = 20;

cfg.mpc.on = true;
[y,t,u,m,dtk_out] = engine.sim_n(cfg, nsim);

[y2,t2,u2,m2,dtk_out2, yy,tt,mm] = engine.sim_n2(cfg, nsim);

figure(1);
plot3_(y, 'linew', 2);
hold on;
plot3_(yy, 'markers', 20, 'linew', 3);
hold off;
axis equal;
grid on;

figure(2);
stairs(t,m, 'linew', 2);
hold on;
stairs(tt,mm, 'linew', 2, 'lines','--');
hold off;

xlim([0, 0.003]);

figure(3);
plot_i(y, t, yy, tt, 1);

figure(4);
plot_i(y, t, yy, tt, 2);

figure(5);
plot_i(y, t, yy, tt, 3);

figure(6);
plot_signal(m, t, mm, tt);

function plot3_(y, varargin)
    plot3(y(:,1), y(:,2), y(:,3), varargin{:});
end

function plot_i(y, t, yy, tt, i)
    plot(t,y(:,i))
    hold on;
    plot(tt,yy(:,i))
    hold off;
end

function plot_signal(m, t, mm, tt)
    stairs(t,m)
    hold on;
    stairs(tt,mm)
    hold off;
    title('compare signal');
end