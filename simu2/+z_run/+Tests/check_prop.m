
s = Simulation(Enums.SimName.PATINO_1);
mpc = Interface.config_mpc();
s.set_mpc(mpc);

fprintf('Before setting false: s.m_config.mpc.on = %d\n', s.m_config.mpc.on);

s.m_config.mpc.on = false;
fprintf('After setting false: s.m_config.mpc.on = %d\n', s.m_config.mpc.on);

config_copy = s.m_config;
fprintf('In copy: config_copy.mpc.on = %d\n', config_copy.mpc.on);

if s.m_config.mpc.on == 1
    fprintf('WARNING: Property did not change correctly!\n');
end
