
s = Simulation(Enums.SimName.PATINO_1);
mpc_config = Interface.config_mpc();
mpc_config.Np = 2;
s.set_mpc(mpc_config);
controller = Controllers.MpcController(s.m_config.mpc);
s.set_controller(controller);

nsim = 5;
x0_pertubed = s.m_config.x0 + [0.2; 0.5];

s.m_config.mpc.on = false;
s.m_config.x0 = x0_pertubed;
[y_off, t_off, m_off] = s.run(nsim);

s.m_config.mpc.on = true;
s.m_config.x0 = x0_pertubed;
[y, t, m] = s.run(nsim);

fprintf('Sum(y_off): %f\n', sum(y_off(:)));
fprintf('Sum(y): %f\n', sum(y(:)));

if isequal(y_off, y)
    fprintf('The trajectories are EXACTLY the same.\n');
else
    fprintf('The trajectories are DIFFERENT.\n');
    fprintf('Diff norm: %f\n', norm(y_off - y));
end
