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
if isfile(output_pdf), delete(output_pdf); end

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

fprintf('Generated two-page trajectory comparison: %s\n', output_pdf);
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
fprintf('Maximum raw/applied switching offset: %.6f / %.6f us\n', ...
    maximum_raw_offset * 1e6, maximum_applied_offset * 1e6);
fprintf('Minimum conditioned dwell: %.6f us (applied bound %.3f us)\n', ...
    minimum_on_dwell * 1e6, applied_schedule_dwell_bound * 1e6);
fprintf('Minimum controller-OFF dwell: %.6f us\n', minimum_off_dwell * 1e6);

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
