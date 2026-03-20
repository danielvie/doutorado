
s = Simulation(Enums.SimName.PATINO_1);
mpc_config = Interface.config_mpc();
mpc_config.Np = 10;
mpc_config.Q = diag([1, 1]);
s.set_mpc(mpc_config);
% MUST SET CONTROLLER!
controller = Controllers.MpcController(s.m_config.mpc);
s.set_controller(controller);

% Change constraints to be very permissive
s.m_config.c_time = [0.01, 0.01]; 

x0_pertubed = s.m_config.x0 + [0.3; 0.5];
s.m_config.x0 = x0_pertubed;
[y, t, m, dtk] = s.run(1); 

fprintf('Dtk with permissive constraints: %f\n', dtk(1, 1));
