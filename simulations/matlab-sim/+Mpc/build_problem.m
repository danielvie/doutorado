function problem = build_problem(cycle_model, config, options)
    % Build the prediction model, terminal ingredients, and static QP data.

    prediction = build_prediction_model(cycle_model, options);
    state_count = size(prediction.state_transition, 1);
    action_count = size(prediction.input_matrix, 2);

    if isempty(options.Q)
        state_weight = eye(state_count);
    else
        validate_square_matrix(options.Q, state_count, 'Options.Mpc.Q');
        state_weight = options.Q;
    end
    action_weight = eye(action_count);

    horizon = build_horizon_maps( ...
        prediction.state_transition, prediction.input_matrix, options.Np);
    dwell_change_map = build_dwell_change_map(action_count);
    minimum_dwell_change = Dynamics.minimum_dwell_change(config);

    state_weights = kron(eye(options.Np), state_weight);
    action_weights = kron(eye(options.Np), action_weight);
    dwell_maps = kron(eye(options.Np), dwell_change_map);
    dwell_bounds = repmat(minimum_dwell_change, options.Np, 1);

    feedback_gain = dlqr( ...
        prediction.state_transition, prediction.input_matrix, ...
        state_weight, action_weight);
    closed_loop = prediction.state_transition ...
        - prediction.input_matrix * feedback_gain;
    terminal_cost = dlyap(closed_loop', ...
        closed_loop' * state_weight * closed_loop ...
        + feedback_gain' * action_weight * feedback_gain);
    [terminal_matrix, terminal_bound] = terminal_set( ...
        closed_loop, dwell_change_map, feedback_gain, minimum_dwell_change);

    hessian = 2 * ( ...
        horizon.input_map' * state_weights * horizon.input_map ...
        + action_weights ...
        + horizon.terminal_input_map' * terminal_cost ...
            * horizon.terminal_input_map);
    hessian = (hessian + hessian') / 2;

    gradient_map = 2 * ( ...
        horizon.input_map' * state_weights * horizon.state_map ...
        + horizon.terminal_input_map' * terminal_cost ...
            * horizon.terminal_state_transition);
    inequality_matrix = [ ...
        -dwell_maps; ...
        terminal_matrix * horizon.terminal_input_map];
    inequality_base_bound = [-dwell_bounds; terminal_bound];
    inequality_state_map = [ ...
        zeros(numel(dwell_bounds), state_count); ...
        terminal_matrix * horizon.terminal_state_transition];

    problem = struct();
    problem.cycle_model = cycle_model;
    problem.prediction = prediction;
    problem.prediction_horizon = options.Np;
    problem.update_period_cycles = options.Nd;
    problem.action_count = action_count;
    problem.feedback_gain = feedback_gain;
    problem.qp = struct( ...
        'hessian', hessian, ...
        'gradient_map', gradient_map, ...
        'inequality_matrix', inequality_matrix, ...
        'inequality_base_bound', inequality_base_bound, ...
        'inequality_state_map', inequality_state_map, ...
        'plan_size', action_count * options.Np);
    problem.solver_options = optimoptions('quadprog', ...
        'Algorithm', options.solver_algorithm, ...
        'Display', options.solver_display);

    % Hardware and diagnostic compatibility.
    problem.K = feedback_gain;
    problem.p = action_count;
    problem.Np = options.Np;
    problem.Nd = options.Nd;
    problem.block_length_cycles = options.Nd;
    problem.state_mode = options.state_mode;
end

function prediction = build_prediction_model(cycle_model, options)
    Phi = cycle_model.Phi;
    Gamma = cycle_model.Gamma;

    A_block = Phi ^ options.Nd;
    B_block = zeros(size(Gamma));
    Phi_power = eye(size(Phi));
    for cycle = 1:options.Nd
        B_block = B_block + Phi_power * Gamma;
        Phi_power = Phi * Phi_power;
    end

    prediction = struct();
    prediction.block_length_cycles = options.Nd;
    prediction.uses_previous_action = false;

    if options.state_mode == Enums.StateMode.ORIGINAL
        prediction.state_transition = A_block;
        prediction.input_matrix = B_block;
        return;
    end
    if options.state_mode ~= Enums.StateMode.AUGMENTED
        error('Options.Mpc.state_mode must be ORIGINAL or AUGMENTED.');
    end

    warning('Mpc:build_problem:ExperimentalDelayModel', ...
        ['AUGMENTED models a one-block actuation delay that is not ', ...
         'present in Simulation.run.']);
    state_count = size(A_block, 1);
    action_count = size(B_block, 2);
    prediction.state_transition = [ ...
        A_block, B_block; ...
        zeros(action_count, state_count), zeros(action_count, action_count)];
    prediction.input_matrix = [ ...
        zeros(state_count, action_count); eye(action_count)];
    prediction.uses_previous_action = true;
end

function horizon = build_horizon_maps(A, B, prediction_horizon)
    state_count = size(A, 1);
    action_count = size(B, 2);
    state_map = zeros(state_count * prediction_horizon, state_count);
    input_map = zeros( ...
        state_count * prediction_horizon, ...
        action_count * prediction_horizon);

    for prediction_step = 1:prediction_horizon
        state_rows = (prediction_step - 1) * state_count ...
            + (1:state_count);
        state_map(state_rows, :) = A ^ prediction_step;

        for action_step = 1:prediction_step
            action_columns = (action_step - 1) * action_count ...
                + (1:action_count);
            input_map(state_rows, action_columns) = ...
                A ^ (prediction_step - action_step) * B;
        end
    end

    terminal_rows = (prediction_horizon - 1) * state_count ...
        + (1:state_count);
    horizon = struct();
    horizon.state_map = state_map;
    horizon.input_map = input_map;
    horizon.terminal_state_transition = A ^ prediction_horizon;
    horizon.terminal_input_map = input_map(terminal_rows, :);
end

function dwell_change_map = build_dwell_change_map(action_count)
    interval_count = action_count + 1;
    dwell_change_map = zeros(interval_count, action_count);
    dwell_change_map(1, 1) = 1;
    for interval = 2:action_count
        dwell_change_map(interval, interval - 1) = -1;
        dwell_change_map(interval, interval) = 1;
    end
    dwell_change_map(interval_count, action_count) = -1;
end

function [terminal_matrix, terminal_bound] = terminal_set( ...
    closed_loop, dwell_change_map, feedback_gain, minimum_dwell_change)
    system = LTISystem('A', closed_loop);
    admissible_set = Polyhedron( ...
        'H', [dwell_change_map * feedback_gain, -minimum_dwell_change]);

    warning_state = warning;
    restore_warnings = onCleanup(@() warning(warning_state)); %#ok<NASGU>
    warning('off', 'all');
    invariant_set = system.invariantSet('X', admissible_set);

    halfspaces = invariant_set.H;
    terminal_matrix = halfspaces(:, 1:end-1);
    terminal_bound = halfspaces(:, end);
end

function validate_square_matrix(value, expected_size, name)
    if ~ismatrix(value) || any(size(value) ~= [expected_size, expected_size])
        error('%s must be a %dx%d matrix.', name, expected_size, expected_size);
    end
end
