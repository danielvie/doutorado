% [y,t,u] = sim_n(config, Ts)
function time_us = signal_process(self, state, dtk_prev)

    % reading config
    config = self.m_config;

    % compute x0
    vc1 = state(1);
    vc2 = state(2);
    i_l = state(3);
    x0  = [vc1; vc2; i_l];

    % compute dtk
    tic;
    [dtk, exitflag] = run_mpc(self, config, x0, dtk_prev);
    time_qp = toc;

    % compute new time vector from dtk
    Ts = config.Ts;
    Ts = self.quantizacao(Ts, Enums.QuantType.Sim);
    
    for j = 1:numel(dtk)
        Ts(j+1) = Ts(j+1) + dtk(j);
    end

    % logging data
    time_us = arrayfun(@round, diff(Ts*1e6));
    
    % add iteration
    if isempty(self.m_log.signal.iter)
        self.m_log.signal.iter = [self.m_log.signal.iter; 1];
    else
        self.m_log.signal.iter = [self.m_log.signal.iter; self.m_log.signal.iter(end)+1];
    end

    % compute `ek`
    ek  = x0 - config.mpc.x_target;

    % log rest of data
    self.m_log.signal.exitflag = [self.m_log.signal.exitflag; exitflag];
    self.m_log.signal.time_us = [self.m_log.signal.time_us; time_us];
    self.m_log.signal.x0 = [self.m_log.signal.x0; x0'];
    self.m_log.signal.ek = [self.m_log.signal.ek; ek'];
    self.m_log.signal.x_target = [self.m_log.signal.x_target; config.mpc.x_target'];

    self.m_log.signal.time_qp = [self.m_log.signal.time_qp; time_qp];

    self.m_log.signal.dtk = [self.m_log.signal.dtk; dtk'];
    self.m_log.signal.dtk_prev = [self.m_log.signal.dtk_prev; dtk_prev'];
end