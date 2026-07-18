classdef MpcController < Controllers.Controller
    % Receding-horizon controller for switching-instant offsets.

    properties
        problem
        update_countdown
        held_action
        previous_applied_action
    end

    methods
        function self = MpcController(problem)
            self.problem = problem;
            self.reset();
        end

        function reset(self)
            self.update_countdown = 0;
            self.held_action = zeros(self.problem.action_count, 1);
            self.previous_applied_action = ...
                zeros(self.problem.action_count, 1);
        end

        function [switching_offsets, exitflag, info] = ...
                compute_control(self, cycle_input_state, orbit_anchor)
            info = struct('time_qp', 0, 'objective', nan);

            if self.update_countdown > 0
                switching_offsets = self.held_action;
                exitflag = 44;
                self.update_countdown = self.update_countdown - 1;
                return;
            end

            orbit_deviation = cycle_input_state - orbit_anchor;
            model_state = orbit_deviation;
            if self.problem.prediction.uses_previous_action
                model_state = [orbit_deviation; self.previous_applied_action];
            end

            qp_start = tic;
            [switching_offsets, objective, exitflag] = ...
                Mpc.solve(self.problem, model_state);
            info.time_qp = toc(qp_start);
            info.objective = objective;

            if exitflag ~= 1
                fprintf(2, ['[MpcController] QP exitflag=%d; ', ...
                    'using terminal feedback.\n'], exitflag);
                switching_offsets = ...
                    -self.problem.feedback_gain * model_state;
            end

            self.previous_applied_action = switching_offsets;
            self.held_action = switching_offsets;
            self.update_countdown = ...
                self.problem.update_period_cycles - 1;
        end
    end
end
