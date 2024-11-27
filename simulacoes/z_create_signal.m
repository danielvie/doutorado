

config = engine.get_config_sim_patino_2();
iref = 8/22; % por que esse valor?
res = compute_phase(config, iref);

disp(res);

ts_us = res.Ts*1e6;
disp('Ts (us):');
disp(ts_us);

disp('dTs (us):');
disp(diff(ts_us));

disp('modes:')
disp(res.Omega);

% param.E = 5;
% param.C(1) = 470e-6;
% param.C(2) = 470e-6;
% param.L = 100*1e-3;
% param.R = 22;

