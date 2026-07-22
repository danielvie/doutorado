function comparison = compare_patino2_linearizations(nsim, make_plot)
    % Compare PATINO_2 MPC runs using both cycle linearization derivations.

    if nargin < 1
        nsim = 8;
    end
    if nargin < 2
        make_plot = true;
    end

    direct = run_case(Enums.LinearizationMethod.SWITCHING_TIME, nsim);
    augmented = run_case(Enums.LinearizationMethod.AUGMENTED_DURATION, nsim);

    comparison = struct();
    comparison.Phi_error = max_abs_difference( ...
        direct.cycle_model.Phi, augmented.cycle_model.Phi);
    comparison.Gamma_error = max_abs_difference( ...
        direct.cycle_model.Gamma, augmented.cycle_model.Gamma);
    comparison.state_error = max_abs_difference(direct.y, augmented.y);
    state_scale = max(1, max(abs(direct.y(:))));
    comparison.relative_state_error = comparison.state_error / state_scale;
    comparison.time_error = max_abs_difference(direct.t, augmented.t);
    comparison.control_error = max_abs_difference(direct.delta_t, augmented.delta_t);
    comparison.same_modes = isequal(direct.m, augmented.m);
    comparison.same_exitflags = isequal(direct.exitflags, augmented.exitflags);
    comparison.direct = direct;
    comparison.augmented = augmented;

    fprintf('PATINO_2 linearization comparison (%d cycles)\n', nsim);
    fprintf('  max |Phi direct - Phi augmented|       = %.3e\n', comparison.Phi_error);
    fprintf('  max |Gamma direct - Gamma augmented|   = %.3e\n', comparison.Gamma_error);
    fprintf('  max |state trajectory difference|      = %.3e\n', comparison.state_error);
    fprintf('  relative state trajectory difference   = %.3e\n', comparison.relative_state_error);
    fprintf('  max |time trajectory difference|       = %.3e\n', comparison.time_error);
    fprintf('  max |control difference|               = %.3e\n', comparison.control_error);
    fprintf('  same modes                              = %d\n', comparison.same_modes);
    fprintf('  same controller exit flags              = %d\n', comparison.same_exitflags);

    assert(any(abs(direct.delta_t(:)) > 0), ...
        'MPC did not produce an active switching-time perturbation.');
    assert(comparison.Phi_error < 1e-10);
    assert(comparison.Gamma_error < 1e-9);
    assert(comparison.relative_state_error < 1e-8);
    assert(comparison.time_error < 1e-9);
    assert(comparison.control_error < 1e-9);
    assert(comparison.same_modes);
    assert(comparison.same_exitflags);

    if make_plot
        plot_comparison(direct, augmented);
    end
end

function result = run_case(method, nsim)
    simulation = Simulation(Enums.SimName.PATINO_2);
    options = Options.Mpc();
    options.Nd = 1;
    options.Np = 2;
    options.Q = eye(3);
    options.linearization_method = method;
    simulation.set_mpc(options);

    simulation.m_config.x0 = [7.51; 20.82; 0.03];
    [y, t, m, delta_t] = simulation.run(nsim);

    result = struct();
    result.method = method;
    result.cycle_model = simulation.m_config.mpc.cycle_model;
    result.y = y;
    result.t = t;
    result.m = m;
    result.delta_t = delta_t;
    result.exitflags = simulation.m_log.run.exitflag;
end

function difference = max_abs_difference(left, right)
    difference = max(abs(left(:) - right(:)));
end

function plot_comparison(direct, augmented)
    direct_name = 'Switching-time derivation';
    augmented_name = 'Augmented-duration derivation';

    figure('Name', 'PATINO 2 linearization states');
    state_labels = {'v_{C1} [V]', 'v_{C2} [V]', 'i_L [A]'};
    for state = 1:3
        subplot(3, 1, state);
        plot(direct.t, direct.y(:, state), 'b-', ...
            augmented.t, augmented.y(:, state), 'r--', ...
            'LineWidth', 1.2);
        ylabel(state_labels{state});
        grid on;
        if state == 1
            legend(direct_name, augmented_name, 'Location', 'best');
        end
    end
    xlabel('Time [s]');

    figure('Name', 'PATINO 2 linearization command signals');
    action_count = size(direct.delta_t, 1);
    subplot(action_count + 1, 1, 1);
    stairs(direct.t, direct.m, 'b-', 'LineWidth', 1.2);
    hold on;
    stairs(augmented.t, augmented.m, 'r--', 'LineWidth', 1.2);
    hold off;
    ylabel('Mode');
    grid on;
    legend(direct_name, augmented_name, 'Location', 'best');

    cycle = 1:size(direct.delta_t, 2);
    for action = 1:action_count
        subplot(action_count + 1, 1, action + 1);
        stairs(cycle, direct.delta_t(action, :), 'b-', 'LineWidth', 1.2);
        hold on;
        stairs(cycle, augmented.delta_t(action, :), 'r--', 'LineWidth', 1.2);
        hold off;
        ylabel(sprintf('\\delta t_%d [s]', action));
        grid on;
    end
    xlabel('Cycle');

    figure('Name', 'PATINO 2 linearization state trajectory');
    plot3(direct.y(:, 1), direct.y(:, 2), direct.y(:, 3), ...
        'b-', 'LineWidth', 1.5);
    hold on;
    plot3(augmented.y(:, 1), augmented.y(:, 2), augmented.y(:, 3), ...
        'r--', 'LineWidth', 1.5);
    hold off;
    xlabel('v_{C1} [V]');
    ylabel('v_{C2} [V]');
    zlabel('i_L [A]');
    grid on;
    legend(direct_name, augmented_name, 'Location', 'best');
    view(3);

    % Flush deferred graphics before returning to an interactive MATLAB REPL.
    drawnow;
end
