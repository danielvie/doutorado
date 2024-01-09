function plot_xi(t, y)
    subplot(3,1,1);
    plotter.patino2_mpc.plot_xi_helper(t, y(:,1), 'Voltage C_1 Multilevel Converter', 't - time(s)', 'V_{c1} [V]')
    subplot(3,1,2);
    plotter.patino2_mpc.plot_xi_helper(t, y(:,2), 'Voltage C_2 Multilevel Converter', 't - time(s)', 'V_{c2} [V]')
    subplot(3,1,3);
    plotter.patino2_mpc.plot_xi_helper(t, y(:,3), 'Current i_L Multilevel Converter', 't - time(s)', 'i_{L} [A]')
end

