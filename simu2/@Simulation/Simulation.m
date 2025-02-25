classdef Simulation < handle
    properties
        config;
        mpc;
        opt;
    end

    methods
        % .. constructor
        function self = Simulation()
            % disp('starting `Simulacao` class')
        end

        % .. preparation
        set_config(self, sim_name);
        set_traj_phase(self, alpha);
        set_mpc(self);

        [Phi, Gamma] = mpc_construcao_modelo_instantes(self, Ac, Bc, tr, xr, config);
        [dtk, fval, exitflag] = mpc_dualmode_switching(self, ek, H, Hf, Phi1Np, Qbar, Rbar, Lbar, cbar, Pf, Sf, bf, PhiNp, p);

        
        % .. simulation
        [y,t,u,m,dtk_out] = run(self, nsim);
        [y,t,m,xr] = sim_cycle2(self, config);
        
        % .. helpers
        Xr = get_xr(self);
        x0 = get_x0(self);
        Ts_out  = quantizacao(self, Ts, type);
    end
    
    methods (Static)
        Ts = calc_ts(dT);
    end

end