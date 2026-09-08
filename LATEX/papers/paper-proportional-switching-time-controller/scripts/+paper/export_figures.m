function export_figures(paths, benchmark, model, response)
%EXPORT_FIGURES Reference and response figures plus a first-cycle diagnostic.
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 9);
set(groot, 'defaultLineLineWidth', 1.2);

[orbit_time, orbit_state] = sample_orbit(benchmark.config, benchmark.orbit_anchor, 80);
figure_reference(paths.article_figures, benchmark.config, orbit_time, orbit_state, ...
    model.cycle_average_state);
figure_first_cycle_conditioning(paths.diagnostic_figures, benchmark.config.Ts(:), ...
    response.raw_offsets(:, 1), response.applied_offsets(:, 1), response.raw_dwell(:, 1), ...
    response.applied_dwell(:, 1), response.conditioning_beta(1), benchmark.applied_schedule_dwell_bound);
figure_conditioned_response(paths.diagnostic_figures, response.conditioned_error, response.conservative_error, ...
    response.open_loop_error, response.conditioning_beta, response.raw_offsets, response.applied_offsets, ...
    response.raw_dwell, response.applied_dwell, benchmark.applied_schedule_dwell_bound);
copyfile(fullfile(paths.diagnostic_figures, 'conditioned_control_response.pdf'), ...
    fullfile(paths.article_figures, 'conditioned_control_response.pdf'));
end

function [time, state] = sample_orbit(config, orbit_anchor, samples_per_interval)
    state_count = numel(orbit_anchor);
    sample_count = numel(config.Omega) * samples_per_interval + 1;
    time = zeros(sample_count, 1);
    state = zeros(sample_count, state_count);
    state(1, :) = orbit_anchor(:)';
    cursor = 1;
    interval_start_state = orbit_anchor(:);
    for interval = 1:numel(config.Omega)
        mode = config.Omega(interval);
        duration = config.Ts(interval + 1) - config.Ts(interval);
        generator = [config.A{mode}, config.b{mode}; ...
            zeros(1, state_count + 1)];
        for sample = 1:samples_per_interval
            cursor = cursor + 1;
            local_time = duration * sample / samples_per_interval;
            augmented_state = expm(generator * local_time) * ...
                [interval_start_state; 1];
            time(cursor) = config.Ts(interval) + local_time;
            state(cursor, :) = augmented_state(1:state_count)';
        end
        interval_start_state = state(cursor, :)';
    end
end

function figure_reference(figures_dir, config, time, state, average_state)
    labels = {'$v_{C_1}$ (V)', '$v_{C_2}$ (V)', '$i_L$ (A)'};
    colors = [0.00, 0.35, 0.70; 0.75, 0.20, 0.15; 0.25, 0.55, 0.30];
    fig = figure('Visible', 'off', 'Position', [100, 100, 720, 650]);
    layout = tiledlayout(4, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    stairs(config.Ts(:) * 1e6, ...
        [config.Omega(:) - 1; config.Omega(end) - 1], 'k');
    ylabel('Mode');
    yticks(unique(config.Omega(:) - 1));
    title('Three-cell converter reference schedule: T = 286 us', ...
        'Interpreter', 'none', 'FontWeight', 'normal');
    grid on;

    for index = 1:3
        nexttile;
        orbit_handle = plot(time * 1e6, state(:, index), ...
            'Color', colors(index, :));
        hold on;
        average_handle = yline(average_state(index), '--k');
        for boundary = config.Ts(2:end-1)
            xline(boundary * 1e6, ':', 'Color', [0.55, 0.55, 0.55]);
        end
        ylabel(labels{index}, 'Interpreter', 'latex');
        grid on;
        if index == 1
            legend([orbit_handle, average_handle], ...
                {'Nominal orbit', 'Cycle average'}, 'Location', 'best');
        end
    end
    xlabel(layout, 'Time ($\mu$s)', 'Interpreter', 'latex');
    exportgraphics(fig, fullfile(figures_dir, ...
        'reference_schedule_orbit.pdf'), 'ContentType', 'vector');
    close(fig);
end

function figure_first_cycle_conditioning(figures_dir, nominal_boundaries, ...
        raw_offsets, applied_offsets, raw_dwell, applied_dwell, beta, dwell_bound)
    boundary_index = 0:(numel(nominal_boundaries) - 1);
    nominal_boundary_us = nominal_boundaries(:) * 1e6;
    raw_boundary_us = (nominal_boundaries(:) + [0; raw_offsets(:); 0]) * 1e6;
    applied_boundary_us = ...
        (nominal_boundaries(:) + [0; applied_offsets(:); 0]) * 1e6;
    [~, inverted_interval] = min(raw_dwell);
    inverted_boundaries = inverted_interval:(inverted_interval + 1);
    colors = [0.00, 0.35, 0.70; 0.75, 0.20, 0.15; 0.20, 0.20, 0.20];

    fig = figure('Visible', 'off', 'Position', [100, 100, 780, 360]);
    layout = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(boundary_index, nominal_boundary_us, ':o', ...
        'Color', colors(3, :), 'MarkerSize', 4); hold on;
    plot(boundary_index, raw_boundary_us, '--o', ...
        'Color', colors(2, :), 'MarkerSize', 4);
    plot(boundary_index, applied_boundary_us, '-s', ...
        'Color', colors(1, :), 'MarkerSize', 4);
    plot(boundary_index(inverted_boundaries), ...
        raw_boundary_us(inverted_boundaries), '-', ...
        'Color', colors(2, :), 'LineWidth', 2.5, ...
        'HandleVisibility', 'off');
    text(mean(boundary_index(inverted_boundaries)), ...
        mean(raw_boundary_us(inverted_boundaries)), '  inversion', ...
        'Color', colors(2, :), 'FontSize', 8);
    xlabel('Cycle-boundary index');
    ylabel('Cycle-relative boundary time ($\mu$s)', 'Interpreter', 'latex');
    title('(a) Boundary ordering', 'FontWeight', 'normal');
    legend('Nominal', 'Raw candidate', 'Applied', 'Location', 'northwest');
    grid on;

    nexttile;
    dwell_bars = bar(1:numel(raw_dwell), ...
        [raw_dwell(:), applied_dwell(:)] * 1e6, 'grouped'); hold on;
    dwell_bars(1).FaceColor = colors(2, :);
    dwell_bars(2).FaceColor = colors(1, :);
    yline(dwell_bound * 1e6, ':k', '3 $\mu$s bound', ...
        'Interpreter', 'latex');
    yline(0, '-k', 'HandleVisibility', 'off');
    xlabel('Mode interval');
    ylabel('Dwell duration ($\mu$s)', 'Interpreter', 'latex');
    title('(b) Nine dwell durations', 'FontWeight', 'normal');
    legend('Raw candidate', 'Applied', 'Location', 'best');
    grid on;

    title(layout, sprintf( ...
        'First-cycle dwell-time conditioning (beta = %.3f)', beta), ...
        'Interpreter', 'none', 'FontWeight', 'normal');
    exportgraphics(fig, fullfile(figures_dir, ...
        'first_cycle_conditioning.pdf'), 'ContentType', 'vector');
    close(fig);
end

function figure_conditioned_response(figures_dir, conditioned_error, ...
        conservative_error, open_error, beta, raw_offsets, applied_offsets, ...
        raw_dwell, applied_dwell, dwell_bound)
    cycles = 0:(numel(conditioned_error) - 1);
    action_cycles = 0:(numel(beta) - 1);
    shown_cycle = min(25, cycles(end));
    colors = [0.00, 0.35, 0.70; 0.75, 0.20, 0.15; 0.25, 0.55, 0.30];
    fig = figure('Visible', 'off', 'Position', [100, 100, 780, 540]);
    layout = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    semilogy(cycles, conditioned_error, 'Color', colors(1, :)); hold on;
    semilogy(cycles, conservative_error, '-.', 'Color', colors(3, :));
    semilogy(cycles, open_error, '--', 'Color', colors(2, :));
    yline(0.01, ':k', '0.01');
    xlim([0, shown_cycle]);
    ylabel('$\|S_x^{-1}e_k\|_2$', 'Interpreter', 'latex');
    title('(a) Exact cycle-start error', 'FontWeight', 'normal');
    legend('Conditioned aggressive', 'Conservative', 'Open loop', ...
        'Location', 'best');
    grid on;

    nexttile;
    stairs(action_cycles, beta, 'Color', colors(1, :));
    xlim([0, shown_cycle]);
    ylim([0, 1.05]);
    ylabel('$\beta_k$', 'Interpreter', 'latex');
    title('(b) Uniform conditioning factor', 'FontWeight', 'normal');
    grid on;

    nexttile;
    plot(action_cycles, max(abs(raw_offsets), [], 1) * 1e6, '--', ...
        'Color', colors(2, :)); hold on;
    plot(action_cycles, max(abs(applied_offsets), [], 1) * 1e6, ...
        'Color', colors(1, :));
    xlim([0, shown_cycle]);
    ylabel('Maximum absolute offset ($\mu$s)', 'Interpreter', 'latex');
    title('(c) Candidate and applied action', 'FontWeight', 'normal');
    legend('Raw', 'Applied', 'Location', 'best');
    grid on;

    nexttile;
    plot(action_cycles, min(raw_dwell, [], 1) * 1e6, '--', ...
        'Color', colors(2, :)); hold on;
    plot(action_cycles, min(applied_dwell, [], 1) * 1e6, ...
        'Color', colors(1, :));
    yline(dwell_bound * 1e6, ':k', '3 $\mu$s bound', ...
        'Interpreter', 'latex');
    xlim([0, shown_cycle]);
    ylabel('Minimum dwell ($\mu$s)', 'Interpreter', 'latex');
    title('(d) Candidate and applied dwell', 'FontWeight', 'normal');
    legend('Raw', 'Applied', 'Location', 'best');
    grid on;

    title(layout, 'Three-cell converter: conditioned large-error response', ...
        'Interpreter', 'none', 'FontWeight', 'normal');
    xlabel(layout, 'Cycle');
    exportgraphics(fig, fullfile(figures_dir, ...
        'conditioned_control_response.pdf'), 'ContentType', 'vector');
    close(fig);
end
