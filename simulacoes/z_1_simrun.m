function z_1_simrun() 
    % get data
    config = engine.get_config_sim_patino_2();




    % compute trajectory based on `iref`
    config.iref = 0.8;


    % {cfg = compute_phase(config, iref);}
    % ========================================================================

    % PARAM hier
    params = struct();

    % params.E = 30;
    % params.C(1) = 40e-6;
    % params.C(2) = 40e-6;
    % params.L = 10*1e-3;
    % params.R = 10;

    % params.iMax = params.E/params.R; 
    % params.iLref = config.iref;
    % params.alpha = params.iLref / params.iMax; % Duty cycle

    % params.n = 3; % Number of switching cells
    % params.T = 0.28*1e-3;



    % set system parameters
    params.E = 5;
    params.C(1) = 470e-6;
    params.C(2) = 470e-6;
    params.L = 100*1e-3;
    params.R = 22;

    params.iMax = params.E/params.R; 
    params.iLref = config.iref;
    params.alpha = params.iLref / params.iMax; % Duty cycle

    imax = params.iMax;
    assignin('base', 'imax', imax);
    fprintf("imax: %f\n", params.iMax);

    params.n = 3; % number of switch cells
    params.T = 0.28*1e-3; % period of cycle


    config = compute_dynamics(config, params);



    [Omega, dT] = compute_trajetory(params);

    config.Omega = Omega;

    cfg = config;
    cfg.Ts = engine.get_ts(dT);
    cfg.x0 = engine.get_x0(cfg);

    % contruindo mpc
    cfg = compute_mpc(cfg);


    % add pertubation on initial condition
    cfg.x0 = cfg.x0 + [2.5; -2.3; 1.1];
    
    % run simulation
    nsim = 40;
    cfg.mpc.on = true;
    [y, t, m] = engine.sim_n2(cfg, nsim);

    % save results
    vout = utils.getAllVars();
    assignin('base', 'vout', vout);
    
    % plot `y`
    subplot(3,1,1);
    plot(t, y(:,1))
    subplot(3,1,2);
    plot(t, y(:,2))
    subplot(3,1,3);
    plot(t, y(:,3))

end

function [Omega, dT] = compute_trajetory(params)
    [Omega, dT] = phase_shift.industrial_solution(params.alpha,params.n,params.T);

    % removendo elementos com dT muito pequeno (< 1e-16)
    EPS = 1e-16;
    I = [];
    for i = 1:numel(dT)
        if dT(i) >= EPS
            I = [I;i];
        end
    end

    Omega = Omega(I);
    dT = dT(I);
end

function [cfg_out] = compute_mpc(cfg)
    Ts  = cfg.Ts;
    tr  = Ts(2:end);
    dtr = diff(Ts);
    xr  = engine.get_xr(cfg);

    [Phi, Gamma] = mpc.construcao_modelo_instantes(cfg.A, cfg.b, tr, xr, cfg);

    N  = numel(cfg.Omega);

    p  = N - 1;
    Q  = diag([1,1,1]); % FIXME: colocar numel generico
    R  = eye(p);
    Np = 2; % numero de ciclos a frente

    % parametros das restricoes de chaveamento
    t_min = 20*1e-6;

    c = zeros(N, 1);
    for i= 1:N
        c(i) = -dtr(i) + t_min;
    end

    % c = [
    %     -dtr(1) + t_min;
    %     -dtr(2) + t_min;
    %     -dtr(3) + t_min;
    %     -dtr(4) + t_min;
    %     -dtr(5) + t_min;
    %     -dtr(6) + t_min;
    %     -dtr(7) + t_min;
    %     -dtr(8) + t_min;
    %     -dtr(9) + t_min;
    % ]; % dimensao: Nx1

    [H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,~] = ...
        mpc.matrizes_ss_mpc_dualmode_switching(Phi,Gamma,Q,R,Np,c);

    % criando estrutura com dados MPC
    mpc_opt          = struct();
    mpc_opt.on       = true;

    mpc_opt.x_target = cfg.x0;
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
    cfg.mpc          = mpc_opt;
    
    cfg_out = cfg;
end

function [cfg_out] = compute_dynamics(cfg, params)


	% dynamics of the system (Buck-Boost converter)
	R  = params.R;
	L  = params.L;
	C1 = params.C(1);
	C2 = params.C(2);
	E  = params.E;

    % construcao das matrizes dinamica
    A = cell(1,8);
    b = cell(1,8);
    
    for i = 1:8
        ibin = dec2bin(i-1, 3);

        u1 = str2double(ibin(1));
        u2 = str2double(ibin(2));
        u3 = str2double(ibin(3));
    
        A{i} = [         0,         0, (u2-u1)/C1
                         0,         0, (u3-u2)/C2
                 (u1-u2)/L, (u2-u3)/L,       -R/L];

        b{i} = [0;0;E/L*u3];
    end
		
	C = eye(3);
	D = [0;0;0];

	cfg.A     = A;
	cfg.b     = b;
	cfg.C     = C;
	cfg.D     = D;
    
    cfg_out = cfg;
end