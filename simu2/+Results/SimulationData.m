classdef SimulationData < handle
    % SimulationData - Standardized container for simulation results
    
    properties
        t       % Time vector (Control ON)
        y       % State matrix (Control ON)
        m       % Mode vector (Control ON)
        
        t_off   % Time vector (Control OFF)
        y_off   % State matrix (Control OFF)
        m_off   % Mode vector (Control OFF)
        
        target  % Target state vector
        config  % Simulation configuration
    end
    
    methods
        function self = SimulationData(vars)
            % Expects a struct 'vars' containing the simulation variables
            if nargin > 0
                self.parse_vars(vars);
            end
        end
        
        function parse_vars(self, vars)
            % Extract known variables from workspace dump
            if isfield(vars, 't'), self.t = vars.t; end
            if isfield(vars, 'y'), self.y = vars.y; end
            if isfield(vars, 'm'), self.m = vars.m; end
            
            if isfield(vars, 't_off'), self.t_off = vars.t_off; end
            if isfield(vars, 'y_off'), self.y_off = vars.y_off; end
            if isfield(vars, 'm_off'), self.m_off = vars.m_off; end
            
            if isfield(vars, 's')
                self.config = vars.s.m_config;

                if ~isempty(self.config.mpc) && isfield(self.config.mpc, 'x_target')
                    self.target = self.config.mpc.x_target;
                end
            end
        end
        
        function stats = calculate_metrics(self)
            % Calculate common performance metrics
            stats = struct();
            
            if isempty(self.target)
                warning('No target state defined. Cannot calculate error metrics.');
                return;
            end
            
            % RMS Error (ON)
            if ~isempty(self.y)
                err = self.y - self.target';
                stats.rmse_on = sqrt(mean(sum(err.^2, 2)));
                stats.final_err_on = norm(self.y(end, :) - self.target');
            end
            
            % RMS Error (OFF)
            if ~isempty(self.y_off)
                err_off = self.y_off - self.target';
                stats.rmse_off = sqrt(mean(sum(err_off.^2, 2)));
                stats.final_err_off = norm(self.y_off(end, :) - self.target');
            end
        end
    end
end
