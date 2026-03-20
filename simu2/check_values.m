
s = Simulation(Enums.SimName.PATINO_1);
mpc_config = Interface.config_mpc();
mpc_config.Np = 2;
s.set_mpc(mpc_config);
controller = Controllers.MpcController(s.m_config.mpc);
s.set_controller(controller);

nsim = 2; % Just 2 iterations for speed
x0_pertubed = s.m_config.x0 + [0.2; 0.5];

s.m_config.mpc.on = false;
s.m_config.x0 = x0_pertubed;
[y_off, t_off, m_off, dtk_off] = s.run(nsim);

s.m_config.mpc.on = true;
s.m_config.x0 = x0_pertubed;
[y, t, m, dtk] = s.run(nsim);

fprintf('First 5 y_off(1, :): [%f, %f]\n', y_off(1,1), y_off(1,2));
fprintf('First 5 y(1, :):     [%f, %f]\n', y(1,1), y(1,2));

fprintf('Dtk_off (first 2): ');
for i=1:size(dtk_off, 2)
    fprintf('%f ', dtk_off(1, i));
end
fprintf('\n');

fprintf('Dtk_on (first 2): ');
for i=1:size(dtk, 2)
    fprintf('%f ', dtk(1, i));
end
fprintf('\n');

if isequal(y_off, y)
    fprintf('The trajectories are EXACTLY the same.\n');
else
    fprintf('The trajectories are DIFFERENT.\n');
    fprintf('Diff norm: %f\n', norm(y_off - y));
end
