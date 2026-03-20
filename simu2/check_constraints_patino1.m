
s = Simulation(Enums.SimName.PATINO_1);
mpc_config = Interface.config_mpc();
s.set_mpc(mpc_config);

fprintf('Constraints c:\n');
c = Dynamics.switching_constraints(s.m_config);
disp(c);

fprintf('Nominal dtr:\n');
disp(diff(s.m_config.Ts)');

fprintf('c_time:\n');
disp(s.m_config.c_time);
