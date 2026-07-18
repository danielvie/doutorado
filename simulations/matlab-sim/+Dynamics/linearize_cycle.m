function model = linearize_cycle(config)
    % Linearize one nominal switching cycle at its orbit anchor.
    %
    % Thesis equation boundary:
    %
    %   e(t_{j,N}) = Phi * e(t_{j,0}) + Gamma * delta_t[j]
    %
    %   Phi = F_N * F_{N-1} * ... * F_1
    %
    %   Gamma = [
    %       F_N * ... * F_2 * ((A_1 - A_2) * x_bar(t_bar_1) + b_1 - b_2),
    %       F_N * ... * F_3 * ((A_2 - A_3) * x_bar(t_bar_2) + b_2 - b_3),
    %       ...,
    %       F_N * ((A_{N-1} - A_N) * x_bar(t_bar_{N-1}) + b_{N-1} - b_N)
    %   ]
    %
    %   delta_t[j] = [delta_t_{j,1}, ..., delta_t_{j,N-1}]^T
    %
    % Thesis equations 4.32-4.34 also include the final column
    %   A_N * x_bar(t_bar_N) + b_N
    % associated with delta_t_N, which perturbs the cycle-end time.
    % This implementation uses the fixed-period restriction of that model:
    % the cycle-start and cycle-end times are fixed, Gamma contains only its
    % first N-1 columns, and only interior switching times are controlled.

    dynamics_indices = config.Omega(:);
    boundary_times = config.Ts(:);
    orbit_anchor = config.orbit_anchor(:);

    interval_count = numel(dynamics_indices);
    state_count = numel(orbit_anchor);
    assert(numel(boundary_times) == interval_count + 1, ...
        'A switching schedule needs one more boundary than interval.');
    assert(all(diff(boundary_times) > 0), ...
        'Nominal dwell durations must be positive.');

    interval_transitions = cell(interval_count, 1);
    orbit_states = zeros(state_count, interval_count + 1);
    orbit_states(:, 1) = orbit_anchor;

    for interval = 1:interval_count
        dynamics_index = dynamics_indices(interval);
        A_mode = config.A{dynamics_index};
        b_mode = config.b{dynamics_index};
        dwell_duration = boundary_times(interval + 1) ...
            - boundary_times(interval);

        affine_generator = [A_mode, b_mode; zeros(1, state_count + 1)];
        affine_transition = expm(affine_generator * dwell_duration);
        interval_transitions{interval} = ...
            affine_transition(1:state_count, 1:state_count);

        augmented_state = affine_transition * [orbit_states(:, interval); 1];
        orbit_states(:, interval + 1) = augmented_state(1:state_count);
    end

    Phi = eye(state_count);
    for interval = 1:interval_count
        Phi = interval_transitions{interval} * Phi;
    end

    Gamma = zeros(state_count, interval_count - 1);
    downstream_transition = eye(state_count);
    for boundary = interval_count - 1:-1:1
        downstream_transition = downstream_transition ...
            * interval_transitions{boundary + 1};

        state_at_boundary = orbit_states(:, boundary + 1);
        before_index = dynamics_indices(boundary);
        after_index = dynamics_indices(boundary + 1);
        vector_field_jump = ...
            (config.A{before_index} - config.A{after_index}) ...
                * state_at_boundary ...
            + config.b{before_index} - config.b{after_index};

        Gamma(:, boundary) = downstream_transition * vector_field_jump;
    end

    model = struct();
    model.Phi = Phi;
    model.Gamma = Gamma;
    model.orbit_states = orbit_states;
    model.orbit_anchor = orbit_anchor;
    model.boundary_times = boundary_times;
    model.dynamics_indices = dynamics_indices;
end
