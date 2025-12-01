s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);

config_mpc = s.get_config_mpc();
config_mpc.Nd = 15;
config_mpc.Np = 1; % Nd - Number of delays in the block (repeated control)

s.set_config_mpc(config_mpc);

s.set_traj_phase_alpha_and_mpc(0.9);

s.get_gain_k()*[1;2;3];