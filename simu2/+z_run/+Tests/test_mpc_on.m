
s = Simulation(Enums.SimName.PATINO_1);
mpc = Options.Mpc();
s.set_mpc(mpc);

fprintf('Initial mpc.on: %d\n', s.m_config.mpc.on);

s.set_control_enabled(false);
fprintf('After setting false: %d\n', s.m_config.mpc.on);

s.set_control_enabled(true);
fprintf('After setting true: %d\n', s.m_config.mpc.on);
