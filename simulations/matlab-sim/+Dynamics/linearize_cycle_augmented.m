function model = linearize_cycle_augmented(config)
    % Linearize through homogeneous augmented states and duration changes.
    %
    % Source: DOCS/linearization/linearization.tex
    %
    %   X = [x; 1]
    %   F_i = [A_i, b_i; 0, 0]
    %   phi_i = expm(F_i * Delta_t_bar_i)
    %
    %   e(t_N) = Phi_augmented * e(t_0) ...
    %       + Gamma_duration * delta_duration
    %
    % The document perturbs all N interval durations. The runtime actuator
    % instead perturbs N-1 interior switching times while fixing both cycle
    % endpoints. Therefore this implementation projects the duration model:
    %
    %   delta_duration = duration_from_switching_time * delta_t
    %   Gamma = Gamma_duration(1:n, :) * duration_from_switching_time

    Omega = config.Omega(:);
    t_bar = config.Ts(:);
    x_bar_0 = config.orbit_anchor(:);

    interval_count = numel(Omega);
    state_count = numel(x_bar_0);
    augmented_count = state_count + 1;
    assert(numel(t_bar) == interval_count + 1, ...
        'A switching schedule needs one more boundary than interval.');
    assert(all(diff(t_bar) > 0), ...
        'Nominal dwell durations must be positive.');

    F = cell(interval_count, 1);
    phi = cell(interval_count, 1);
    X_bar = zeros(augmented_count, interval_count + 1);
    X_bar(:, 1) = [x_bar_0; 1];

    for interval = 1:interval_count
        mode = Omega(interval);
        F{interval} = [ ...
            config.A{mode}, config.b{mode}; ...
            zeros(1, augmented_count)];
        nominal_duration = t_bar(interval + 1) - t_bar(interval);
        phi{interval} = expm(F{interval} * nominal_duration);
        X_bar(:, interval + 1) = phi{interval} * X_bar(:, interval);
    end

    Phi_augmented = eye(augmented_count);
    for interval = 1:interval_count
        Phi_augmented = phi{interval} * Phi_augmented;
    end

    Gamma_duration = zeros(augmented_count, interval_count);
    downstream_transition = eye(augmented_count);
    for interval = interval_count:-1:1
        Gamma_duration(:, interval) = downstream_transition ...
            * F{interval} * X_bar(:, interval + 1);
        downstream_transition = downstream_transition * phi{interval};
    end

    duration_from_switching_time = fixed_period_duration_map(interval_count);

    model = struct();
    model.Phi = Phi_augmented(1:state_count, 1:state_count);
    model.Gamma = Gamma_duration(1:state_count, :) ...
        * duration_from_switching_time;
    model.orbit_states = X_bar(1:state_count, :);
    model.orbit_anchor = x_bar_0;
    model.boundary_times = t_bar;
    model.dynamics_indices = Omega;
    model.Phi_augmented = Phi_augmented;
    model.Gamma_duration = Gamma_duration;
    model.duration_from_switching_time = duration_from_switching_time;
end

function map = fixed_period_duration_map(interval_count)
    switching_time_count = interval_count - 1;
    map = zeros(interval_count, switching_time_count);
    map(1, 1) = 1;
    for interval = 2:switching_time_count
        map(interval, interval - 1) = -1;
        map(interval, interval) = 1;
    end
    map(interval_count, switching_time_count) = -1;
end
