classdef Proportional < Controllers.Controller
    % Proportional - LQR-based proportional controller with constraint conditioning.
    %
    % Computes dtk = -K * ek and applies switching constraint conditioning
    % to ensure minimum dwell time is respected. The MPC controller handles
    % this internally via its QP constraints, but the proportional controller
    % has no such mechanism — so conditioning is done here.

    properties
        K              % Gain matrix (from dlqr)
        Nd = 1         % Downsampling factor (1 = every step)
        time_us        % Nominal switching intervals [us] (for conditioning)
        min_gap_us     % Minimum gap between switching instants [us]

        % Internal state
        counter
        last_dtk
    end

    methods
        function self = Proportional(K, Nd, time_us, min_gap_us)
            % Constructor
            %   Proportional(K)
            %   Proportional(K, Nd)
            %   Proportional(K, Nd, time_us, min_gap_us)
            %
            % Inputs:
            %   K          - Gain matrix (p x n)
            %   Nd         - Downsampling factor (default: 1)
            %   time_us    - Nominal switching intervals in microseconds
            %   min_gap_us - Minimum gap constraint in microseconds

            if nargin > 0, self.K = K; end
            if nargin > 1, self.Nd = Nd; end
            if nargin > 2, self.time_us = time_us; end
            if nargin > 3, self.min_gap_us = min_gap_us; end
            self.reset();
        end

        function reset(self)
            % Initialize so the first step triggers a computation
            self.counter = self.Nd;
            self.last_dtk = [];
        end

        function [dtk, exitflag, info] = compute_control(self, x, x_target)
            info = struct('time_qp', 0);

            % Check if we should compute or hold
            if self.counter < self.Nd
                % Hold previous control
                if isempty(self.last_dtk)
                    dtk = zeros(size(self.K, 1), 1);
                else
                    dtk = self.last_dtk;
                end
                exitflag = 44; % "Held/Cached" status
                self.counter = self.counter + 1;
            else
                % Compute new control
                tic_start = tic;

                ek = x - x_target;
                dtk = -self.K * ek;

                % Apply switching constraint conditioning
                % (MPC handles this via QP constraints, but proportional needs it)
                if ~isempty(self.time_us) && ~isempty(self.min_gap_us)
                    dtk_us = dtk * 1e6;
                    dtk_us = Controllers.condition_dtk( ...
                        self.time_us, dtk_us, self.min_gap_us);
                    dtk = dtk_us * 1e-6;
                end

                info.time_qp = toc(tic_start);
                exitflag = 1;

                % Update state
                self.last_dtk = dtk;
                self.counter = 1;
            end
        end
    end
end
