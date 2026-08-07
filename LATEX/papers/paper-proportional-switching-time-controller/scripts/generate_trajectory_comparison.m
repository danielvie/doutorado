% Generate standalone controller ON/OFF trajectory comparisons.
% Run from the article root with:
% matlab -batch "run('scripts/generate_trajectory_comparison.m')"

article_dir = fileparts(fileparts(mfilename('fullpath')));
simulation_dir = fullfile(article_dir, '..', '..', '..', ...
    'simulations', 'matlab-sim');
addpath(simulation_dir);
addpath(fullfile(article_dir, 'scripts'));

output_dir = fullfile(article_dir, 'comparison');
if ~isfolder(output_dir), mkdir(output_dir); end
output_pdf = fullfile(output_dir, 'trajectory_comparison.pdf');
open_loop_output_pdf = fullfile(output_dir, 'open_loop_convergence.pdf');
open_loop_trajectory_output_pdf = fullfile(output_dir, ...
    'open_loop_trajectory_convergence.pdf');
open_loop_states_output_pdf = fullfile(output_dir, ...
    'open_loop_states_over_time.pdf');
if isfile(output_pdf), delete(output_pdf); end
if isfile(open_loop_output_pdf), delete(open_loop_output_pdf); end
if isfile(open_loop_trajectory_output_pdf), delete(open_loop_trajectory_output_pdf); end
if isfile(open_loop_states_output_pdf), delete(open_loop_states_output_pdf); end

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 9);
set(groot, 'defaultLineLineWidth', 1.1);

%% Three-cell converter benchmark and normalized LQR
simulation = Simulation(Enums.SimName.PATINO_2);
config = simulation.m_config;
dynamics_indices = [1, 2, 4, 8, 3, 1, 5, 8, 5];
published_modes = [0, 1, 3, 7, 2, 0, 4, 7, 4];
corrected_boundary_us = [0, 63.889183506119, 87.556782881998, ...
    109.556782881998, 132.538059851499, 154.538059851499, ...
    218.210068109424, 240.380157440049, 263.827584831201, 286];
published_boundary_us = [0, 66, 88, 110, 132, 154, 220, 242, 264, 286];
published_anchor = [9.9247; 19.2928; 0.9823];
benchmark_design_dwell_bound = 22e-6;
applied_schedule_dwell_bound = 3e-6;
config.Omega = dynamics_indices;
config.Ts = corrected_boundary_us * 1e-6;
config.orbit_anchor = published_anchor;
config.x0 = published_anchor;
anchor = published_anchor;

assert(isequal(config.Omega(:)' - 1, published_modes), ...
    'The dynamics indices do not match the published physical modes.');
assert(numel(config.Omega) == 9 && numel(config.Ts) == 10, ...
    'The three-cell converter benchmark must contain exactly 9 intervals.');
assert(config.Ts(end) - config.Ts(1) == 286e-6, ...
    'The three-cell converter benchmark period must be exactly 286 us.');
assert(all(diff(corrected_boundary_us) >= 22), ...
    'A nominal benchmark dwell is below the 22 us design bound.');
assert(isequal(config.orbit_anchor(:), published_anchor) && ...
    isequal(config.x0(:), published_anchor), ...
    'Both benchmark initial-state fields must equal the published anchor.');
assert(max(abs(corrected_boundary_us - published_boundary_us)) > 0, ...
    'The comparison must use the closure-corrected boundaries.');

model = Dynamics.linearize_cycle(config);
nominal_closure_error = norm(model.orbit_states(:, end) - anchor, inf);
assert(nominal_closure_error < 1e-10, ...
    'The three-cell converter orbit does not close at the published anchor.');

state_scale = diag([10, 20, 1]);
timing_scale = 10e-6;
A_normalized = state_scale \ model.Phi * state_scale;
B_normalized = state_scale \ model.Gamma * timing_scale;
aggressive_input_weight = 0.001;
K_normalized = dlqr(A_normalized, B_normalized, ...
    eye(size(A_normalized)), ...
    aggressive_input_weight * eye(size(B_normalized, 2)));
K_physical = timing_scale * K_normalized / state_scale;

comparison_cycles = 100;
open_loop_check_cycles = 100000;
open_loop_convergence_tolerance = 1e-2;
samples_per_interval = 30;
% Large initial displacement used in the paper's conditioned-controller study.
initial_state = [7.5143; 20.8211; 0.0314];
initial_normalized_error = norm(state_scale \ (initial_state - anchor), 2);

[time_on, state_on, minimum_on_dwell, conditioning_factors, ...
    maximum_raw_offset, maximum_applied_offset] = simulate_dense_cycles( ...
    config, anchor, initial_state, K_physical, comparison_cycles, ...
    samples_per_interval, applied_schedule_dwell_bound);
[time_off, state_off, minimum_off_dwell] = simulate_dense_cycles( ...
    config, anchor, initial_state, zeros(size(K_physical)), ...
    comparison_cycles, samples_per_interval, applied_schedule_dwell_bound);
[reference_time, reference_state] = repeat_reference(config, anchor, ...
    comparison_cycles, samples_per_interval);

assert(all(isfinite(state_on), 'all') && all(isfinite(state_off), 'all'), ...
    'A trajectory comparison contains non-finite states.');
assert(norm(state_on(end, :)' - anchor) < norm(initial_state - anchor), ...
    'The controller-ON trajectory does not approach the cycle anchor.');
assert(all(conditioning_factors >= 0 & conditioning_factors <= 1), ...
    'A dwell-time conditioning factor is outside [0, 1].');

[open_loop_cycle_error, open_loop_convergence_cycle, ...
    open_loop_spectral_radius] = check_open_loop_convergence( ...
    model.Phi, state_scale, initial_state - anchor, ...
    open_loop_check_cycles, open_loop_convergence_tolerance);
conditioned_cycle_count = sum(conditioning_factors < 1 - 1e-12);
assert(conditioned_cycle_count > 0, ...
    'The aggressive comparison does not exercise the dwell-time conditioner.');

%% Page 1: continuous-time state responses
colors = [0.00, 0.35, 0.70; 0.75, 0.20, 0.15; 0.20, 0.20, 0.20];
labels = {'$v_{C_1}$ (V)', '$v_{C_2}$ (V)', '$i_L$ (A)'};
fig = figure('Visible', 'off', 'Position', [100, 100, 780, 650]);
layout = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
for state_index = 1:3
    nexttile;
    plot(time_on * 1e3, state_on(:, state_index), ...
        'Color', colors(1, :));
    hold on;
    plot(time_off * 1e3, state_off(:, state_index), '--', ...
        'Color', colors(2, :));
    plot(reference_time * 1e3, reference_state(:, state_index), ':', ...
        'Color', colors(3, :));
    ylabel(labels{state_index}, 'Interpreter', 'latex');
    grid on;
    if state_index == 1
        legend('Conditioned LQR', 'Open loop', 'Reference trajectory', ...
            'Location', 'best', 'NumColumns', 3);
    end
end
xlabel(layout, 'Time (ms)');
title(layout, sprintf(['Three-cell converter trajectory comparison ', ...
    'over %d cycles'], comparison_cycles), ...
    'Interpreter', 'none', 'FontWeight', 'normal');
exportgraphics(fig, output_pdf, 'ContentType', 'vector');
close(fig);

%% Page 2: switching-boundary state-space trajectories
interval_count = numel(config.Omega);
samples_per_cycle = interval_count * samples_per_interval;
boundary_indices = 1:samples_per_interval:size(state_on, 1);
boundary_on = state_on(boundary_indices, :);
boundary_off = state_off(boundary_indices, :);
reference_boundary_indices = 1:samples_per_interval:(samples_per_cycle + 1);
reference_boundary = reference_state(reference_boundary_indices, :);

marked_cycles = 0:10:comparison_cycles;
marked_boundary_indices = 1 + marked_cycles * interval_count;

fig = figure('Visible', 'off', 'Position', [100, 100, 700, 600]);
controlled_handle = plot3(boundary_on(:, 1), boundary_on(:, 2), ...
    boundary_on(:, 3), 'Color', colors(1, :));
hold on;
open_handle = plot3(boundary_off(:, 1), boundary_off(:, 2), ...
    boundary_off(:, 3), '--', 'Color', colors(2, :));
target_handle = plot3(reference_boundary(:, 1), reference_boundary(:, 2), ...
    reference_boundary(:, 3), ':', 'Color', colors(3, :), 'LineWidth', 2.0);
plot3(boundary_on(marked_boundary_indices, 1), ...
    boundary_on(marked_boundary_indices, 2), ...
    boundary_on(marked_boundary_indices, 3), 'o', ...
    'Color', colors(1, :), 'MarkerFaceColor', colors(1, :), ...
    'MarkerSize', 3, 'HandleVisibility', 'off');
plot3(boundary_off(marked_boundary_indices, 1), ...
    boundary_off(marked_boundary_indices, 2), ...
    boundary_off(marked_boundary_indices, 3), 'x', ...
    'Color', colors(2, :), 'MarkerSize', 4, 'HandleVisibility', 'off');
initial_handle = plot3(initial_state(1), initial_state(2), initial_state(3), ...
    'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
anchor_handle = plot3(anchor(1), anchor(2), anchor(3), 'kp', ...
    'MarkerFaceColor', [0.95, 0.75, 0.10], 'MarkerSize', 10);
xlabel('$v_{C_1}$ (V)', 'Interpreter', 'latex');
ylabel('$v_{C_2}$ (V)', 'Interpreter', 'latex');
zlabel('$i_L$ (A)', 'Interpreter', 'latex');
title('Three-cell converter switching-boundary trajectories', ...
    'Interpreter', 'none', 'FontWeight', 'normal');
legend([controlled_handle, open_handle, target_handle, ...
    initial_handle, anchor_handle], ...
    {'Conditioned LQR', 'Open loop', 'Target boundary polygon', ...
    'Initial state', 'Cycle anchor'}, 'Location', 'best');
grid on;
view(42, 24);
exportgraphics(fig, output_pdf, 'ContentType', 'vector', 'Append', true);
close(fig);

%% Long-horizon open-loop state-space trajectory
open_loop_plot_indices = convergence_plot_indices(open_loop_check_cycles, ...
    open_loop_convergence_cycle);
open_loop_anchor_states = sample_open_loop_anchors(model.Phi, anchor, ...
    initial_state, open_loop_plot_indices);
[~, final_cycle_state] = simulate_dense_cycles(config, anchor, ...
    open_loop_anchor_states(end, :)', zeros(size(K_physical)), 1, ...
    samples_per_interval, applied_schedule_dwell_bound);
fig = figure('Visible', 'off', 'Position', [100, 100, 700, 600]);
transient_handle = plot3(state_off(:, 1), state_off(:, 2), state_off(:, 3), ...
    '--', 'Color', colors(2, :));
hold on;
anchor_handle = scatter3(open_loop_anchor_states(:, 1), ...
    open_loop_anchor_states(:, 2), open_loop_anchor_states(:, 3), 12, ...
    [0.85, 0.55, 0.05], 'filled', 'MarkerFaceAlpha', 0.25, ...
    'MarkerEdgeAlpha', 0.10);
final_handle = plot3(final_cycle_state(:, 1), final_cycle_state(:, 2), ...
    final_cycle_state(:, 3), '--', 'Color', colors(1, :), 'LineWidth', 1.2);
plot3(reference_boundary(:, 1), reference_boundary(:, 2), ...
    reference_boundary(:, 3), '-', 'Color', 'w', 'LineWidth', 5.0, ...
    'HandleVisibility', 'off');
target_handle = plot3(reference_boundary(:, 1), reference_boundary(:, 2), ...
    reference_boundary(:, 3), '-', 'Color', colors(3, :), 'LineWidth', 3.0);
initial_handle = plot3(initial_state(1), initial_state(2), initial_state(3), ...
    'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
target_anchor_handle = plot3(anchor(1), anchor(2), anchor(3), 'kp', ...
    'MarkerFaceColor', [0.95, 0.75, 0.10], 'MarkerSize', 10);
if ~isempty(open_loop_convergence_cycle)
    crossing_index = find(open_loop_plot_indices - 1 == ...
        open_loop_convergence_cycle, 1);
    crossing_handle = plot3(open_loop_anchor_states(crossing_index, 1), ...
        open_loop_anchor_states(crossing_index, 2), ...
        open_loop_anchor_states(crossing_index, 3), 'md', ...
        'MarkerFaceColor', 'm', 'MarkerSize', 6);
end
xlabel('$v_{C_1}$ (V)', 'Interpreter', 'latex');
ylabel('$v_{C_2}$ (V)', 'Interpreter', 'latex');
zlabel('$i_L$ (A)', 'Interpreter', 'latex');
title('Open-loop convergence toward the switching limit cycle', ...
    'FontWeight', 'normal');
legend_handles = [transient_handle, anchor_handle, final_handle, target_handle, ...
    initial_handle, target_anchor_handle];
legend_labels = {'First 100 cycles', 'Faded cycle-start anchors', ...
    'Cycle 100000', 'Target limit cycle', 'Initial state', ...
    'Target anchor'};
if ~isempty(open_loop_convergence_cycle)
    legend_handles(end + 1) = crossing_handle;
    legend_labels{end + 1} = sprintf('Tolerance crossing (cycle %d)', ...
        open_loop_convergence_cycle);
end
legend(legend_handles, legend_labels, 'Location', 'best');
grid on;
view(42, 24);
exportgraphics(fig, open_loop_trajectory_output_pdf, ...
    'ContentType', 'image', 'Resolution', 300);
close(fig);

%% Open-loop states at phase-aligned cycle starts
cycle_period = config.Ts(end) - config.Ts(1);
noninitial_indices = 2:numel(open_loop_plot_indices);
cycle_start_time = (open_loop_plot_indices(noninitial_indices) - 1) * ...
    cycle_period;
state_colors = [0.00, 0.35, 0.70; 0.75, 0.20, 0.15; 0.15, 0.55, 0.25];
fig = figure('Visible', 'off', 'Position', [100, 100, 780, 650]);
layout = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
for state_index = 1:3
    nexttile;
    state_handle = semilogx(cycle_start_time, ...
        open_loop_anchor_states(noninitial_indices, state_index), '-o', ...
        'Color', state_colors(state_index, :), 'MarkerSize', 2);
    hold on;
    target_handle = yline(anchor(state_index), '--k', 'Target anchor');
    if ~isempty(open_loop_convergence_cycle)
        crossing_handle = xline(open_loop_convergence_cycle * cycle_period, ...
            '--m', 'Tolerance crossing');
    end
    ylabel(labels{state_index}, 'Interpreter', 'latex');
    grid on;
    if state_index == 1
        if isempty(open_loop_convergence_cycle)
            legend([state_handle, target_handle], ...
                {'Open-loop cycle starts', 'Target anchor'}, ...
                'Location', 'best');
        else
            legend([state_handle, target_handle, crossing_handle], ...
                {'Open-loop cycle starts', 'Target anchor', ...
                'Tolerance crossing'}, 'Location', 'best');
        end
    end
end
xlabel(layout, 'Time from initial state (s, log scale)');
title(layout, 'Open-loop states at cycle starts over 100000 cycles', ...
    'FontWeight', 'normal');
exportgraphics(fig, open_loop_states_output_pdf, 'ContentType', 'vector');
close(fig);

%% Open-loop convergence at cycle starts
plot_indices = convergence_plot_indices(open_loop_check_cycles, ...
    open_loop_convergence_cycle);
fig = figure('Visible', 'off', 'Position', [100, 100, 780, 420]);
semilogy(plot_indices - 1, open_loop_cycle_error(plot_indices), ...
    'Color', colors(2, :));
hold on;
yline(open_loop_convergence_tolerance, '--k', ...
    'Tolerance: normalized error = 0.01', 'LabelHorizontalAlignment', 'left');
if ~isempty(open_loop_convergence_cycle)
    xline(open_loop_convergence_cycle, '--k', ...
        sprintf('Persistent crossing: cycle %d', open_loop_convergence_cycle), ...
        'LabelOrientation', 'horizontal', 'LabelVerticalAlignment', 'bottom');
end
xlabel('Cycle number');
ylabel('Normalized cycle-start error');
title('Open-loop convergence to the switching limit cycle', ...
    'FontWeight', 'normal');
xlim([0, open_loop_check_cycles]);
grid on;
exportgraphics(fig, open_loop_output_pdf, 'ContentType', 'vector');
close(fig);

fprintf('Generated two-page trajectory comparison: %s\n', output_pdf);
fprintf('Generated open-loop convergence chart: %s\n', open_loop_output_pdf);
fprintf('Generated open-loop trajectory chart: %s\n', ...
    open_loop_trajectory_output_pdf);
fprintf('Generated open-loop state chart: %s\n', open_loop_states_output_pdf);
fprintf('Nominal closure error (inf norm): %.3e\n', nominal_closure_error);
cycle_start_indices = 1 + (0:comparison_cycles) * ...
    (numel(config.Omega) * samples_per_interval);
cycle_start_error = vecnorm(state_scale \ ...
    (state_on(cycle_start_indices, :)' - anchor), 2, 1);
first_cycle_below_one_percent = find(cycle_start_error < 0.01, 1) - 1;
assert(~isempty(first_cycle_below_one_percent), ...
    'The conditioned controller does not reduce the error below 0.01.');
closed_loop_spectral_radius = max(abs(eig( ...
    A_normalized - B_normalized * K_normalized)));

fprintf('Initial normalized error: %.6f\n', initial_normalized_error);
fprintf('Aggressive normalized LQR input weight: %.4g\n', ...
    aggressive_input_weight);
fprintf('Conditioned cycles: %d; minimum conditioning factor: %.6f\n', ...
    conditioned_cycle_count, min(conditioning_factors));
fprintf('Closed-loop linear spectral radius: %.9f\n', ...
    closed_loop_spectral_radius);
fprintf('First cycle below normalized error 0.01: %d\n', ...
    first_cycle_below_one_percent);
fprintf('Open-loop spectral radius: %.9f\n', open_loop_spectral_radius);
if isempty(open_loop_convergence_cycle)
    fprintf(['Open loop does not remain below normalized error %.3g ', ...
        'within %d cycles (final error %.6g).\n'], ...
        open_loop_convergence_tolerance, open_loop_check_cycles, ...
        open_loop_cycle_error(end));
else
    fprintf(['Open loop remains below normalized error %.3g from ', ...
        'cycle %d through %d (final error %.6g).\n'], ...
        open_loop_convergence_tolerance, open_loop_convergence_cycle, ...
        open_loop_check_cycles, open_loop_cycle_error(end));
end
fprintf('Maximum raw/applied switching offset: %.6f / %.6f us\n', ...
    maximum_raw_offset * 1e6, maximum_applied_offset * 1e6);
fprintf('Minimum conditioned dwell: %.6f us (applied bound %.3f us)\n', ...
    minimum_on_dwell * 1e6, applied_schedule_dwell_bound * 1e6);
fprintf('Minimum controller-OFF dwell: %.6f us\n', minimum_off_dwell * 1e6);

function plot_indices = convergence_plot_indices(cycle_count, convergence_cycle)
    early_indices = 1:min(cycle_count + 1, 1001);
    logarithmic_indices = unique(round(logspace(0, log10(cycle_count + 1), 900)));
    crossing_indices = [];
    if ~isempty(convergence_cycle)
        crossing_cycles = max(0, convergence_cycle - 25): ...
            min(cycle_count, convergence_cycle + 25);
        crossing_indices = crossing_cycles + 1;
    end
    plot_indices = unique([early_indices, logarithmic_indices, crossing_indices, ...
        cycle_count + 1]);
end

function anchor_states = sample_open_loop_anchors(Phi, anchor, ...
        initial_state, sample_indices)
    state_count = numel(anchor);
    anchor_states = zeros(numel(sample_indices), state_count);
    error = initial_state(:) - anchor(:);
    sample_cursor = 1;
    for cycle = 0:sample_indices(end) - 1
        if cycle + 1 == sample_indices(sample_cursor)
            anchor_states(sample_cursor, :) = (anchor(:) + error)';
            sample_cursor = sample_cursor + 1;
            if sample_cursor > numel(sample_indices)
                return;
            end
        end
        error = Phi * error;
    end
end

function [cycle_error, convergence_cycle, spectral_radius] = ...
        check_open_loop_convergence(Phi, state_scale, initial_error, ...
        cycle_count, tolerance)
    % Sample only switching-cycle starts: e(k+1) = Phi * e(k).
    error = initial_error(:);
    cycle_error = zeros(cycle_count + 1, 1);
    cycle_error(1) = norm(state_scale \ error, 2);
    for cycle = 1:cycle_count
        error = Phi * error;
        cycle_error(cycle + 1) = norm(state_scale \ error, 2);
    end

    spectral_radius = max(abs(eig(Phi)));
    last_outside_tolerance = find(cycle_error >= tolerance, 1, 'last');
    if isempty(last_outside_tolerance)
        convergence_cycle = 0;
    elseif last_outside_tolerance > cycle_count
        convergence_cycle = [];
    else
        convergence_cycle = last_outside_tolerance;
    end
end

function [time, state, minimum_dwell, conditioning_factors, ...
        maximum_raw_offset, maximum_applied_offset] = simulate_dense_cycles( ...
        config, anchor, initial_state, gain, cycle_count, ...
        samples_per_interval, applied_dwell_bound)
    state_count = numel(initial_state);
    samples_per_cycle = numel(config.Omega) * samples_per_interval;
    total_samples = cycle_count * samples_per_cycle + 1;
    time = zeros(total_samples, 1);
    state = zeros(total_samples, state_count);
    state(1, :) = initial_state(:)';
    current_state = initial_state(:);
    cursor = 1;
    period = config.Ts(end) - config.Ts(1);
    minimum_dwell = inf;
    conditioning_factors = ones(cycle_count, 1);
    maximum_raw_offset = 0;
    maximum_applied_offset = 0;

    for cycle = 1:cycle_count
        raw_offsets = -gain * (current_state - anchor);
        [offsets, conditioning_factor, cycle_dwell] = ...
            condition_dwell_times(config.Ts, raw_offsets, applied_dwell_bound);
        boundaries = config.Ts(:) + [0; offsets(:); 0];

        conditioning_factors(cycle) = conditioning_factor;
        maximum_raw_offset = max(maximum_raw_offset, max(abs(raw_offsets)));
        maximum_applied_offset = max( ...
            maximum_applied_offset, max(abs(offsets)));
        minimum_dwell = min(minimum_dwell, min(cycle_dwell));

        for interval = 1:numel(config.Omega)
            mode = config.Omega(interval);
            duration = boundaries(interval + 1) - boundaries(interval);
            generator = [config.A{mode}, config.b{mode}; ...
                zeros(1, state_count + 1)];
            interval_start = current_state;
            for sample = 1:samples_per_interval
                local_time = duration * sample / samples_per_interval;
                augmented = expm(generator * local_time) * ...
                    [interval_start; 1];
                cursor = cursor + 1;
                time(cursor) = (cycle - 1) * period ...
                    + boundaries(interval) + local_time;
                state(cursor, :) = augmented(1:state_count)';
            end
            current_state = state(cursor, :)';
        end
    end
end

function [time, state] = repeat_reference(config, anchor, ...
        cycle_count, samples_per_interval)
    state_count = numel(anchor);
    samples_per_cycle = numel(config.Omega) * samples_per_interval;
    total_samples = cycle_count * samples_per_cycle + 1;
    time = zeros(total_samples, 1);
    state = zeros(total_samples, state_count);
    state(1, :) = anchor(:)';
    cursor = 1;
    period = config.Ts(end) - config.Ts(1);

    for cycle = 1:cycle_count
        current_state = anchor(:);
        for interval = 1:numel(config.Omega)
            mode = config.Omega(interval);
            duration = config.Ts(interval + 1) - config.Ts(interval);
            generator = [config.A{mode}, config.b{mode}; ...
                zeros(1, state_count + 1)];
            interval_start = current_state;
            for sample = 1:samples_per_interval
                local_time = duration * sample / samples_per_interval;
                augmented = expm(generator * local_time) * ...
                    [interval_start; 1];
                cursor = cursor + 1;
                time(cursor) = (cycle - 1) * period ...
                    + config.Ts(interval) + local_time;
                state(cursor, :) = augmented(1:state_count)';
            end
            current_state = state(cursor, :)';
        end
    end
end
