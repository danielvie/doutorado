% [y,t,u] = sim_n(config, Ts)
function [y,t,u,m] = sim_n(config, nsim)
    
    config_ = config;
    y   = [];
    t   = [];
    u   = [];
    m   = [];
    t0  = 0.0;
    x0  = config_.x0;
    for i = 1:nsim
        if isfield(config_, 'mpc')
            % calculo `ek`
            ek  = reshape(x0, [2,1]) - reshape(config_.mpc.x_target, [2,1]);

            % calculo comando `dtk`
            dtk = mpc.mpc_dualmode_switching(ek,config_.mpc.H,config_.mpc.Hf,config_.mpc.Phi1Np,config_.mpc.Qbar,config_.mpc.Rbar,config_.mpc.Lbar,config_.mpc.cbar,config_.mpc.Pf,config_.mpc.Sf,config_.mpc.bf,config_.mpc.PhiNp,config_.mpc.p);

            % aplicando diferenca de tempo calculada pelo controle
            tr = config_.Ts(2:end);
            for j = 1:numel(dtk)
                tr(j) = tr(j) + dtk(j);
            end

            if config_.mpc.on == 1
                config_.Ts = [0, tr];
            end
        end
        
        % simulando dinamica
        [y_,t_,u_,m_] = patino.sim_1(config_);
        config_.x0 = y_(end,:)';

        y   = [y;y_];
        t   = [t;t_ + t0];
        u   = [u;u_];
        m   = [m;m_];
        
        t0  = t(end);
        x0  = config_.x0;
    end
end