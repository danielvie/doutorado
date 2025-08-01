function [y,t,m,dtk_out] = run(self, nsim)

    % initializing output variables
    modes_len  = numel(self.m_config.Omega);
    states_len = numel(self.m_config.x0);

    y = zeros(nsim*modes_len, states_len); 
    t = zeros(nsim*modes_len, 1);
    m = zeros(nsim*modes_len, 1);
    
    dtk_len = modes_len - 1;
    dtk_out = zeros(dtk_len, nsim);

    config = self.m_config;

    t0  = 0.0;
    x0  = config.x0;
    
    mpc_on = false;
    if isfield(config, 'mpc')
        if config.mpc.on == 1
            mpc_on = true;
        end
    end
    
    % getting Nd from config
    Nd = self.m_mpc_config.Nd;
    Nd_counter = 1;
    
    dtk_prev  = zeros([numel(config.Omega)-1, 1]);

    cont = 0;
    skip = 100;

    for i = 1:nsim
        dtk = zeros([numel(config.Omega)-1, 1]);
        if mpc_on
            % ?? augmented
            if self.m_state_mode == Enums.StateMode.AUGMENTED
                Nd_counter = Nd_counter + 1;
                if Nd_counter < Nd 
                    dtk = dtk_prev; % keep repeating control until Nd
                    exitflag = 44; % flag that the value is not computed
                else
                    % [dtk, exitflag] = self.run_mpc(config, x0, dtk_prev);
                    % NOTE: computing dtk with proportinal
                    ek  = x0 - config.mpc.x_target;
                    k = self.m_config.mpc.K;
                    dtk = -k*ek;
                    exitflag = 1;

                    Nd_counter = 1;
                end
            else % Enums.StateMode.ORIGINAL
                % [dtk, exitflag] = self.run_mpc(config, x0, dtk_prev);
                % NOTE: computing dtk with proportinal
                ek  = x0 - config.mpc.x_target;
                k = self.m_config.mpc.K;
                dtk = -k*ek;
                exitflag = 1;
            end

            time_qp = tic;

            % updating dtk_prev
            dtk_prev = dtk;
            
            % constrainting `dtk`
            time_us = self.get_time_us();
            dtk_us = dtk*1e6;
            dtk_us(1) = max(time_us(2)-time_us(1) + dtk_us(1),5);
            dtk_us(2) = max(time_us(3)-time_us(2) + dtk_us(1)+dtk_us(2),5);
            dtk_us(3) = max(time_us(4)-time_us(3) + dtk_us(1)+dtk_us(2)+dtk_us(3),5);
            dtk_us(4) = max(time_us(5)-time_us(4) + dtk_us(1)+dtk_us(2)+dtk_us(3)+dtk_us(4),5);
            dtk_us(5) = max(time_us(6)-time_us(5) + dtk_us(1)+dtk_us(2)+dtk_us(3)+dtk_us(4)+dtk_us(5),5);
            
            Ts = self.compute_ts_from_dtk(self.m_config, dtk_us*1e-6);

            % 
            % c = self.m_config.c_time(1);
            % 
            % while any(diff(Ts) < 0)
            %     dts = max(diff(Ts), c);
            %     dts_ = dts - diff(Ts);
            %     for j = 1:numel(dts_)
            %         Ts(j+1) = Ts(j+1) + dts_(j);
            %     end
            % 
            %     % conditioning time to factible values
            %     Ts_final = self.m_config.Ts(end);
            %     if sum(Ts) > Ts_final
            %         Ts = Ts/norm(Ts)*Ts_final;
            %     end
            % end

            ts_us = Ts*1e6;
            d_ts_us = diff(ts_us);
            if any(d_ts_us < 0)
                error("ASSERT :: time cannot be negative!");
            end
            
            % % getting correct dtk for resulting Ts
            % Ts_nom = self.m_config.Ts;
            % dTs = (Ts - Ts_nom)';
            % dtk = dTs(2:end-1);


            % 
            % 
            % cont = cont + 1;
            % if rem(cont, skip) == 0
            %     bla = 1;
            % end


            bla_time_us = self.signal_process(x0, dtk_prev);
    
            % updating time on local config variable
            config.Ts = Ts;

            % logging DATA
            time_us = arrayfun(@round, diff(Ts*1e6));
            
            % add iteration
            if isempty(self.m_log.run.iter)
                self.m_log.run.iter = [self.m_log.run.iter; 1];
            else
                self.m_log.run.iter = [self.m_log.run.iter; self.m_log.run.iter(end)+1];
            end

            % compute `ek`
            ek  = x0 - config.mpc.x_target;

            % log data
            self.m_log.run.exitflag = [self.m_log.run.exitflag; exitflag];
            self.m_log.run.time_us = [self.m_log.run.time_us; time_us];
            self.m_log.run.x0 = [self.m_log.run.x0; x0'];
            self.m_log.run.ek = [self.m_log.run.ek; ek'];
            self.m_log.run.ts = [self.m_log.run.ts; Ts];
            self.m_log.run.x_target = [self.m_log.run.x_target; config.mpc.x_target'];

            self.m_log.run.time_qp = [self.m_log.run.time_qp; time_qp];
            self.m_log.run.time_qp = [self.m_log.run.time_qp; time_qp];

            self.m_log.run.dtk = [self.m_log.run.dtk; dtk'];
            self.m_log.run.dtk_prev = [self.m_log.run.dtk_prev; dtk_prev'];
        end
        
        % running 1 simulation cycle
        [y_,t_,m_,~] = self.sim_cycle2(config);

        % saving states
        ii = (i-1)*modes_len + 1;
        y(ii:ii+modes_len-1,:) = y_(1:modes_len,:);
        t(ii:ii+modes_len-1)   = t_(1:modes_len) + t0;
        m(ii:ii+modes_len-1)   = m_(1:modes_len);

        % saving control signal
        dtk_out(:,i) = dtk(:);

        % updating values for next cycle
        if t0 < 0
            bla = 1;
        end
        t0  = t_(end) + t0;
        config.x0 = y_(end,:)';
        x0  = config.x0;
    end
end
