
function cfg_out = patino_2(savefig)
    if (nargin == 0)
        savefig = false;
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
    vc1 = y(:,1);
    vc2 = y(:,2);
    i_l = y(:,3);


    % plot dos resultados
    close all;

    f1 = figure(1);
    plot(t, vc1);

    grid on;
    xlabel('t - time(s)');
    ylabel('V_{c1} [V]');
    set(gca,'fontsize', 15);


    f2 = figure(2);
    plot(t, vc2);

    grid on;
    xlabel('t - time(s)');
    ylabel('V_{c2} [V]');
    set(gca,'fontsize', 15);

    f3 = figure(3);
    plot(t, i_l);

    grid on;
    xlabel('t - time(s)');
    ylabel('i_L [A]');
    set(gca,'fontsize', 15);

    f4 = figure(4);
    y = engine.sim_n(c, 30);

    vc1_ = y(:,1);
    vc2_ = y(:,2);
    i_l_ = y(:,3);

    y1 = engine.sim_1_custo(c);

    assignin('base', 'y1', y1);

    % plot3(y1(:,1), y1(:,2), y1(:,3), 'k');
    plot3(vc1_, vc2_, i_l_, 'k');

    grid on;
    xlabel('V_{c1} [V]');
    ylabel('V_{c2} [V]');
    zlabel('i_L [A]');
    set(gca,'fontsize', 15);

    if (savefig)
        fprintf("salvando figuras\n\n");

        %% saving figures
        save_figure(f1, "graf_ex2_1.pdf");
        save_figure(f2, "graf_ex2_2.pdf");
        save_figure(f3, "graf_ex2_3.pdf");
        save_figure(f4, "graf_ex2_4.pdf");

        %% copy figures to latex
        % copyfile('graf_ex2_*.pdf', "../../LATEX_tese/Cap2/fig/");
    end

    % defining output in case it is set by the caller
    if (nargout == 1)
        cfg_out = config;
    end
