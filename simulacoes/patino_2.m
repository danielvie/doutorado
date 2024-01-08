
function cfg_out = patino_2(save_fig)
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
    plot_xi(t, y);

    f2 = figure(4);
    [y,t,u,m,dtk_out] = engine.sim_n(c, 30);
    plot_trajectory(y, "Multilevel Converter: Trajectory", "X_1: Tension C_1 [V]", "X_2: Tension C_2 [V]", "X_3: Current L [A]")
    
    f3 = figure(5);
    i = t < c.Ts(end);
    plot_control_signal(t(i), m(i), "Multilevel Conveter: Input Signal", "t - time(s)", "u - switch command");

    if (save_fig)
        fprintf("salvando figuras\n\n");

        addr = "../LATEX_tese/Cap2/fig/";
        % saving figures

        config.fig_width = 8;
        config.fig_height = 10;
        save_figure(f1, "graf_ex2_xi.pdf", addr, config);

        save_figure(f2, "graf_ex2_traj.pdf", addr);
        save_figure(f3, "graf_ex2_u_signal.pdf", addr);

        %% copy figures to latex
        % copyfile('graf_ex2_*.pdf', "../../LATEX_tese/Cap2/fig/");
    end

    % defining output in case it is set by the caller
    if (nargout == 1)
        cfg_out = config;
    end
end

function plot_xi(t, y) 
    vc1 = y(:,1);
    vc2 = y(:,2);
    i_l = y(:,3);

    subplot(3, 1, 1);
    plot_xi_helper(t, vc1, "Multilevel Converter: X_1", "t - time(s)", "Tension C_1 [V]");

    subplot(3, 1, 2);
    plot_xi_helper(t, vc2, "Multilevel Converter: X_2", "t - time(s)", "Tension C_2 [V]");

    subplot(3, 1, 3);
    plot_xi_helper(t, i_l, "Multilevel Converter: X_3", "t - time(s)", "Tension L [A]");
end

function plot_xi_helper(t, x, tit, x_la, y_la)
    plot(t, x);

    grid on;
    title(tit);
    xlabel(x_la);
    ylabel(y_la);

    set(gca,'fontsize', 15);
end

function plot_trajectory(y, tit, x_la, y_la, z_la)

    vc1_ = y(:,1);
    vc2_ = y(:,2);
    i_l_ = y(:,3);

    plot3(vc1_, vc2_, i_l_, 'k');

    grid on;

    title(tit);
    xlabel(x_la);
    ylabel(y_la);
    zlabel(z_la);

    set(gca,'fontsize', 15);
end

function plot_control_signal(t, m, tit, x_label, y_label)

    hold off;

    f = stairs(t, m, 'linew', 3); 

    hold on;
    grid on;
    title(tit)
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);

    % removing the values that are not integers in Y axis
    v = f.Parent.YTick;
    
    % indices for integer
    p = abs(v - floor(v)) < 0.1;
    
    % update yticks
    f.Parent.YTick = v(p);
    
    xlim([t(1), t(end)]);
end