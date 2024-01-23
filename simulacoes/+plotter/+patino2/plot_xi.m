function plot_xi(t, y) 
    vc1 = y(:,1);
    vc2 = y(:,2);
    i_l = y(:,3);

    subplot(3, 1, 1);
    plotter.patino2.plot_xi_helper(t, vc1, "Multilevel Converter: X_1", "t - time(s)", "Voltage C_1 [V]");

    subplot(3, 1, 2);
    plotter.patino2.plot_xi_helper(t, vc2, "Multilevel Converter: X_2", "t - time(s)", "Voltage C_2 [V]");

    subplot(3, 1, 3);
    plotter.patino2.plot_xi_helper(t, i_l, "Multilevel Converter: X_3", "t - time(s)", "Voltage L [A]");
end

