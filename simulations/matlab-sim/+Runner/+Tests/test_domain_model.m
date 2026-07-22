function test_domain_model()
    assert_cycle_linearization(Enums.SimName.PATINO_1);
    assert_cycle_linearization(Enums.SimName.LAB_CIRCUIT);

    simulation = Simulation(Enums.SimName.PATINO_1);
    orbit_anchor = simulation.m_config.orbit_anchor;
    cycle_model = simulation.get_cycle_linear_model();

    disturbance = [0.2; -0.1];
    simulation.set_offset(disturbance);
    assert(isequal(simulation.m_config.orbit_anchor, orbit_anchor));
    assert(isequal(simulation.m_config.x0, orbit_anchor + disturbance));

    disturbed_model = simulation.get_cycle_linear_model();
    assert(norm(disturbed_model.Phi - cycle_model.Phi) < 1e-12);
    assert(norm(disturbed_model.Gamma - cycle_model.Gamma) < 1e-12);

    options = Options.Mpc();
    options.Np = 2;
    options.Nd = 2;
    simulation.set_mpc(options);
    assert(isequal(simulation.get_target(), orbit_anchor));

    prediction = simulation.m_config.mpc.prediction;
    Phi = cycle_model.Phi;
    Gamma = cycle_model.Gamma;
    assert(norm(prediction.state_transition - Phi^2) < 1e-12);
    assert(norm(prediction.input_matrix ...
        - (eye(size(Phi)) + Phi) * Gamma) < 1e-12);
end

function assert_cycle_linearization(simulation_name)
    simulation = Simulation(simulation_name);
    if simulation_name == Enums.SimName.LAB_CIRCUIT
        simulation.alpha(0.5);
    end

    config = simulation.m_config;
    model = simulation.get_cycle_linear_model();
    augmented_model = Dynamics.linearize_cycle_augmented(config);
    [Phi_fd, Gamma_fd] = finite_difference(config);

    assert(norm(augmented_model.Phi - model.Phi) < 1e-10, ...
        'Augmented-state Phi differs from the direct derivation.');
    assert(norm(augmented_model.Gamma - model.Gamma) ...
        / max(1, norm(model.Gamma)) < 1e-10, ...
        'Augmented-state Gamma differs from the direct derivation.');

    state_error = norm(model.Phi - Phi_fd) / max(1, norm(Phi_fd));
    switching_error = norm(model.Gamma - Gamma_fd) ...
        / max(1, norm(Gamma_fd));
    assert(state_error < 1e-6, ...
        'Cycle state transition does not match finite differences.');
    assert(switching_error < 1e-6, ...
        'Switching-offset map does not match finite differences.');
end

function [Phi, Gamma] = finite_difference(config)
    state_count = numel(config.orbit_anchor);
    action_count = numel(config.Omega) - 1;
    state_step = 1e-7 * max(1, norm(config.orbit_anchor));
    time_step = max(1e-9, (config.Ts(end) - config.Ts(1)) * 1e-5);

    Phi = zeros(state_count);
    for state_index = 1:state_count
        plus_config = config;
        minus_config = config;
        plus_config.x0 = config.orbit_anchor;
        minus_config.x0 = config.orbit_anchor;
        plus_config.x0(state_index) = ...
            plus_config.x0(state_index) + state_step;
        minus_config.x0(state_index) = ...
            minus_config.x0(state_index) - state_step;
        Phi(:, state_index) = ...
            (cycle_end_state(plus_config) - cycle_end_state(minus_config)) ...
            / (2 * state_step);
    end

    Gamma = zeros(state_count, action_count);
    for action_index = 1:action_count
        plus_config = config;
        minus_config = config;
        plus_config.x0 = config.orbit_anchor;
        minus_config.x0 = config.orbit_anchor;
        boundary_index = action_index + 1;
        plus_config.Ts(boundary_index) = ...
            plus_config.Ts(boundary_index) + time_step;
        minus_config.Ts(boundary_index) = ...
            minus_config.Ts(boundary_index) - time_step;
        Gamma(:, action_index) = ...
            (cycle_end_state(plus_config) - cycle_end_state(minus_config)) ...
            / (2 * time_step);
    end
end

function final_state = cycle_end_state(config)
    [states, ~, ~, ~] = Dynamics.propagate_switching(config);
    final_state = states(end, :)';
end
