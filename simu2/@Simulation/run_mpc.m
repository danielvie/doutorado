function [dtk, exitflag] = run_mpc(self, config, x0, dtk_prev)

    % read config
    cfg = config;

    % compute `ek`
    ek  = x0 - cfg.mpc.x_target;
    
    % compute augmented `ek_aug`
    ek_aug = [ek; dtk_prev];
    
    % compute control `dtk`
    % ?? augmented
    if self.m_state_mode == Enums.StateMode.AUGMENTED
        [dtk, ~, exitflag] = Mpc.dualmode_switching(ek_aug,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,...
                                                    cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,...
                                                    cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,...
                                                    cfg.mpc.PhiNp,cfg.mpc.p);
    else % Enums.StateMode.ORIGINAL
        [dtk, ~, exitflag] = Mpc.dualmode_switching(ek,cfg.mpc.H,cfg.mpc.Hf,cfg.mpc.Phi1Np,...
                                                    cfg.mpc.Qbar,cfg.mpc.Rbar,cfg.mpc.Lbar,...
                                                    cfg.mpc.cbar,cfg.mpc.Pf,cfg.mpc.Sf,cfg.mpc.bf,...
                                                    cfg.mpc.PhiNp,cfg.mpc.p);
    end
    
    % ignore control if problem not possible
    %  exitflag:
    %    1: function converged to the solution x
    %    0: number of iterations exceeded MaxIterations
    %   -2: problem is infeasible
    %   -3: problem is unbounded
    if exitflag ~= 1
        dtk = dtk*0;
    end
    
    % compute new time vector from dtk
    Ts = config.Ts;
    Ts = self.quantizacao(Ts, Enums.QuantType.Sim);
    
    for j = 1:numel(dtk)
        Ts(j+1) = Ts(j+1) + dtk(j);
    end
end