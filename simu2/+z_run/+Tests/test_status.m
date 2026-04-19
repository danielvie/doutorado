clear;

s = Simulation();
s.set_config(Enums.SimName.LAB_CIRCUIT);

config_mpc = s.get_config_mpc();
config_mpc.Nd = 15;
config_mpc.Np = 1; % Nd - Number of delays in the block (repeated control)
 
s.set_config_mpc(config_mpc);
s.set_traj_phase_with_alpha(0.5);
s.set_mpc();
 
msg_data = s.get_msg_control_signal();

b = BTBroker();
b.simulation = s;
% b.msg(msg_data);
b.control_on = false;

b.set_control_off;
% b.msg("TOGGLE_SET_B");
% b.msg("CONTROL_ON");
b.v_off;

b.ss(0.5);
% b.tg_b();
b.st();

% b.sa();
% pause(0.3);
% b.x();
% b.st();

% b.st();

% b.s(0.5);
% b.sa

% -k*ek =
% 
% -0.00129366826422298
%  0.00129306126582899
% -0.00042003017300946
%  0.00041587370621232
% -0.00234865174015572
