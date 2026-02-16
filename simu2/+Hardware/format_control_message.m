function msg_out = format_control_message(config)
    % format_control_message - Format BLE message with control signal data.
    %
    % Creates the MESSAGE_DATA string to send to the ESP32 hardware.
    %
    % Inputs:
    %   config - struct with fields:
    %       .mpc.K       : Gain matrix
    %       .Ts          : Switching time sequence
    %       .Omega       : Mode index sequence
    %       .mpc.x_target: Target state vector
    %
    % Outputs:
    %   msg_out - Formatted message string

    % gain_k
    gain_k = config.mpc.K;
    str_gain_k_elements = arrayfun(@num2str, gain_k, 'UniformOutput', false);
    str_gain_k = strjoin(str_gain_k_elements, ',');
    [m,n] = size(gain_k);

    % times (microseconds, rounded)
    time_us = arrayfun(@round, diff(config.Ts*1e6));
    str_times_elements = arrayfun(@num2str, time_us, 'UniformOutput', false);
    str_time_us = strjoin(str_times_elements, ',');

    % modes (0-indexed for hardware)
    mode = config.Omega - 1;
    str_mode_elements = arrayfun(@num2str, mode, 'UniformOutput', false);
    str_mode = strjoin(str_mode_elements, ',');

    % x_target
    target = config.mpc.x_target;
    str_target_elements = arrayfun(@num2str, target, 'UniformOutput', false);
    str_target = strjoin(str_target_elements, ',');

    msg_out = sprintf("MESSAGE_DATA:%d;%d;%s;%s;%s;%s;", m, n, str_gain_k, str_time_us, str_mode, str_target);
end
