classdef Simulacao < handle
    properties
        config;
        mpc;
        opt;
    end

    methods
        % .. constructor
        function obj = Simulacao()
            disp('starting `Simulacao` class')
        end

        % .. preparation
        load(obj, sim_name);
        otmin(obj, config);
        
        % .. simulation
        [y,t,u,m,dtk_out] = sim_n(obj, nsim);

        % .. helpers
        Xr = get_xr(obj);
    end
end