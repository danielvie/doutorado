function [dtk, exitflag, info] = step_control(self, x0, x_target)
    % Delegates control computation to the external controller
    [dtk, exitflag, info] = self.m_controller.compute_control(x0, x_target);
end
