function signal = signal_create(time, mode)
    
    % Check if vectors are the same length
    if length(time) ~= length(mode)
        error('Vectors must be the same length');
    end

    % make time not be smaller than a value
    time_ = arrayfun(@(x) max(x, 20), time);

    % Convert vector a to string
    time_str = strjoin(arrayfun(@num2str, time_, 'UniformOutput', false), ',');

    % Convert vector b to string
    mode_str = strjoin(arrayfun(@num2str, mode, 'UniformOutput', false), ',');

    % Combine into final signal format
    signal = sprintf('SIGNAL:%s;%s', time_str, mode_str);

end