
s = Simulation(Enums.SimName.PATINO_1);
mpc_config = Options.Mpc();
mpc_config.Np = 2;
s.set_mpc(mpc_config);
controller = Controllers.MpcController(s.m_config.mpc);
s.set_controller(controller);

nsim = 2;
x0_pertubed = s.m_config.x0 + [0.2; 0.5];

s.set_control_enabled(true);
s.m_config.x0 = x0_pertubed;
[y, t, m, dtk] = s.run(nsim);

log_run = s.m_log.run;
fprintf('QP Exitflags: ');
disp(log_run.exitflag');

fprintf('Dtk values: ');
disp(dtk);
