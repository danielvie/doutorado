classdef MpcController < Controllers.Controller
    % MpcController - Model Predictive Control with variable switching instants.
    %
    % Solves the dual-mode MPC QP problem at each control step using quadprog.
    % Falls back to proportional control (K*ek) when the QP is infeasible.
    %
    % Usage:
    %   s.set_mpc();
    %   mpc_data = s.m_config.mpc;
    %   ctrl = Controllers.MpcController(mpc_data);
    %   s.set_controller(ctrl);
    %
    % The MPC parameters (H, Hf, Phi1Np, ...) are computed by set_mpc()
    % and stored in config.mpc. This controller consumes that struct.

    properties
        mpc         % MPC data struct (from config.mpc)
        state_mode  % Enums.StateMode.ORIGINAL or .AUGMENTED
        Nd          % Downsampling factor (1 = every step)

        % Internal state
        counter
        last_dtk
        dtk_prev    % Previous control action (for augmented model)
    end

    methods
        function self = MpcController(mpc_data, varargin)
            % Constructor
            %   MpcController(mpc_data)
            %   MpcController(mpc_data, 'Nd', 3, 'StateMode', Enums.StateMode.ORIGINAL)
            %
            % Inputs:
            %   mpc_data   - struct from config.mpc (computed by set_mpc)
            %
            % Name-value pairs:
            %   'Nd'        - Downsampling factor (default: 1)
            %   'StateMode' - Enums.StateMode.ORIGINAL or AUGMENTED (default: ORIGINAL)

            self.mpc = mpc_data;

            % Defaults
            self.Nd = 1;
            self.state_mode = Enums.StateMode.ORIGINAL;

            % Parse optional name-value pairs
            for i = 1:2:numel(varargin)
                switch lower(varargin{i})
                    case 'nd'
                        self.Nd = varargin{i+1};
                    case 'statemode'
                        self.state_mode = varargin{i+1};
                end
            end

            self.reset();
        end

        function reset(self)
            % Reset internal state for a new simulation run
            self.counter  = self.Nd;  % trigger computation on first step
            self.last_dtk = [];
            self.dtk_prev = zeros(self.mpc.p, 1);
        end

        function [dtk, exitflag, info] = compute_control(self, x, x_target)
            % compute_control - Solve the MPC QP or hold previous control.
            %
            % Inputs:
            %   x        - Current state vector
            %   x_target - Target state vector
            %
            % Outputs:
            %   dtk      - Control action (switching time deviations)
            %   exitflag - Solver status (1=optimal, 0=max iter, -2=infeasible, 44=held)
            %   info     - Struct with .time_qp field

            info = struct('time_qp', 0);

            % --- Downsampling: hold previous control ---
            if self.counter < self.Nd
                if isempty(self.last_dtk)
                    dtk = zeros(self.mpc.p, 1);
                else
                    dtk = self.last_dtk;
                end
                exitflag = 44; % held/cached
                self.counter = self.counter + 1;
                return;
            end

            % --- Solve MPC QP ---
            tic_start = tic;

            % Compute error
            ek = x - x_target;

            % Augmented state (if delay compensation is active)
            if self.state_mode == Enums.StateMode.AUGMENTED
                ek_input = [ek; self.dtk_prev];
            else
                ek_input = ek;
            end

            % Solve QP via Mpc.dualmode_switching
            [dtk, ~, exitflag] = Mpc.dualmode_switching( ...
                ek_input, ...
                self.mpc.H, self.mpc.Hf, self.mpc.Phi1Np, ...
                self.mpc.Qbar, self.mpc.Rbar, self.mpc.Lbar, ...
                self.mpc.cbar, self.mpc.Pf, self.mpc.Sf, self.mpc.bf, ...
                self.mpc.PhiNp, self.mpc.p);

            info.time_qp = toc(tic_start);

            % Fallback: if QP is infeasible, use proportional law
            if exitflag ~= 1
                fprintf(2, '[MpcController] QP exitflag=%d, falling back to K*ek\n', exitflag);
                dtk = -self.mpc.K * ek;
            end

            % Update internal state
            self.last_dtk = dtk;
            self.dtk_prev = dtk;
            self.counter  = 1;
        end
    end
end
