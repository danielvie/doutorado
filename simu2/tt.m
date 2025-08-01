% play

alpha = 0.1;
s.set_traj_phase_with_alpha(alpha);

m = s.get_msg_control_signal();
b.msg(m);