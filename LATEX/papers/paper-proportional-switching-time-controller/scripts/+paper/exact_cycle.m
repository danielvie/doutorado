function state_end = exact_cycle(config, state_start, switching_offsets)
    boundary_states = paper.cycle_boundaries( ...
        config, state_start, switching_offsets);
    state_end = boundary_states(:, end);
end

