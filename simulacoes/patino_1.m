function var_out = patino_1(save_fig)
    
    if (nargin == 0)
        save_fig = false;
    end

    % get configuration
    config = engine.get_config_sim_patino_1();

    %% calculo da trajetoria
    [config, x, fval] = engine.otmin(config);
    % disp(x);
    % disp(fval);

    %% rodando simulacao como resultado da trajetoria
    c = config;

    c.x0 = c.x0;
    nsim = 30;
    [y,t,u,m] = engine.sim_n(c, nsim);

    %% plot dos resultados

    % grafico 1
    f1 = figure(1);
    plot_trajetory(y, c.xref, "Buck-Boost Converter: Cyclic Trajectory", "x_1 - Voltage Capacitor C", "x_2 - Current Inductor L");

    % grafico 2
    f2 = figure(2);

    i = t < c.Ts(end);
    plot_control_signal(t(i), m(i), "Buck-Boost Converter Signal Command", "t - time (s)", "u - switch command");


    % get variables
    all_vars = who;
    var_out = [];
    for i = 1:length(all_vars)
        var_name = all_vars{i};
        var_out.(var_name) = eval(var_name);
    end

    if (save_fig)
        %% saving figures
        save_figure(f1, "graf_patino1_traj.pdf", "../LATEX_tese/Cap2/fig/");
        save_figure(f2, "graf_patino1_u_signal.pdf", "../LATEX_tese/Cap2/fig/");
    end

        %% copy figures
        % copyfile('graf_ex1_*.pdf', "../../LATEX_tese/Cap2/fig/");
    
end

function plot_trajetory(y, xref, tit, x_label, y_label)
    hold off;
    plot(y(:,1), y(:,2), 'LineWidth', 2); hold on;
    plot(xref(1), xref(2), 'rx');

    axis equal;
    grid on;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
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