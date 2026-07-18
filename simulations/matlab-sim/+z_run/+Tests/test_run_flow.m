function test_run_flow()
    simulation = Simulation(Enums.SimName.PATINO_1);
    initial_state = simulation.m_config.x0;
    modes_per_cycle = numel(simulation.m_config.Omega);

    simulation.set_control_enabled(false);
    [y, t, ~, dtk] = simulation.run(2);

    assert(size(y, 1) == 1 + 2 * modes_per_cycle);
    assert(isequal(y(1, :)', initial_state));
    assert(all(diff(t) > 0));
    assert(all(dtk(:) == 0));
    assert(isequal(simulation.m_log.run.x0(1, :)', initial_state));
    assert(isequal(simulation.m_log.run.x0(2, :), ...
        y(1 + modes_per_cycle, :)));

    control_len = numel(simulation.m_config.Omega) - 1;
    state_len = numel(initial_state);
    controller = Controllers.Proportional(1e-6 * ones(control_len, state_len));
    simulation.m_config.control.x_target = initial_state + ones(state_len, 1);
    simulation.set_controller(controller);
    simulation.set_control_enabled(true);
    simulation.run(2);

    assert(all(simulation.m_log.run.dtk_prev(1, :) == 0));
    assert(isequal(simulation.m_log.run.dtk_prev(2, :), ...
        simulation.m_log.run.dtk(1, :)));
end
