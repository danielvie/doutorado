function signal = signal_create(time, mode)
    
    % Check if vectors are the same length
    if length(time) ~= length(mode)
        error('Vectors must be the same length');
    end

    % Convert vector a to string
    time_str = strjoin(arrayfun(@num2str, time, 'UniformOutput', false), ',');

    % Convert vector b to string
    mode_str = strjoin(arrayfun(@num2str, mode, 'UniformOutput', false), ',');

    % Combine into final signal format
    signal = sprintf('SIGNAL:%s;%s', time_str, mode_str);
end