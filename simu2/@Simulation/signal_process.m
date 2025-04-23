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
    cfg.mpc.x_target = [1.38; 2.4; 0.05];
    ek = x0 - cfg.mpc.x_target;
    %ek = [0.01;0;0];

    % computing control `dtk`
    tic;
    [dtk, ~, exitflag] = Mpc.dualmode_switching(ek,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,cfg.mpc.PhiNp,cfg.mpc.p);
    time_qp = toc;
    %self.quadprog_dtk = [self.quadprog_dtk;dtk';];
    

    % ignore control if problem not possible
    %  exitflag:
    %    1: function converged to the solution x
    %    0: number of iterations exceeded MaxIterations
    %   -2: problem is infeasible
    %   -3: problem is unbounded
    if exitflag ~= 1
        dtk = dtk*0;
    end

    % reading nominal time values
    Ts = config.Ts;
    
    % applying quantization on time signal
    % Ts = self.quantizacao(Ts, Enums.QuantType.Sim);

    % updating time vector with control command
    for j = 1:numel(dtk)
        Ts(j+1) = Ts(j+1) + dtk(j);
    end


    % logging data
    time_us = arrayfun(@round, diff(Ts*1e6));
    
    % add iteration
    if isempty(self.log.iter)
        self.log.iter = [self.log.iter; 1];
    else
        self.log.iter = [self.log.iter; self.log.iter(end)+1];
    end

    % log rest of data
    self.log.exitflag = [self.log.exitflag; exitflag];
    self.log.time_us = [self.log.time_us; time_us];
    self.log.x0 = [self.log.x0; x0'];
    self.log.x_target = [self.log.x_target; cfg.mpc.x_target'];

    self.log.time_qp = [self.log.time_qp; time_qp];
end
