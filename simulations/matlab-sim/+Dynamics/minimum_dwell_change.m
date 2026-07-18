function lower_bound = minimum_dwell_change(config)
    % Lower bound on dwell-duration changes caused by switching offsets.
    %
    % applied_dwell = nominal_dwell + dwell_change
    % dwell_change >= minimum_dwell_change(config)

    nominal_dwell = diff(config.Ts(:));
    minimum_pattern = config.c_time(:);
    interval_count = numel(nominal_dwell);
    pattern_indices = mod((0:interval_count - 1)', numel(minimum_pattern)) + 1;
    minimum_dwell = minimum_pattern(pattern_indices);
    lower_bound = minimum_dwell - nominal_dwell;
end
