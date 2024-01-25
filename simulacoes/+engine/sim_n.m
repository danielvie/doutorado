% [y,t,u] = sim_n(config, Ts)
function [y,t,u,m,dtk_out] = sim_n(config, nsim)
    
    cfg = config;
    y   = []; t   = [];
    u   = [];
    m   = [];
    dtk_out = [];
    t0  = 0.0;
    x0  = cfg.x0;
    
    mpc_on = false;
    if isfield(cfg, 'mpc')
        if cfg.mpc.on == 1
            mpc_on = true;
        end
    end
    
    numelx0 = numel(x0);
    for i = 1:nsim
        dtk = zeros([numel(cfg.Omega)-1, 1]);
        if mpc_on
            % calculo `ek`
            ek  = reshape(x0, [numelx0,1]) - reshape(cfg.mpc.x_target, [numelx0,1]);

            % calculo comando `dtk`
            [dtk, fval, exitflag] = mpc.mpc_dualmode_switching(ek,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,cfg.mpc.PhiNp,cfg.mpc.p);


            % if (exitflag == -2)
            %     dtk = dtk*0.0;
            % end


            % aplicando diferenca de tempo calculada pelo controle em cima
            % da trajetoria de referencia.
            % nota: o tempo eh ajustado a partir de `j+1` porque o primeiro
            % instante eh `0`.
            Ts = config.Ts;
            for j = 1:numel(dtk)
                Ts(j+1) = Ts(j+1) + dtk(j);
            end
    
            cfg.Ts = Ts;
        end
        
        % simulando dinamica
        [y_,t_,u_,m_] = engine.sim_cycle(cfg);
        cfg.x0 = y_(end,:)';

        y   = [y;y_];
        t   = [t;t_ + t0];
        u   = [u;u_];
        m   = [m;m_];
        
        dtk_out = [dtk_out, dtk];

        t0  = t(end);
        x0  = cfg.x0;
    end
end