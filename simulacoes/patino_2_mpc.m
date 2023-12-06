function var_out = patino_2_mpc(save_fig)


    if (nargin == 0)
        save_fig = false;
    end

    %% 1 INIT
        % get configuration
        config = engine.get_config_sim_patino_2();
        config.tstep = 1e-7;

    %% 2 CALCULO DA TRAJETORIA
        % get custom options for the fmincon
        opt = engine.get_otmin_opt(config);
        opt.MaxFunctionEvaluations = 500*12;
        opt.Display = 'iter';
        opt.ConstraintTolerance = 1e-4;
        % opt.PlotFcn = 'optimplotfvalconstr';

        [config, x, fval] = engine.otmin(config, opt);


    %% 3 CONSTRUINDO MPC
        % montando valores de referencia
        tr  = config.Ts(2:end);
        ur  = [1, 0];
        dtr = diff(config.Ts);
        xr  = engine.get_xr(config);

        [Phi, Gamma] = mpc.construcao_modelo_instantes(config.A, config.b, tr, xr, config);

        A = config.A;
        b = config.b;
        xbar0 = xr(1,:)';
        Dt = diff(config.Ts);

        % [Phi_,Gamma_] = linModel(A,b,config.Omega,xbar0,Dt);
        % Gamma = [Gamma, Gamma_(:, end)];

        N  = numel(tr);

        p  = N - 1;
        Q  = diag([1,1,1]); % FIXME: colocar numel generico
        R  = eye(p);
        Np = 2; % numero de ciclos a frente

        % parametros das restricoes de chaveamento
        t_min = 20*1e-6;

        c = [
            -dtr(1) + t_min;
            -dtr(2) + t_min;
            -dtr(3) + t_min;
            -dtr(4) + t_min;
            -dtr(5) + t_min;
            -dtr(6) + t_min;
            -dtr(7) + t_min;
            -dtr(8) + t_min;
            -dtr(9) + t_min;
        ]; % dimensao: Nx1

        [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
            mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

        % criando estrutura com dados MPC
        mpc_opt          = struct();
        mpc_opt.on       = true;

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

        mpc_opt.options  = optimoptions('quadprog', 'Algorithm', 'active-set');
        config.mpc       = mpc_opt;


    %% 4 RUN PROGRAM
    %% rodando simulacao como resultado da trajetoria

        cfg = config;
        nsim = 50;

        % estados
        % 1. vc1
        % 2. vc2
        % 3. i

        % adicionando erros
        cfg.x0  = config.x0 + [-2;1;-1];

        cfg.mpc.on = true;
        [y,t,u,m,dtk_out] = engine.sim_n(cfg, nsim);

        cfg.mpc.on = false;
        [y_off,t_off,u_off,m_off,dtk_out_off] = engine.sim_n(cfg, nsim);
        
    %% 5 PLOTING GRAPHICS

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
        plot3(vc1, vc2, i_l, 'k');

        grid on;
        xlabel('V_{c1} [V]');
        ylabel('V_{c2} [V]');
        zlabel('i_L [A]');
        set(gca,'fontsize', 15);

        % plotando diferencas

        f5 = figure(5);
        stairs(t_off, m_off, 'linew', 2);
        hold on;
        stairs(t, m, 'linew', 2, 'linestyle', '--');
        hold off;
        xlim([0, 1.46e-3]);
        grid on;
        xlabel('time (s)');
        ylabel('mode');
        set(gca,'fontsize', 15);
        legend('modes target trajectory', 'modes simulation');


        % get values from the function
        all_variables = who;
        var_out = [];
        for i = 1:length(all_variables)
            var_name           = all_variables{i};
            var_out.(var_name) = eval(var_name);
        end

        %% saving figures
        if (save_fig)
            addr_out = "../LATEX_tese/Cap4/fig/";

            save_figure(f1, "graf_patino_ex2_1.pdf", addr_out);
            save_figure(f2, "graf_patino_ex2_2.pdf", addr_out);
            save_figure(f3, "graf_patino_ex2_3.pdf", addr_out);
            save_figure(f4, "graf_patino_ex2_4.pdf", addr_out);
            save_figure(f5, "graf_patino_ex2_5.pdf", addr_out);
        end


end