function msg_control_signal = get_msg_control_signal(self)

    % gain_k
    gain_k = self.get_gain_k();
    str_gain_k_elements = arrayfun(@num2str, gain_k, 'UniformOutput', false);
    str_gain_k = strjoin(str_gain_k_elements, ',');
    [m,n] = size(gain_k);

    % times
    time_us = self.get_time_us();
    str_times_elements = arrayfun(@num2str, time_us, 'UniformOutput', false);
    str_time_us = strjoin(str_times_elements, ',');

    % modes
    mode = self.get_mode();
    str_mode_elements = arrayfun(@num2str, mode, 'UniformOutput', false);
    str_mode = strjoin(str_mode_elements, ',');
    
    % x_target
    target = self.get_target();
    str_target_elements = arrayfun(@num2str, target, 'UniformOutput', false);
    str_target = strjoin(str_target_elements, ',');

    msg_control_signal = sprintf("MESSAGE_DATA:%d;%d;%s;%s;%s;%s;", m,n,str_gain_k,str_time_us,str_mode,str_target);

end