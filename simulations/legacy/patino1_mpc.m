
function res = patino1_mpc(save_fig)

    if (nargin == 0)
        save_fig = false;
    end

    % get configuration
    config = engine.get_config_sim_patino_1();

    %% calculo da trajetoria
    [config, x, fval] = engine.otmin(config);

    %% construindo MPC
    % montando valores de referencia
    tr  = config.Ts(2:end);
    ur  = [1, 0];
    dtr = diff(config.Ts);
    xr  = engine.get_xr(config);

    [Phi, Gamma] = mpc.construcao_modelo_instantes(config.A, config.b, tr, xr, config);

    N  = numel(tr);
    p  = N - 1;
    Q  = diag([10,1]); % por que 10???
    R  = eye(p);
    Np = 2;

    % parametros das restricoes de chaveamento
    t_on  = 0.25;
    t_off = 0.25;

    c = [
        -dtr(1) + t_on;
        -dtr(2) + t_off;
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

    %% rodando simulacao com o resultado da trajetoria
    cfg     = config;
    cfg.mpc = mpc_opt;
    cfg.x0  = config.x0 + [0.2; 0.5];
    nsim    = 40;

    % simulacao com controle mpc
    [y,t,u,m,dtk_out] = engine.sim_n(cfg, nsim);

    % simulacao sem controle mpc
    cfg.mpc.on = 0;
    [y_off,t_off,u_off,m_off] = engine.sim_n(cfg, nsim);

    % get values from the function
    var_out = utils.getAllVars();
    res = resultados.ResPatino1_mpc(var_out);

    % plot dos resultados
    f1 = figure(1);
    res.plot_traj();

    f2 = figure(2);
    res.plot_u_signal();
    
    res.data.f1 = f1;
    res.data.f2 = f2;

    if (save_fig)
        %% save figures
        % save_figure(f1, "graf_patino_ex1_1.pdf", "../LATEX_tese/Cap4/fig/");
        % save_figure(f2, "graf_patino_ex1_2.pdf", "../LATEX_tese/Cap4/fig/");
        save_figure(f1, "graf_patino1_traj.pdf", "../LATEX_tese/Cap4/fig/");
        save_figure(f2, "graf_patino1_u_signal.pdf", "../LATEX_tese/Cap4/fig/");
    end

end
