classdef Planner < handle
    % Planner - Handles reference trajectory generation for switched systems.
    %
    % Computes the mode sequence (Omega), switching times (Ts), and periodic
    % orbit equilibrium (x0) from a duty cycle alpha or a reference current.
    %
    % Usage:
    %   planner = Trajectory.Planner(config);
    %   planner.set_alpha(0.5);
    %   % config.Omega, config.Ts, config.x0 are now updated
    %
    % The Planner operates on a config struct passed by reference through
    % a holding property. After calling set_alpha() or set_reference_current(),
    % use planner.result to retrieve the computed values.

    properties
        circuit_params  % Circuit parameters struct (E, R, C1, C2, L)
        result          % Last computed result struct (.Omega, .Ts, .x0)
    end

    properties (Access = private)
        n = 3           % Number of switching cells (default)
        T = 0.28e-3     % Period of the complete cycle (default)
    end

    methods
        function self = Planner(circuit_params, n, T)
            % Constructor
            %   Planner(circuit_params)     - use default n=3, T=0.28ms
            %   Planner(circuit_params,n,T) - custom cells and period
            self.circuit_params = circuit_params;
            if nargin > 1, self.n = n; end
            if nargin > 2, self.T = T; end
            self.result = struct();
        end

        function [Omega, Ts, x0] = set_alpha(self, alpha, config)
            % set_alpha - Compute trajectory from duty cycle.
            %
            % Inputs:
            %   alpha  - Duty cycle in (0, 1)
            %   config - Full config struct (needed for x0 computation)
            %
            % Outputs (optional):
            %   Omega - Mode sequence
            %   Ts    - Switching time sequence
            %   x0    - Periodic orbit equilibrium

            params = self.circuit_params;
            params.alpha = alpha;
            params.iMax = params.E / params.R;
            params.iLref = alpha * params.iMax;
            params.n = self.n;
            params.T = self.T;

            fprintf('Trajectory: set alpha = %.4f\n', alpha);
            [Omega, Ts, x0] = self.compute(params, config);
        end

        function [Omega, Ts, x0] = set_reference_current(self, iref, config)
            % set_reference_current - Compute trajectory from reference current.
            %
            % Inputs:
            %   iref   - Reference inductor current [A]
            %   config - Full config struct (needed for x0 computation)
            %
            % Outputs (optional):
            %   Omega - Mode sequence
            %   Ts    - Switching time sequence
            %   x0    - Periodic orbit equilibrium

            params = self.circuit_params;
            params.iLref = iref;
            params.iMax = params.E / params.R;
            params.alpha = iref / params.iMax;
            params.n = self.n;
            params.T = self.T;

            fprintf('Trajectory: set iref = %.4f (alpha = %.4f)\n', iref, params.alpha);
            [Omega, Ts, x0] = self.compute(params, config);
        end
    end

    methods (Access = private)
        function [Omega, Ts, x0] = compute(self, params, config)
            % Core computation: Industrial Solution + periodic orbit

            [Omega, dT] = Utils.industrial_solution(params.alpha, params.n, params.T);

            % Filter negligible time intervals
            valid_idx = dT >= 1e-16;
            Omega = Omega(valid_idx);
            dT = dT(valid_idx);

            % Compute switching time sequence (cumulative)
            Ts = Utils.get_ts(dT);

            % Compute periodic orbit equilibrium
            % (needs a temporary config with updated Omega and Ts)
            temp_config = config;
            temp_config.Omega = Omega;
            temp_config.Ts = Ts;
            x0 = Utils.get_x0(temp_config);

            % Store result
            self.result.Omega = Omega;
            self.result.Ts    = Ts;
            self.result.x0    = x0;
            self.result.alpha = params.alpha;

            fprintf('Trajectory: %d modes, T = %.2f us\n', numel(Omega), Ts(end)*1e6);
        end
    end
end
