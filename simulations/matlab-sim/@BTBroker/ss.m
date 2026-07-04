function ss(self, alpha)

    % compute signal based on alpha
    self.simulation.set_traj_phase_with_alpha(alpha);
    self.simulation.set_mpc();

    % get values of time_us and mode
    command = self.simulation.get_msg_control_signal();

    % sending message with command
    self.msg(command);
    fprintf("send command: %s\n", command);

end