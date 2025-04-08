% [y,t,u] = sim_n(config, Ts)
function time_us = signal_process(self, state)

    % reading config
    config = self.config;
    
    % reading state
    vc1 = state(1);
    vc2 = state(2);
    i_l = state(3);

    % inicializacao variaveis de saida
    cfg = config;
    x0  = [vc1; vc2; i_l];
    
    mpc_on = false;
    if isfield(cfg, 'mpc')
        if true == cfg.mpc.on
            mpc_on = true;
        end
    end
    
    if false == mpc_on
        return
    end

    % computing `ek`
    ek  = x0 - cfg.mpc.x_target;

    % computing control `dtk`
    [dtk, ~, ~] = Mpc.dualmode_switching(ek,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,cfg.mpc.PhiNp,cfg.mpc.p);

    % reading nominal time values
    Ts = config.Ts;
    
    % applying quantization on time signal
    % Ts = self.quantizacao(Ts, Enums.QuantType.Sim);

    % updating time vector with control command
    for j = 1:numel(dtk)
        Ts(j+1) = Ts(j+1) + dtk(j);
    end


    time_us = arrayfun(@round, diff(Ts*1e6));
end
