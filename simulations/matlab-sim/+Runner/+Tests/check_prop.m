
s = Simulation(Enums.SimName.PATINO_1);
mpc = Options.Mpc();
s.set_mpc(mpc);

fprintf('Before setting false: s.m_config.control.on = %d\n', s.m_config.control.on);

s.set_control_enabled(false);
fprintf('After setting false: s.m_config.control.on = %d\n', s.m_config.control.on);

config_copy = s.m_config;
fprintf('In copy: config_copy.control.on = %d\n', config_copy.control.on);

if s.m_config.control.on == 1
    fprintf('WARNING: Property did not change correctly!\n');
end
