function s(self, alpha)

    % compute signal based on alpha
    self.simulation.set_traj_phase_with_alpha(alpha);

    % get values of time_us and mode
    time_us = self.simulation.get_time_us();
    mode = self.simulation.get_mode();

    % construct signal message
    command = Utils.signal_create( ...
        time_us, ...
        mode);

    % sending message with command
    self.msg(command);
    fprintf("send command: %s\n", command);

end