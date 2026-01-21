classdef Planner < handle
    % Planner - Handles reference trajectory generation
    
    properties
        config % Handle to Data.Config object
    end
    
    methods
        function self = Planner(config)
            self.config = config;
        end
        
        function set_alpha(self, alpha)
            % Sets trajectory based on duty cycle alpha
            params = self.get_params();
            
            % Update params based on alpha
            params.alpha = alpha;
            params.iMax = params.E/params.R;
            params.iLref = params.alpha * params.iMax;
            
            self.compute_and_update(params);
        end
        
        function set_reference_current(self, iref)
            % Sets trajectory based on reference current
            params = self.get_params();
            
            % Update params based on iref
            params.iLref = iref;
            params.iMax = params.E/params.R;
            params.alpha = params.iLref / params.iMax;
            
            self.compute_and_update(params);
        end
        
    end
    
    methods (Access = private)
        function params = get_params(self)
            % Extract parameters with defaults
            params = self.config.circuit_params;
            
            % Default defaults (moved from legacy methods)
            if ~isfield(params, 'n'), params.n = 3; end
            if ~isfield(params, 'T'), params.T = 0.28e-3; end
        end
        
        function compute_and_update(self, params)
            % Core logic: Computes "Industrial Solution" and updates Config
            
            [Omega, dT] = Utils.industrial_solution(params.alpha, params.n, params.T);
            
            % Filter small time steps
            EPS = 1e-16;
            valid_idx = dT >= EPS;
            Omega = Omega(valid_idx);
            dT = dT(valid_idx);
            
            % Update Configuration
            self.config.Omega = Omega;
            self.config.Ts = Utils.get_ts(dT);
            self.config.x0 = Utils.get_x0(self.config);
            
            % Log
            fprintf('Trajectory updated (alpha=%.2f, cycles=%d)\n', params.alpha, numel(Omega));
        end
    end
end
