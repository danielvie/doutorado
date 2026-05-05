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
        control
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
            
            % Runtime control state
            self.control = struct();
            self.control.on = false;
            self.control.x_target = [];

            % MPC runtime data
            self.mpc = struct();
            
            % Circuit parameters for physical models
            self.circuit_params = struct('E', [], 'C1', [], 'C2', [], 'L', [], 'R', []);
            
            % Optimization options for trajectory planning (otmin)
            self.otmin = struct('x0', [], 'lb', [], 'ub', [], 'A', [], 'b', [], 'Aeq', [], 'beq', []);
        end
    end
end
