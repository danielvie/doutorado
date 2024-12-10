% SCRIPT TO CREATE SIGNAL TO TESTE CIRCUIT

% reading config data
config = engine.get_config_sim_patino_2();

% setting `iref`
param = struct();
param.E = 30;
param.C(1) = 40e-6;
param.C(2) = 40e-6;
param.L = 10*1e-3;
param.R = 10;

param.iMax = param.E/param.R;
param.iLref = 1; % << this is the current setpoint
param.alpha = param.iLref / param.iMax; % duty cycle

param.n = 3; % number of swtching cells
param.T = 0.28*1e-3;

[Omega, dT] = phase_shift.industrial_solution(param.alpha, param.n, param.T);

config.Omega = Omega;

% creating `cfg` for simulation
cfg = config;
cfg.Ts = engine.get_ts(dT);
cfg.x0 = engine.get_x0(cfg);

% number of cycles to simulate
nsim = 40;

% % save config in WS
% assignin('base', 'config', config);
% assignin('base', 'cfg', cfg);

% run simulation
[y, t, m] = engine.sim_n2(cfg, nsim);

% plotting result traj
vc1 = y(:,1);
vc2 = y(:,2);
i_l = y(:,3);

figure(1);
clf()
plot3(vc1, vc2, i_l);
grid on;
title('Multilevel Converter: Trajectory');
xlabel('X_1: Voltage C_1 [V]');
ylabel('X_2: Voltage C_2 [V]');
zlabel('X_3: Current L [A]');

% plotting result xi
figure(2);
clf()

subplot(3, 1, 1);
plot(t, vc1);
xlabel('t - time(s)');
ylabel('voltage c_1 [V]');

subplot(3, 1, 2);
plot(t, vc2);
xlabel('t - time(s)');
ylabel('voltage c_2 [V]');

subplot(3, 1, 3);
plot(t, i_l);
xlabel('t - time(s)');
ylabel('current L [A]');



% iref = 8/22; % por que esse valor?
% res = compute_phase(config, iref);

% disp(res);

% ts_us = res.Ts*1e6;
% disp('Ts (us):');
% disp(ts_us);

% disp('dTs (us):');
% disp(diff(ts_us));

% disp('modes:')
% disp(res.Omega);


