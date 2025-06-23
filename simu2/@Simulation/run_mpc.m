function [dtk, exitflag] = run_mpc(self, config, x0, dtk_prev)

    % compute `ek`
    ek  = x0 - config.mpc.x_target;
    
    % compute augmented `ek_aug`
    ek_aug = [ek; dtk_prev];
    
    % compute control `dtk`
    % ?? augmented
    if self.m_state_mode == Enums.StateMode.AUGMENTED
        [dtk, ~, exitflag] = Mpc.dualmode_switching(ek_aug,config.mpc.H,config.mpc.Hf,config.mpc.Phi1Np,...
                                                    config.mpc.Qbar,config.mpc.Rbar,config.mpc.Lbar,...
                                                    config.mpc.cbar,config.mpc.Pf,config.mpc.Sf,config.mpc.bf,...
                                                    config.mpc.PhiNp,config.mpc.p);
    else % Enums.StateMode.ORIGINAL
        [dtk, ~, exitflag] = Mpc.dualmode_switching(ek,config.mpc.H,config.mpc.Hf,config.mpc.Phi1Np,...
                                                    config.mpc.Qbar,config.mpc.Rbar,config.mpc.Lbar,...
                                                    config.mpc.cbar,config.mpc.Pf,config.mpc.Sf,config.mpc.bf,...
                                                    config.mpc.PhiNp,config.mpc.p);
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

end