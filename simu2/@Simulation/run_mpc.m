function [dtk, exitflag] = run_mpc(self, config, x0, dtk_prev)

    % compute `ek`
    ek  = x0 - config.mpc.x_target;
    
    % compute ek_input
    if self.m_state_mode == Enums.StateMode.AUGMENTED
        ek_input = [ek; dtk_prev];
    else % Enums.StateMode.ORIGINAL
        ek_input = ek;
    end
    
    % compute control `dtk`
    [dtk, ~, exitflag] = Mpc.dualmode_switching(ek_input,config.mpc.H,config.mpc.Hf,config.mpc.Phi1Np,...
                                                config.mpc.Qbar,config.mpc.Rbar,config.mpc.Lbar,...
                                                config.mpc.cbar,config.mpc.Pf,config.mpc.Sf,config.mpc.bf,...
                                                config.mpc.PhiNp,config.mpc.p);
    
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