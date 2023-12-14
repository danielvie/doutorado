
function var_out = integrador_duplo(save_fig)

    if (nargin == 0)
        save_fig = false;
    end

    %% 1 INIT
        % get configuration
        config = engine.get_config_sim_intduplo();

    %% 2 TRAJETORIA
        % [config, x, fval] = engine.otmin(config);
        %% construindo MPC
        % montando valores de referencia

    %% 4 CONSTRUINDO MPC
        tr  = config.Ts(2:end);
        % ur  = [1, 0];
        dtr = diff(config.Ts);
        xr  = engine.get_xr(config);

        [Phi, Gamma] = mpc.construcao_modelo_instantes(config.A, config.b, tr, xr, config);

        N  = numel(tr);
        p  = N - 1;
        Q  = diag([10,1]); % por que 10???
        R  = eye(p);
        Np = 2;

        % parametros das restricoes de chaveamento
        t_on  = 1.625;
        t_off = 0.635;

        c = [
            -dtr(1) + t_on;
            -dtr(2) + t_off;
            -dtr(3) + t_on;
            -dtr(4) + t_off;
        ];

        [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
            mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

        % criando estrutura com dados MPC
        mpc_opt          = struct();
        mpc_opt.on       = 1;

        mpc_opt.x_target = config.x0;
        mpc_opt.H        = H;
        mpc_opt.Hf       = Hf;
        mpc_opt.Phi1Np   = Phi1Np;
        mpc_opt.Qbar     = Qbar;
        mpc_opt.Rbar     = Rbar;
        mpc_opt.Lbar     = Lbar;
        mpc_opt.cbar     = cbar;
        mpc_opt.Pf       = Pf;
        mpc_opt.Sf       = Sf;
        mpc_opt.bf       = bf;
        mpc_opt.PhiNp    = PhiNp;
        mpc_opt.p        = p;

    %% RODANDO SIMULACAO COM O RESULTADO DA TRAJETORIA
        cfg     = config;
        cfg.mpc = mpc_opt;
        cfg.x0  = config.x0 + [2; 0.5];
        nsim    = 40;

        % simulacao com controle mpc
        [y,t,u,m,dtk_out] = engine.sim_n(cfg, nsim);

        % simulacao sem controle mpc
        cfg.mpc.on = 0;
        [y_off,t_off,u_off,m_off] = engine.sim_n(cfg, nsim);


    % PLOT DOS RESULTADOS
        ncycle = size(y_off, 1) / nsim;

        f1 = figure(1);
        plot_traj(y_off(1:ncycle*5,:), config.x0, "double integrator MPC off", "v_c", "i_L");

        f2 = figure(2);
        plot_traj(y, config.x0, "double integrator MPC on", "v_c", "i_L");

        f3 = figure(3);
        
        ncycle = ncycle * 8 + 1;
        plot_control_signal(t_off(1:ncycle), m_off(1:ncycle), t(1:ncycle), m(1:ncycle), "double integrator Control Signal", "time (s)", "mode");

        % get values from the function
        all_variables = who;
        var_out = [];
        for i = 1:length(all_variables)
            var_name           = all_variables{i};
            var_out.(var_name) = eval(var_name);
        end

        if (save_fig)
            %% save figures
            save_figure(f1, "graf_ex1_1.pdf", "../LATEX_tese/Cap4/fig/");
            save_figure(f2, "graf_ex1_2.pdf", "../LATEX_tese/Cap4/fig/");

            save_figure(f3, "graf_ex1_3.pdf", "../LATEX_tese/Cap4/fig/");
        end
end

function plot_traj(y, x0, tit, x_label, y_label)
    plot(y(:,1), y(:,2), 'linew', 1.2);
    hold on;

    % plot marcadores
    plot(y(1,1), y(1,2), 'ro', 'markers', 10, 'linew', 1.2);
    plot(y(end,1), y(end,2), 'k.', 'markers', 30);
    plot(x0(1), x0(2), 'rx', 'linew', 2, 'markers', 16);

    legend('trajectory', 'start', 'end', 'target x_0', 'location', 'southeast');

    hold off;
    grid on;
    axis equal;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);
end

function plot_control_signal(t_off, m_off, t, m, tit, x_label, y_label)
    f = stairs(t_off, m_off, 'linew', 2);
    hold on;
    stairs(t, m, 'linew', 2, 'linestyle', '--');
    hold off;
    
    grid on;
    title(tit);
    xlabel(x_label);
    ylabel(y_label);
    set(gca,'fontsize', 15);
    legend('modes target trajectory', 'modes simulation');

    % removing the values that are not integers in Y axis
    v = f.Parent.YTick;
    
    % indices for integer
    p = abs(v - floor(v)) < 0.1;
    
    % update yticks
    f.Parent.YTick = v(p);

end