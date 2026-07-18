classdef Planner < handle
    % Planner - Build a nominal switching schedule and its orbit anchor.
    %
    % The nominal duty ratio or inductor-current setpoint determines the
    % schedule. The caller applies the returned schedule and orbit anchor.

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
            % set_alpha - Build a schedule from the nominal duty ratio.
            %
            % Inputs:
            %   alpha  - Nominal duty ratio in (0, 1)
            %   config - Dynamics used to compute the orbit anchor
            %
            % Outputs (optional):
            %   Omega - Dynamics-index sequence
            %   Ts    - Nominal cycle-boundary times
            %   x0    - Orbit anchor at the cycle-start boundary

            params = self.circuit_params;
            params.alpha = alpha;
            params.iMax = params.E / params.R;
            params.iLref = alpha * params.iMax;
            params.n = self.n;
            params.T = self.T;

            fprintf('Nominal schedule: duty ratio = %.4f\n', alpha);
            [Omega, Ts, x0] = self.compute(params, config);
        end

        function [Omega, Ts, x0] = set_reference_current(self, iref, config)
            % set_reference_current - Build a schedule from a current setpoint.
            %
            % Inputs:
            %   iref   - Inductor-current setpoint [A]
            %   config - Dynamics used to compute the orbit anchor
            %
            % Outputs (optional):
            %   Omega - Dynamics-index sequence
            %   Ts    - Nominal cycle-boundary times
            %   x0    - Orbit anchor at the cycle-start boundary

            params = self.circuit_params;
            params.iLref = iref;
            params.iMax = params.E / params.R;
            params.alpha = iref / params.iMax;
            params.n = self.n;
            params.T = self.T;

            fprintf(['Nominal schedule: inductor-current setpoint = %.4f A ', ...
                '(duty ratio = %.4f)\n'], iref, params.alpha);
            [Omega, Ts, x0] = self.compute(params, config);
        end
    end

    methods (Access = private)
        function [Omega, Ts, x0] = compute(self, params, config)
            % Build the nominal schedule and its cycle-start orbit anchor.

            [Omega, dT] = Utils.industrial_solution(params.alpha, params.n, params.T);

            % Filter negligible time intervals
            valid_idx = dT >= 1e-16;
            Omega = Omega(valid_idx);
            dT = dT(valid_idx);

            % Convert dwell durations to cumulative cycle-boundary times.
            Ts = Utils.get_ts(dT);

            % Compute the orbit anchor for the new nominal schedule.
            temp_config = config;
            temp_config.Omega = Omega;
            temp_config.Ts = Ts;
            x0 = Utils.get_x0(temp_config);

            % Store result
            self.result.Omega = Omega;
            self.result.Ts    = Ts;
            self.result.x0    = x0;
            self.result.alpha = params.alpha;

            fprintf('Nominal schedule: %d intervals, period = %.2f us\n', ...
                numel(Omega), Ts(end) * 1e6);
        end
    end
end
