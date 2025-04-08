% [y,t,u] = sim_n(config, Ts)
function [y,t,m,dtk_out] = run(self, nsim)

    % reading config
    config = self.config;

    % inicializacao variaveis de saida
    nmodes  = numel(config.Omega);
    nstates = numel(config.x0);

    dtk_out = [];

    y = zeros(nsim*nmodes, nstates); 
    t = zeros(nsim*nmodes, 1);
    m = zeros(nsim*nmodes, 1);
    
    cfg = config;

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
            % computing `ek`
            ek  = reshape(x0, [numelx0,1]) - reshape(cfg.mpc.x_target, [numelx0,1]);

            % computing control `dtk`
            [dtk, ~, exitflag] = Mpc.dualmode_switching(ek,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,cfg.mpc.PhiNp,cfg.mpc.p);

            % ignore control if problem is infeasible
            if exitflag == -2
                dtk = dtk*0;
            end

            % reading nominal time values
            Ts = config.Ts;
            
            % applying quantization on time signal
            Ts = self.quantizacao(Ts, Enums.QuantType.Sim);


            dtk_ = dtk*1e6;
            cts_us = Ts*1e6;
            dts    = diff(cts_us);
            % updating time vector with control command
            for j = 1:numel(dtk)
                Ts(j+1) = Ts(j+1) + dtk(j);
            end

            ts_us = Ts*1e6;
            bla = self.signal_process(x0);
            ble = 1;

            % compessating negative time values (when control is too much)
            % need to adjust control constraints!!!
            % dif = [ 0, diff(Ts) ];
            % idx = dif < 0;
            % while any(idx)
            %     Ts = Ts - dif.*idx;
            %     dif = [ 0, diff(Ts) ];
            %     idx = dif < 0;
            % end
    
            % updating time on local config variable
            cfg.Ts = Ts;
        end
        
        % running 1 simulation cycle
        [y_,t_,m_,~] = self.sim_cycle2(cfg);

        % saving states
        ii = (i-1)*nmodes + 1;
        y(ii:ii+nmodes-1,:) = y_(1:nmodes,:);
        t(ii:ii+nmodes-1)   = t_(1:nmodes) + t0;
        m(ii:ii+nmodes-1)   = m_(1:nmodes);

        % saving control signal
        dtk_out = [dtk_out, dtk];

        % updating values for next cycle
        cfg.x0 = y_(end,:)';
        t0  = t_(end) + t0;
        x0  = cfg.x0;

    end
end
