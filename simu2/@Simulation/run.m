% [y,t,u] = sim_n(config, Ts)
function [y,t,m,dtk_out] = run(self, nsim)

    % reading config
    config = self.m_config;

    % initializing output variables
    modes_len  = numel(config.Omega);
    states_len = numel(config.x0);

    y = zeros(nsim*modes_len, states_len); 
    t = zeros(nsim*modes_len, 1);
    m = zeros(nsim*modes_len, 1);
    
    dtk_len = modes_len - 1;
    dtk_out = zeros(dtk_len, nsim);

    cfg = config;

    t0  = 0.0;
    x0  = cfg.x0;
    
    mpc_on = false;
    if isfield(cfg, 'mpc')
        if cfg.mpc.on == 1
            mpc_on = true;
        end
    end
    
    % getting Nd from config
    Nd = self.m_mpc_config.Nd;
    Nd_counter = 1;
    
    dtk_prev = zeros([numel(cfg.Omega)-1, 1]);

    for i = 1:nsim
        dtk = zeros([numel(cfg.Omega)-1, 1]);
        if mpc_on
            % computing `ek`
            ek  = x0 - cfg.mpc.x_target;

            % computing augmented `ek_aug`
            ek_aug = [ek; dtk_prev];

            % computing control `dtk`
            tic;

            % ?? augmented
            if self.m_state_mode == Enums.StateMode.AUGMENTED
                Nd_counter = Nd_counter + 1;
                if Nd_counter < Nd 
                    dtk = dtk_prev; % keep repeating control until Nd
                    exitflag = 44; % flag that the value is not computed
                else
                    [dtk, ~, exitflag] = Mpc.dualmode_switching(ek_aug,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,...
                    cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,...
                    cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,...
                    cfg.mpc.PhiNp,cfg.mpc.p);
                    Nd_counter = 1;
                end
            else % Enums.StateMode.ORIGINAL
                [dtk, ~, exitflag] = Mpc.dualmode_switching(ek,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,...
                                                            cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,...
                                                            cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,...
                                                            cfg.mpc.PhiNp,cfg.mpc.p);
            end

            time_qp = tic;

            % updating dtk_prev
            dtk_prev = dtk;

            % ignore control if problem not possible
            %  exitflag:
            %    1: function converged to the solution x
            %    0: number of iterations exceeded MaxIterations
            %   -2: problem is infeasible
            %   -3: problem is unbounded
            %   44: using previous dtk to emulate the time to respond from esp32
            if exitflag ~= 1 && exitflag ~= 44
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
            % bla = self.signal_process(x0);
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


            % LOGGING DATA
            time_us = arrayfun(@round, diff(Ts*1e6));
            
            % add iteration
            if isempty(self.m_log.run.iter)
                self.m_log.run.iter = [self.m_log.run.iter; 1];
            else
                self.m_log.run.iter = [self.m_log.run.iter; self.m_log.run.iter(end)+1];
            end

            % log rest of data
            self.m_log.run.exitflag = [self.m_log.run.exitflag; exitflag];
            self.m_log.run.time_us = [self.m_log.run.time_us; time_us];
            self.m_log.run.x0 = [self.m_log.run.x0; x0'];
            self.m_log.run.x_target = [self.m_log.run.x_target; cfg.mpc.x_target'];

            self.m_log.run.time_qp = [self.m_log.run.time_qp; time_qp];
            self.m_log.run.time_qp = [self.m_log.run.time_qp; time_qp];

            self.m_log.run.dtk = [self.m_log.run.dtk; dtk'];
            self.m_log.run.dtk_prev = [self.m_log.run.dtk_prev; dtk_prev'];

        end
        
        % running 1 simulation cycle
        [y_,t_,m_,~] = self.sim_cycle2(cfg);

        % saving states
        ii = (i-1)*modes_len + 1;
        y(ii:ii+modes_len-1,:) = y_(1:modes_len,:);
        t(ii:ii+modes_len-1)   = t_(1:modes_len) + t0;
        m(ii:ii+modes_len-1)   = m_(1:modes_len);

        % saving control signal
        dtk_out(:,i) = dtk(:);

        % updating values for next cycle
        t0  = t_(end) + t0;
        cfg.x0 = y_(end,:)';
        x0  = cfg.x0;
    end
end
