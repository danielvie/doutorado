
s = Simulation(Enums.SimName.PATINO_1);
mpc = Interface.config_mpc();
s.set_mpc(mpc);

fprintf('Initial mpc.on: %d\n', s.m_config.mpc.on);

s.m_config.mpc.on = false;
fprintf('After setting false: %d\n', s.m_config.mpc.on);

s.m_config.mpc.on = true;
fprintf('After setting true: %d\n', s.m_config.mpc.on);
