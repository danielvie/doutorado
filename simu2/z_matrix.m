s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);

mpc_config = s.get_mpc_config();
mpc_config.Nd = 15;
mpc_config.Np = 1; % Nd - Number of delays in the block (repeated control)

s.set_mpc_config(mpc_config);

s.set_traj_phase_alpha_and_mpc(0.9);

s.get_gain_k()*[1;2;3];