classdef Config
    properties
        sim_name
        Omega
        smax
        A
        b
        C
        D
        tstep
        xref
        Q
        Tpmax
        Ts
        x0
        circuit_params
        mpc
        c_time
        quant_traj
        quant_sim
        kawa
        otmin
    end
    
    methods
        function self = Config()
            % Default initialization
            self.mpc = struct();
            self.mpc.on = false;
        end
    end
end
