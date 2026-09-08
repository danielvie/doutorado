function states = cycle_boundaries(config, state_start, switching_offsets)
    boundary_times = config.Ts(:) + [0; switching_offsets(:); 0];
    assert(all(diff(boundary_times) > 0), ...
        'Exact cycle propagation received a nonpositive dwell.');
    state_count = numel(state_start);
    states = zeros(state_count, numel(config.Omega) + 1);
    states(:, 1) = state_start(:);
    for interval = 1:numel(config.Omega)
        mode = config.Omega(interval);
        generator = [config.A{mode}, config.b{mode}; ...
            zeros(1, state_count + 1)];
        transition = expm(generator * ...
            (boundary_times(interval + 1) - boundary_times(interval)));
        augmented_state = transition * [states(:, interval); 1];
        states(:, interval + 1) = augmented_state(1:state_count);
    end
end

