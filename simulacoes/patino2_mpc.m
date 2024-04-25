function res = patino2_mpc(save_fig, nsim_in)

    if (nargin == 0)
        save_fig = false;
    end
    
    nsim = 100;
    if (nargin >= 1)
        nsim = nsim_in;
    end

    %% 1 INIT
        % get configuration
        config = engine.get_config_sim_patino_2();

    %% 2 CALCULO DA TRAJETORIA
        % get custom options for the fmincon
        opt = engine.get_otmin_opt(config);
        opt.MaxFunctionEvaluations = 500*12;
        opt.Display = 'iter';
        opt.ConstraintTolerance = 1e-4;
        % opt.PlotFcn = 'optimplotfvalconstr';

        config.quant_traj = 0.022e-3;
        config.quant_sim = 0.022e-3;
        [config, ~, ~] = engine.otmin(config, opt);
        
        % truncando valor da trajetoria
        resolution = 1e8;
        Ts = config.Ts;
        for i = 1:length(Ts)
            Ts(i) = fix(Ts(i)*resolution)/resolution;
        end
        config.Ts = Ts;
        
        % calculando x0 para a trajetoria truncada
        config.x0 = engine.get_x0(config);


    %% 3 CONSTRUINDO MPC
        % montando valores de referencia
        % tr  = config.Ts(2:end);
        % dtr = diff(config.Ts);
        % xr  = engine.get_xr(config);

        Ts  = config.Ts;
        tr  = Ts(2:end);
        dtr = diff(Ts);
        xr  = engine.get_xr(config);

        [Phi, Gamma] = mpc.construcao_modelo_instantes(config.A, config.b, tr, xr, config);

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

        [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,~] = ...
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
        % nsim = 500;

        % estados
        % 1. vc1
        % 2. vc2
        % 3. i

        % adicionando erros
        % cfg.x0  = config.x0 + [-2;1;-1];
        % cfg.x0  = config.x0 + [-0.1; .1; -.1];
        % cfg.x0 = [0; 10; 10];

        % cfg.x0  = config.x0 + [-2;1;-1];
        cfg.mpc.on = true;
        [y,t,m,dtk_out] = engine.sim_n2(cfg, nsim);
        x0_1 = cfg.x0;

        cfg.mpc.on = false;
        cfg.x0  = config.x0 + [-1.2; -1.3; -.9];
        [y_off,t_off,m_off,dtk_out_off] = engine.sim_n2(cfg, nsim);

        % cfg.x0  = config.x0 + [-0.2; -.3; -.3];
        % cfg.mpc.on = true;
        % y2 = engine.sim_n2(cfg, nsim);

        % cfg.mpc.on = false;
        % y2_off = engine.sim_n2(cfg, nsim);
        
        cfg.mpc.on = true;
        [y_quant,t_quant,m_quant,dtk_out_quant] = engine.sim_n2(cfg, nsim);
        
        % x0_2 = cfg.x0;
    %% 5 PLOTING GRAPHICS

        % get values from the function
        var_out = utils.getAllVars();
        res = resultados.ResPatino2_mpc(var_out);
        res.plot();
        
        % f1 = figure(1);
        % res.plot_xi();

        % f2 = figure(2);
        % res.plot_traj();

        % f2_1 = figure(3);
        % res.plot_traj2();

        % f3 = figure(4);
        % res.plot_u_signal();
        
        % res.data.f1 = f1;
        % res.data.f2 = f2;
        % res.data.f2_1 = f2_1;
        % res.data.f3 = f3;

        %% saving figures
        if (save_fig)
            addr_out = "../LATEX_tese/Cap4/fig/";

            config.fig_width = 8;
            config.fig_height = 10;

            % states
                save_figure(f1, "graf_patino2_xi.pdf", addr_out, config);
            % trajectory
                save_figure(f2, "graf_patino2_traj.pdf", addr_out);
            % trajectory 2
                save_figure(f2_1, "graf_patino2_traj_2.pdf", addr_out);
            % control signal
                save_figure(f3, "graf_patino2_u_signal.pdf", addr_out);

        end
end
