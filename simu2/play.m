
s = Simulation();
s.set_config(Enums.SimName.PATINO_2)
s.set_traj_phase(0.8);
s.set_mpc();


% number of cycles
nsim = 40;

% add error in IC
s.config.x0 = s.config.x0 + [2.5; -2.3; 1.1];

s.config.mpc.on = true;
[y, t, m] = s.run(nsim);

s.config.mpc.on = false;
[y_off, t_off, m_off] = s.run(nsim);

% plot results
figure(11);
subplot(3,1,1);
plot(t, y(:,1))
subplot(3,1,2);
plot(t, y(:,2))
subplot(3,1,3);
plot(t, y(:,3))

figure(12);
plot3(y(:,1), y(:,2), y(:,3));
hold on;
plot3(y_off(:,1), y_off(:,2), y_off(:,3));
hold off;