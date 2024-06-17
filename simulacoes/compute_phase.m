function cfg = compute_phase(config, iref)

    config.iref = iref;

    %% CALCULO DA TRAJETORIA
        %% rodando simulacao como resultado da trajetoria
        param = struct();

        param.E = 30;
        param.C(1) = 40e-6;
        param.C(2) = 40e-6;
        param.L = 10*1e-3;
        param.R = 10;

        param.iMax = param.E/param.R; 
        param.iLref = config.iref;
        param.alpha = param.iLref / param.iMax; % Duty cycle

        param.n = 3; % Number of switching cells
        param.T = 0.28*1e-3;

        [Omega,dT] = phase_shift.industrial_solution(param.alpha,param.n,param.T);
        % [A,b] = phase_shift.modelSwitchedCapacitor(param.n,param.R,param.L,param.C,param.E);
        
        config.Omega = Omega;

        cfg = config;
        cfg.Ts = engine.get_ts(dT);
        cfg.x0 = engine.get_x0(cfg);

        % save `config` in WS
        assignin('base', "config", config);
        assignin('base', "cfg", cfg);


    %% CONTRUINDO MPC

        Ts  = cfg.Ts;
        tr  = Ts(2:end);
        dtr = diff(Ts);
        xr  = engine.get_xr(cfg);

        [Phi, Gamma] = mpc.construcao_modelo_instantes(config.A, config.b, tr, xr, cfg);

        N  = numel(Omega);

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

end
