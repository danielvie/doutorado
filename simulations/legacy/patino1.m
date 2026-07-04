function res = patino1(save_fig)

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

    % get variables
    var_out = utils.getAllVars();
    res = resultados.ResPatino1(var_out);

    %% plot dos resultados
    % grafico 1
    f1 = figure(1);
    res.plot_traj();

    % grafico 2
    f2 = figure(2);
    res.plot_u_signal();
    
    res.data.f1 = f1;
    res.data.f2 = f2;

    if (save_fig)
        %% saving figures
        save_figure(f1, "graf_patino1_traj.pdf", "../LATEX_tese/Cap2/fig/");
        save_figure(f2, "graf_patino1_u_signal.pdf", "../LATEX_tese/Cap2/fig/");
    end
    
end
