
function res = patino2(save_fig, nsim_in)
    if (nargin == 0)
        save_fig = false;
    end
    
    nsim = 100;
    if (nargin >= 1)
        nsim = nsim_in;
    end


    % get configuration
    config = engine.get_config_sim_patino_2();

    %% calculo da trajetoria

    % get custom options for the fmincon
    opt = engine.get_otmin_opt(config);
    opt.MaxFunctionEvaluations = 500*12;
    opt.Display = 'iter';
    opt.ConstraintTolerance = 1e-5;
    % opt.PlotFcn = 'optimplotfvalconstr';

    config.quant = 0.022e-3;
    [config, x, ~] = engine.otmin(config, opt);

    % save `config` in WS
    assignin('base', "config", config);

    %% rodando simulacao como resultado da trajetoria
    cfg = config;

    dT = x;
    cfg.Ts = engine.get_ts(dT);
    cfg.x0 = engine.get_x0(config);
    % nsim = 300;

    % cfg.x0 = cfg.x0 + [4.5; 1.1; 3.1];
    % cfg.x0 = [0.0, 0.0, 0.0];
    % cfg.x0 = [19.2928,9.9247,0.9823];
    % cfg.x0 = [7.6113, 20.8227, 0.0317];


    % config_.x0 = x0;
    % [y,t,u] = sim_1(config_);

    [y, t, m] = engine.sim_n2(cfg, nsim);

    % getting vars from the function
    vout = utils.getAllVars();
    res = resultados.ResPatino2(vout);

    % plot dos resultados
    f1 = figure(1);
    res.plot_xi();

    f2 = figure(2);
    res.plot_traj();

    f3 = figure(3);
    res.plot_u_signal();
    
    res.data.f1 = f1;
    res.data.f2 = f2;
    res.data.f3 = f3;

    if (save_fig)
        fprintf("salvando figuras\n\n");

        addr = "../LATEX_tese/Cap2/fig/";
        % saving figures

        config.fig_width = 8;
        config.fig_height = 10;
        save_figure(f1, "graf_patino2_xi.pdf", addr, config);
        save_figure(f2, "graf_patino2_traj.pdf", addr);
        save_figure(f3, "graf_patino2_u_signal.pdf", addr);

        %% copy figures to latex
        % copyfile('graf_ex2_*.pdf', "../../LATEX_tese/Cap2/fig/");
    end

end


