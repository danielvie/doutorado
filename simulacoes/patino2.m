
function vout = patino2(save_fig)
    if (nargin == 0)
        save_fig = false;
    end

    % get configuration
    config = engine.get_config_sim_patino_2();
    config.tstep = 1e-7;

    %% calculo da trajetoria

    % get custom options for the fmincon
    opt = engine.get_otmin_opt(config);
    opt.MaxFunctionEvaluations = 500*12;
    opt.Display = 'iter';
    opt.ConstraintTolerance = 1e-5;
    % opt.PlotFcn = 'optimplotfvalconstr';

    % open figure
    % figure(5);
    % clf();

    [config, x, ~] = engine.otmin(config, opt);

    % save `config` in WS
    assignin('base', "config", config);

    %% rodando simulacao como resultado da trajetoria
    c = config;

    dT = x;
    c.Ts = engine.get_ts(dT);
    c.x0 = engine.get_x0(config);
    nsim = 50;

    % c.x0 = c.x0 + [4.5; 1.1; 3.1];
    % c.x0 = [0.0, 0.0, 0.0];
    % c.x0 = [19.2928,9.9247,0.9823];


    % config_.x0 = x0;
    % [y,t,u] = sim_1(config_);

    [y, t] = engine.sim_n(c, nsim);

    % renomeando variaveis

    % plot dos resultados
    % close all;

    f1 = figure(13);
    plotter.patino2.plot_xi(t, y);

    f2 = figure(4);
    [y,t,u,m,dtk_out] = engine.sim_n(c, 30);
    plotter.patino2.plot_traj(y, "Multilevel Converter: Trajectory", "X_1: Voltage C_1 [V]", "X_2: Voltage C_2 [V]", "X_3: Current L [A]")
    
    f3 = figure(5);
    i = t < c.Ts(end);
    plotter.patino2.plot_control_signal(t(i), m(i), "Multilevel Converter: Input Signal", "t - time(s)", "u - switch command");

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

    % defining output in case it is set by the caller
    vout = struct();
    vnames = who;
    for i = 1:numel(vnames)
        vi = vnames{i};
        vout.(vi) = eval(vi);
    end

end


