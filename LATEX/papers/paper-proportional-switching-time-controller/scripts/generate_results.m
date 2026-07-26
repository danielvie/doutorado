% Generate the figures and scalar results used by article.tex.
% Run from the article root with: matlab -batch "run('scripts/generate_results.m')"

article_dir = fileparts(fileparts(mfilename('fullpath')));
simulation_dir = fullfile(article_dir, '..', '..', '..', 'simulations', 'matlab-sim');
addpath(simulation_dir);

figures_dir = fullfile(article_dir, 'figures');
results_dir = fullfile(article_dir, 'results');
if ~isfolder(figures_dir), mkdir(figures_dir); end
if ~isfolder(results_dir), mkdir(results_dir); end

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 9);
set(groot, 'defaultLineLineWidth', 1.2);

simulation = Simulation(Enums.SimName.PATINO_2);
target_orbit_state = simulation.m_config.x0;

options = Options.Mpc();
options.Nd = 1;
options.Np = 2;
options.Q = eye(3);
simulation.set_mpc(options);

[Phi, Gamma] = simulation.get_phi_gamma();
K = simulation.get_gain_k();
minimum_dwell_us = 3;
controller = Controllers.Proportional( ...
    K, 1, simulation.get_time_us(), minimum_dwell_us);
simulation.set_controller(controller);

dwell_change_map = build_dwell_change_map(size(K, 1));
nominal_dwell = simulation.get_time_us()' * 1e-6;
minimum_dwell = minimum_dwell_us * 1e-6;
admissible_matrix = dwell_change_map * K;
admissible_bound = nominal_dwell - minimum_dwell;
admissible_region = Polyhedron( ...
    'A', admissible_matrix, 'b', admissible_bound);
closed_loop = Phi - Gamma * K;
invariant_region = LTISystem('A', closed_loop).invariantSet( ...
    'X', admissible_region);
admissible_region.minHRep();
invariant_region.minHRep();
spectral_radius = max(abs(eig(closed_loop)));
regions_coincide = polyhedra_equal( ...
    admissible_region, invariant_region, 1e-9);

assert(admissible_region.isBounded() && admissible_region.isFullDim(), ...
    'The raw-action admissible region must be bounded and full-dimensional.');
assert(invariant_region.isBounded() && invariant_region.isFullDim(), ...
    'The invariant region must be bounded and full-dimensional.');
assert(spectral_radius < 1, ...
    'The unconditioned linear closed loop is not Schur stable.');
assert(regions_coincide, ...
    'The invariant region no longer coincides with the admissible region.');

cycles = 80;
initial_state = [7.51; 20.82; 0.03];
simulation.m_config.x0 = initial_state;
simulation.set_control_enabled(true);
[y_controlled, t_controlled, ~, dtk_controlled] = simulation.run(cycles);
log_controlled = simulation.m_log.run;
cycle_errors = log_controlled.ek;
raw_actions = -K * cycle_errors';
inside_admissible_region = all( ...
    admissible_matrix * cycle_errors' <= admissible_bound + 1e-12, 1)';
conditioning_active = vecnorm(raw_actions - dtk_controlled, 2, 1)' > 1e-12;
first_admissible_cycle = find(inside_admissible_region, 1, 'first');
conditioned_cycles = sum(conditioning_active);

assert(~isempty(first_admissible_cycle), ...
    'The controlled trajectory never enters the admissible region.');
assert(all(inside_admissible_region(first_admissible_cycle:end)), ...
    'The controlled trajectory leaves the admissible region after entering it.');
assert(isequal(conditioning_active, ~inside_admissible_region), ...
    'Conditioning activity does not match raw-action feasibility.');

simulation.m_config.x0 = initial_state;
simulation.set_control_enabled(false);
[y_open, t_open] = simulation.run(cycles);
log_open = simulation.m_log.run;

state_scale = [10, 20, 1];
initial_error = normalized_error(initial_state', target_orbit_state', state_scale);
controlled_error = normalized_error( ...
    log_controlled.x0, target_orbit_state', state_scale);
open_error = normalized_error(log_open.x0, target_orbit_state', state_scale);
controlled_reduction = 100 * (1 - controlled_error(end) / initial_error);
open_reduction = 100 * (1 - open_error(end) / initial_error);
dwell_controlled_us = diff(log_controlled.ts, 1, 2) * 1e6;
minimum_observed_dwell = min(dwell_controlled_us, [], 'all');
maximum_perturbation = max(abs(dtk_controlled), [], 'all') * 1e6;

assert(controlled_error(end) < initial_error, ...
    'The proportional controller did not reduce the normalized error.');
assert(minimum_observed_dwell >= minimum_dwell_us - 1e-9, ...
    'The generated switching schedule violates the dwell-time bound.');

write_metrics(results_dir, initial_error, controlled_error(end), ...
    open_error(end), controlled_reduction, open_reduction, ...
    minimum_observed_dwell, maximum_perturbation, cycles, ...
    spectral_radius, first_admissible_cycle, conditioned_cycles);
write_gain(results_dir, K, Phi, Gamma);
write_region_data(results_dir, dwell_change_map, admissible_matrix, ...
    admissible_bound, closed_loop, admissible_region, invariant_region);

figure_states(figures_dir, t_controlled, y_controlled, t_open, y_open, ...
    target_orbit_state);
figure_error(figures_dir, controlled_error, open_error, initial_error);
figure_timing(figures_dir, dtk_controlled, dwell_controlled_us, ...
    minimum_dwell_us);
figure_trajectory(figures_dir, y_controlled, y_open, target_orbit_state, ...
    initial_state);
figure_constraint_region_views(figures_dir, invariant_region, cycle_errors, ...
    first_admissible_cycle);

fprintf('Generated article results in %s\n', article_dir);
fprintf('Initial normalized error: %.6f\n', initial_error);
fprintf('Final controlled normalized error: %.6f\n', controlled_error(end));
fprintf('Final open-loop normalized error: %.6f\n', open_error(end));
fprintf('Minimum observed dwell interval: %.3f us\n', minimum_observed_dwell);
fprintf('Closed-loop spectral radius: %.3e\n', spectral_radius);
fprintf('First cycle in admissible region: %d\n', first_admissible_cycle);
fprintf('Cycles with active conditioning: %d\n', conditioned_cycles);

function value = normalized_error(state, target, scale)
    value = vecnorm((state - target) ./ scale, 2, 2);
end

function write_metrics(results_dir, initial_error, controlled_final, ...
    open_final, controlled_reduction, open_reduction, minimum_dwell, ...
    maximum_perturbation, cycles, spectral_radius, ...
    first_admissible_cycle, conditioned_cycles)
    path = fullfile(results_dir, 'metrics.tex');
    file = fopen(path, 'w');
    assert(file ~= -1, 'Could not write %s', path);
    cleanup = onCleanup(@() fclose(file));
    fprintf(file, '%% Generated by scripts/generate_results.m.\n');
    fprintf(file, '\\newcommand{\\SimulationCycles}{%d}\n', cycles);
    fprintf(file, '\\newcommand{\\InitialNormalizedError}{%.4f}\n', initial_error);
    fprintf(file, '\\newcommand{\\ControlledFinalError}{%.4f}\n', controlled_final);
    fprintf(file, '\\newcommand{\\OpenLoopFinalError}{%.4f}\n', open_final);
    fprintf(file, '\\newcommand{\\ControlledErrorReduction}{%.1f\\%%}\n', controlled_reduction);
    fprintf(file, '\\newcommand{\\OpenLoopErrorReduction}{%.1f\\%%}\n', open_reduction);
    fprintf(file, '\\newcommand{\\MinimumObservedDwell}{%.1f}\n', minimum_dwell);
    fprintf(file, '\\newcommand{\\MaximumPerturbation}{%.1f}\n', maximum_perturbation);
    exponent = floor(log10(spectral_radius));
    mantissa = spectral_radius / 10^exponent;
    fprintf(file, ...
        '\\newcommand{\\ClosedLoopSpectralRadius}{%.2f\\times10^{%d}}\n', ...
        mantissa, exponent);
    fprintf(file, '\\newcommand{\\FirstAdmissibleCycle}{%d}\n', ...
        first_admissible_cycle);
    fprintf(file, '\\newcommand{\\ConditionedCycles}{%d}\n', conditioned_cycles);

    csv_path = fullfile(results_dir, 'metrics.csv');
    writetable(table(initial_error, controlled_final, open_final, ...
        controlled_reduction, open_reduction, minimum_dwell, ...
        maximum_perturbation, cycles, spectral_radius, ...
        first_admissible_cycle, conditioned_cycles), csv_path);
end

function write_gain(results_dir, K, Phi, Gamma)
    save(fullfile(results_dir, 'linear_model.mat'), 'K', 'Phi', 'Gamma');
    writematrix(K, fullfile(results_dir, 'gain_matrix.csv'));
end

function write_region_data(results_dir, dwell_change_map, ...
    admissible_matrix, admissible_bound, closed_loop, ...
    admissible_region, invariant_region)
    admissible_vertices = admissible_region.V;
    invariant_vertices = invariant_region.V;
    save(fullfile(results_dir, 'constraint_regions.mat'), ...
        'dwell_change_map', 'admissible_matrix', 'admissible_bound', ...
        'closed_loop', 'admissible_vertices', 'invariant_vertices');
    writematrix(admissible_vertices, ...
        fullfile(results_dir, 'admissible_region_vertices.csv'));
    writematrix(invariant_vertices, ...
        fullfile(results_dir, 'invariant_region_vertices.csv'));
end

function figure_states(figures_dir, tc, yc, to, yo, target)
    fig = figure('Visible', 'off', 'Position', [100, 100, 720, 600]);
    labels = {'$v_{C_1}$ (V)', '$v_{C_2}$ (V)', '$i_L$ (A)'};
    layout = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    for state = 1:3
        nexttile;
        plot(tc * 1e3, yc(:, state), 'Color', [0.00, 0.35, 0.70]); hold on;
        plot(to * 1e3, yo(:, state), '--', 'Color', [0.75, 0.20, 0.15]);
        yline(target(state), ':k');
        ylabel(labels{state}, 'Interpreter', 'latex');
        grid on;
        if state == 1
            legend('Controlled', 'Open loop', 'Cycle-boundary target', ...
                'Location', 'best');
        end
    end
    xlabel(layout, 'Time (ms)', 'Interpreter', 'latex');
    exportgraphics(fig, fullfile(figures_dir, 'state_response.pdf'), ...
        'ContentType', 'vector');
    close(fig);
end

function figure_error(figures_dir, controlled, open_loop, initial)
    fig = figure('Visible', 'off', 'Position', [100, 100, 720, 360]);
    semilogy(1:numel(controlled), controlled, ...
        'Color', [0.00, 0.35, 0.70]); hold on;
    semilogy(1:numel(open_loop), open_loop, '--', ...
        'Color', [0.75, 0.20, 0.15]);
    yline(0.05 * initial, ':k', '5% of initial error');
    xlabel('Cycle');
    ylabel('Normalized cycle-to-cycle error');
    legend('Controlled', 'Open loop', 'Location', 'best');
    grid on;
    exportgraphics(fig, fullfile(figures_dir, 'cycle_error.pdf'), ...
        'ContentType', 'vector');
    close(fig);
end

function figure_timing(figures_dir, dtk, dwell, minimum_dwell)
    shown_cycles = min(20, size(dtk, 2));
    fig = figure('Visible', 'off', 'Position', [100, 100, 720, 520]);
    layout = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(1:shown_cycles, dtk(:, 1:shown_cycles)' * 1e6);
    ylabel('Perturbation ($\\mu$s)', 'Interpreter', 'latex');
    grid on;

    nexttile;
    plot(1:shown_cycles, min(dwell(1:shown_cycles, :), [], 2), ...
        'Color', [0.00, 0.35, 0.70]); hold on;
    yline(minimum_dwell, '--k', 'Minimum dwell time');
    ylabel('Shortest dwell interval ($\\mu$s)', 'Interpreter', 'latex');
    xlabel(layout, 'Cycle');
    grid on;

    exportgraphics(fig, fullfile(figures_dir, 'timing_action.pdf'), ...
        'ContentType', 'vector');
    close(fig);
end



function figure_constraint_region_views(figures_dir, region, errors, ...
    first_admissible_cycle)
    fig = figure('Visible', 'off', 'Position', [100, 100, 900, 700]);
    layout = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    vertices = region.V;
    labels = {'$e_{v_{C_1}}$ (V)', '$e_{v_{C_2}}$ (V)', '$e_{i_L}$ (A)'};

    nexttile;
    plot_region_projection(vertices, errors, first_admissible_cycle, ...
        [1, 2], labels, 'XY');

    nexttile;
    plot_region_projection(vertices, errors, first_admissible_cycle, ...
        [1, 3], labels, 'XZ');

    nexttile;
    plot_region_projection(vertices, errors, first_admissible_cycle, ...
        [2, 3], labels, 'YZ');

    nexttile;
    facets = convhulln(vertices);
    region_handle = trisurf(facets, vertices(:, 1), vertices(:, 2), ...
        vertices(:, 3), 'FaceColor', [0.20, 0.55, 0.75], ...
        'FaceAlpha', 0.24, 'EdgeColor', 'none');
    hold on;
    plot_polyhedron_edges(vertices, facets, [0.08, 0.28, 0.42]);
    trajectory_handle = plot3(errors(:, 1), errors(:, 2), errors(:, 3), ...
        '-o', 'Color', [0.75, 0.20, 0.15], 'MarkerSize', 2.2, ...
        'MarkerFaceColor', [0.75, 0.20, 0.15]);
    initial_handle = scatter3(errors(1, 1), errors(1, 2), errors(1, 3), ...
        36, 'k', 'filled');
    entry_error = errors(first_admissible_cycle, :);
    entry_handle = scatter3(entry_error(1), entry_error(2), entry_error(3), ...
        48, [0.95, 0.65, 0.10], 'filled', 'MarkerEdgeColor', 'k');
    origin_handle = scatter3(0, 0, 0, 54, 'p', 'MarkerFaceColor', ...
        [0.25, 0.65, 0.35], 'MarkerEdgeColor', 'k');
    xlabel(labels{1}, 'Interpreter', 'latex');
    ylabel(labels{2}, 'Interpreter', 'latex');
    zlabel(labels{3}, 'Interpreter', 'latex');
    title('XYZ');
    grid on;
    axis vis3d;
    camproj('perspective');
    view(132, 24);
    legend([region_handle, trajectory_handle, initial_handle, ...
        entry_handle, origin_handle], ...
        {'$\mathcal C=\mathcal C_\infty$', 'Cycle-start error', ...
        'Initial error', 'First admissible cycle', 'Origin'}, ...
        'Interpreter', 'latex', 'FontSize', 7, 'Location', 'best');

    exportgraphics(fig, fullfile(figures_dir, ...
        'constraint_admissible_region_views.pdf'), ...
        'ContentType', 'image', 'Resolution', 300);
    close(fig);
end

function plot_region_projection(vertices, errors, first_admissible_cycle, ...
    dimensions, labels, view_name)
    first_coordinate = vertices(:, dimensions(1));
    second_coordinate = vertices(:, dimensions(2));
    hull = convhull(first_coordinate, second_coordinate);
    fill(first_coordinate(hull), second_coordinate(hull), ...
        [0.20, 0.55, 0.75], 'FaceAlpha', 0.24, ...
        'EdgeColor', [0.08, 0.28, 0.42], 'LineWidth', 0.9);
    hold on;
    plot(errors(:, dimensions(1)), errors(:, dimensions(2)), '-o', ...
        'Color', [0.75, 0.20, 0.15], 'MarkerSize', 2.2, ...
        'MarkerFaceColor', [0.75, 0.20, 0.15]);
    scatter(errors(1, dimensions(1)), errors(1, dimensions(2)), ...
        36, 'k', 'filled');
    entry_error = errors(first_admissible_cycle, :);
    scatter(entry_error(dimensions(1)), entry_error(dimensions(2)), ...
        48, [0.95, 0.65, 0.10], 'filled', 'MarkerEdgeColor', 'k');
    scatter(0, 0, 54, 'p', 'MarkerFaceColor', [0.25, 0.65, 0.35], ...
        'MarkerEdgeColor', 'k');
    xlabel(labels{dimensions(1)}, 'Interpreter', 'latex');
    ylabel(labels{dimensions(2)}, 'Interpreter', 'latex');
    title(view_name);
    grid on;
    axis tight;
end

function figure_trajectory(figures_dir, controlled, open_loop, target, initial)
    fig = figure('Visible', 'off', 'Position', [100, 100, 680, 520]);
    plot3(controlled(:, 1), controlled(:, 2), controlled(:, 3), ...
        'Color', [0.00, 0.35, 0.70]); hold on;
    plot3(open_loop(:, 1), open_loop(:, 2), open_loop(:, 3), '--', ...
        'Color', [0.75, 0.20, 0.15]);
    plot3(initial(1), initial(2), initial(3), 'ko', ...
        'MarkerFaceColor', 'k');
    plot3(target(1), target(2), target(3), 'kp', ...
        'MarkerSize', 10, 'MarkerFaceColor', [0.95, 0.75, 0.10]);
    xlabel('$v_{C_1}$ (V)', 'Interpreter', 'latex');
    ylabel('$v_{C_2}$ (V)', 'Interpreter', 'latex');
    zlabel('$i_L$ (A)', 'Interpreter', 'latex');
    legend('Controlled', 'Open loop', 'Initial state', ...
        'Cycle-boundary target', 'Location', 'northoutside', ...
        'Orientation', 'horizontal');
    grid on;
    view(42, 24);
    exportgraphics(fig, fullfile(figures_dir, 'state_trajectory.pdf'), ...
        'ContentType', 'vector');
    close(fig);
end

function map = build_dwell_change_map(action_count)
    map = zeros(action_count + 1, action_count);
    map(1, 1) = 1;
    for interval = 2:action_count
        map(interval, interval - 1) = -1;
        map(interval, interval) = 1;
    end
    map(end, end) = -1;
end

function result = polyhedra_equal(first, second, tolerance)
    first_inside_second = all( ...
        second.A * first.V' <= second.b + tolerance, 'all');
    second_inside_first = all( ...
        first.A * second.V' <= first.b + tolerance, 'all');
    result = first_inside_second && second_inside_first;
end

function plot_polyhedron_edges(vertices, facets, color)
    triangle_edges = [facets(:, [1, 2]); facets(:, [2, 3]); facets(:, [3, 1])];
    triangle_edges = sort(triangle_edges, 2);
    facet_index = repmat((1:size(facets, 1))', 3, 1);
    [candidate_edges, ~, edge_group] = unique(triangle_edges, 'rows');

    normals = cross( ...
        vertices(facets(:, 2), :) - vertices(facets(:, 1), :), ...
        vertices(facets(:, 3), :) - vertices(facets(:, 1), :), 2);
    normals = normals ./ vecnorm(normals, 2, 2);

    for edge = 1:size(candidate_edges, 1)
        adjacent_facets = facet_index(edge_group == edge);
        adjacent_normals = normals(adjacent_facets, :);
        is_boundary_edge = any( ...
            abs(adjacent_normals * adjacent_normals(1, :)') < 1 - 1e-8);
        if ~is_boundary_edge
            continue;
        end
        endpoints = vertices(candidate_edges(edge, :), :);
        plot3(endpoints(:, 1), endpoints(:, 2), endpoints(:, 3), ...
            'Color', color, 'LineWidth', 0.9);
    end
end
