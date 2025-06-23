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
    
    dtk_prev  = zeros([numel(cfg.Omega)-1, 1]);

    for i = 1:nsim
        dtk = zeros([numel(cfg.Omega)-1, 1]);
        if mpc_on

            % ?? augmented
            if self.m_state_mode == Enums.StateMode.AUGMENTED
                Nd_counter = Nd_counter + 1;
                if Nd_counter < Nd 
                    dtk = dtk_prev; % keep repeating control until Nd
                    exitflag = 44; % flag that the value is not computed
                else
                    [dtk, exitflag] = self.run_mpc(cfg, x0, dtk_prev);
                    Nd_counter = 1;
                end
            else % Enums.StateMode.ORIGINAL
                [dtk, exitflag] = self.run_mpc(cfg, x0, dtk_prev);
            end

            time_qp = tic;

            % updating dtk_prev
            dtk_prev = dtk;

            % compute new time vector from dtk
            Ts = config.Ts;
            Ts = self.quantizacao(Ts, Enums.QuantType.Sim);
            
            for j = 1:numel(dtk)
                Ts(j+1) = Ts(j+1) + dtk(j);
            end

            bla_time_us = self.signal_process(x0, dtk_prev);
    
            % updating time on local config variable
            cfg.Ts = Ts;

            % logging DATA
            time_us = arrayfun(@round, diff(Ts*1e6));
            
            % add iteration
            if isempty(self.m_log.run.iter)
                self.m_log.run.iter = [self.m_log.run.iter; 1];
            else
                self.m_log.run.iter = [self.m_log.run.iter; self.m_log.run.iter(end)+1];
            end

            % log data
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
