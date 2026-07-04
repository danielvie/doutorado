omega = config.modes + 1;
omega(numel(omega) + 1) = omega(1);
t = config.Ts;

figure(7)
stairs(t, omega, 'linew', 2);
grid on;