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
            % Default initialization of complex properties
            
            % MPC default configuration
            self.mpc = struct();
            self.mpc.on = false;
            self.mpc.x_target = [];
            
            % Circuit parameters for physical models
            self.circuit_params = struct('E', [], 'C1', [], 'C2', [], 'L', [], 'R', []);
            
            % Optimization options for trajectory planning (otmin)
            self.otmin = struct('x0', [], 'lb', [], 'ub', [], 'A', [], 'b', [], 'Aeq', [], 'beq', []);
        end
    end
end
