function z_play()
    % creating `sim` object
    sim = Simulacao();

    % .. init
    sim.load(enums.SimName.INTEGRADOR_DUPLO);

    % .. trajetoria
    
    % .. mpc
    tr  = sim.config.Ts(2:end);
    xr  = sim.get_xr();
    [Phi, Gamma] = mpc.construcao_modelo_instantes(sim.config.A, sim.config.b, tr, xr, sim.config);
    
    % FIXME: check if this `N` is really like this
    N = numel(tr);
    p = N - 1;
    Q = diag([10,1]);
    R = eye(p);
    Np = 2;
    
    % parametros das restricoes de chaveamento
    t_on = 1.625;
    t_off = 0.635;
    
    dtr = diff(sim.config.Ts);
    c = [
        -dtr(1) + t_on;
        -dtr(2) + t_off;
        -dtr(3) + t_on;
        -dtr(4) + t_off;
    ];

    [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,L] = ...
        mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

    % criando estructura com dados MPC
    mpc_opt          = struct();
    mpc_opt.on       = 1;

    mpc_opt.x_target = sim.config.x0;
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
    
    sim.mpc = mpc_opt;
    
    % .. simulacao
    config = sim.config;
    
    sim.config.x0 = config.x0 + [2; 0.5];
    nsim = 40;

    % simulacao com controle mpc
    [y,t,u,m,dtk_out] = sim.sim_n(nsim);
    
    % simulacao sem controle mpc
    sim.mpc.on = false;
    [y_off,t_off,u_off,m_off] = sim.sim_n(nsim);

    bla = 1;
end