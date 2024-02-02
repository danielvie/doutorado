function var_out = patino1(save_fig)

    if (nargin == 0)
        save_fig = false;
    end

    % get configuration
    config = engine.get_config_sim_patino_1();

    %% calculo da trajetoria
    [config, ~, ~] = engine.otmin(config);

    %% rodando simulacao como resultado da trajetoria
    c = config;

    c.x0 = c.x0;
    nsim = 30;
    [y, t, u, m] = engine.sim_n(c, nsim);
    % [y, t, m] = engine.sim_n(c, nsim);

    %% plot dos resultados

    % grafico 1
    f1 = figure(1);
    plotter.patino1.plot_traj(y, c.xref, "Buck-Boost Converter: Cyclic Trajectory", "x_1 - Voltage Capacitor C", "x_2 - Current Inductor L");

    % grafico 2
    f2 = figure(2);

    % i = t < c.Ts(end);
    % plotter.patino1.plot_control_signal(t(i), m(i), "Buck-Boost Converter Signal Command", "t - time (s)", "u - switch command");
    plotter.patino1.plot_control_signal(t, m, "Buck-Boost Converter Signal Command", "t - time (s)", "u - switch command");

    % get variables
    var_out = utils.getAllVars();

    if (save_fig)
        %% saving figures
        save_figure(f1, "graf_patino1_traj.pdf", "../LATEX_tese/Cap2/fig/");
        save_figure(f2, "graf_patino1_u_signal.pdf", "../LATEX_tese/Cap2/fig/");
    end
    
end
