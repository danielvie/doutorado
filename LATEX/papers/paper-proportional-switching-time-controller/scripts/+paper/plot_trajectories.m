function plot_trajectories(output, data, benchmark)
%PLOT_TRAJECTORIES Render saved physical trajectories without resimulating.
% Dense short-run paths are distinct from phase-aligned long-run cycle samples.
if ~isfolder(output), mkdir(output); end
figure_comparison(output, data, benchmark);
figure_convergence(output, data, benchmark);
end

function figure_comparison(output, data, benchmark)
fig = figure('Visible', 'off', 'Position', [100, 100, 740, 550]);
cleanup = onCleanup(@() close(fig));
ax = axes(fig);
x = data.state_off;
open = plot3(ax, x(:, 1), x(:, 2), x(:, 3), '--', ...
    'Color', [0.75, 0.20, 0.15], 'LineWidth', 0.8); hold(ax, 'on');
x = data.state_on;
controlled = plot3(ax, x(:, 1), x(:, 2), x(:, 3), '-', ...
    'Color', [0.00, 0.35, 0.70], 'LineWidth', 1.2);
r = data.reference_state;
target = plot3(ax, r(:, 1), r(:, 2), r(:, 3), '-k', 'LineWidth', 2.2);
x = data.state_on(1, :);
start = plot3(ax, x(1), x(2), x(3), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
a = benchmark.orbit_anchor;
anchor = plot3(ax, a(1), a(2), a(3), 'kp', ...
    'MarkerFaceColor', [1, 0.8, 0], 'MarkerSize', 11);
physical_axes(ax, 12);
title(ax, sprintf('Controlled and open-loop trajectories, %d cycles', benchmark.cycle_count), ...
    'FontWeight', 'normal');
legend(ax, [controlled, open, target, start, anchor], ...
    {'Conditioned feedback', 'Open loop', 'Reference periodic trajectory', ...
    'Initial state', 'Cycle anchor'}, 'Location', 'southoutside', ...
    'NumColumns', 2, 'FontSize', 11, 'Box', 'off');
exportgraphics(fig, fullfile(output, 'trajectory_comparison.pdf'), 'ContentType', 'vector');
end

function figure_convergence(output, data, benchmark)
last_cycle = size(data.long_open_loop_states, 2) - 1;
assert(last_cycle == benchmark.long_simulation_cycles, 'Long-run horizon mismatch.');
assert(data.convergence_cycle <= last_cycle, 'Threshold crossing lies beyond the run.');
% Logarithmic time cannot include k = 0. Use actual samples, not interpolated states.
% Dense late-time sampling keeps the damped oscillations visible on the log axis.
cycles = unique([1:1000, round(logspace(3, log10(last_cycle), 6000)), ...
    data.convergence_cycle, last_cycle]);
cycles = cycles(cycles >= 1 & cycles <= last_cycle);
time = cycles * benchmark.period;
x = data.long_open_loop_states(:, cycles + 1);
colors = [0.00, 0.35, 0.70; 0.75, 0.20, 0.15; 0.15, 0.50, 0.25];
labels = {'$v_{C_1}(kT)$ (V)', '$v_{C_2}(kT)$ (V)', '$i_L(kT)$ (A)'};
fig = figure('Visible', 'off', 'Position', [100, 100, 1160, 650]);
cleanup = onCleanup(@() close(fig));
layout = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for index = 1:3
    ax = nexttile(layout, 2 * index - 1);
    state = semilogx(ax, time, x(index, :), '-', 'Color', colors(index, :), 'LineWidth', 1.5);
    hold(ax, 'on');
    target = yline(ax, benchmark.orbit_anchor(index), '--k', 'LineWidth', 1);
    crossing = xline(ax, data.convergence_cycle * benchmark.period, ':', ...
        'Color', [0.6, 0.1, 0.6], 'LineWidth', 1.3);
    set(ax, 'FontName', 'Times New Roman', 'FontSize', 13);
    ylabel(ax, labels{index}, 'Interpreter', 'latex');
    xlim(ax, [benchmark.period, last_cycle * benchmark.period]);
    xticks(ax, 10.^(floor(log10(benchmark.period)):ceil(log10(last_cycle * benchmark.period))));
    grid(ax, 'on');
    title(ax, sprintf('(%c) Open-loop cycle-start state', 'a' + index - 1), 'FontWeight', 'normal');
    if index == 1
        legend(ax, [state, target, crossing], ...
            {'Open loop', 'Cycle anchor', 'Error threshold crossing'}, ...
            'Location', 'southwest', 'FontSize', 11, 'Box', 'off');
    end
    if index == 3, xlabel(ax, 'Time kT (s, log scale)'); end
end

ax = nexttile(layout, 2, [3, 1]);
% Retain the dense early transient, then draw selected cycle-start states only.
% No lines connect those samples: they do not describe the within-cycle motion.
x = data.state_off;
early = plot3(ax, x(:, 1), x(:, 2), x(:, 3), '--', ...
    'Color', colors(2, :), 'LineWidth', 0.7); hold(ax, 'on');
tail_cycles = unique([benchmark.cycle_count:10:1000, ...
    round(logspace(3, log10(last_cycle), 1000)), data.convergence_cycle, last_cycle]);
tail_cycles = tail_cycles(tail_cycles >= benchmark.cycle_count & tail_cycles <= last_cycle);
x = data.long_open_loop_states(:, tail_cycles + 1)';
fade = log(tail_cycles(:) / benchmark.cycle_count) / log(last_cycle / benchmark.cycle_count);
point_colors = (1 - fade) * [0.80, 0.48, 0.12] + fade * [0.97, 0.94, 0.87];
tail = scatter3(ax, x(:, 1), x(:, 2), x(:, 3), 8, point_colors, 'filled');
r = data.reference_state;
target = plot3(ax, r(:, 1), r(:, 2), r(:, 3), '-k', 'LineWidth', 2.5);
r = data.final_state;
final = plot3(ax, r(:, 1), r(:, 2), r(:, 3), '--', ...
    'Color', colors(1, :), 'LineWidth', 1.2);
a = benchmark.orbit_anchor;
plot3(ax, a(1), a(2), a(3), 'kp', 'MarkerFaceColor', [1, 0.8, 0], ...
    'MarkerSize', 11, 'HandleVisibility', 'off');
x = data.state_off(1, :);
plot3(ax, x(1), x(2), x(3), 'ko', 'MarkerFaceColor', 'k', ...
    'MarkerSize', 5, 'HandleVisibility', 'off');
x = data.long_open_loop_states(:, data.convergence_cycle + 1);
crossing = plot3(ax, x(1), x(2), x(3), 'd', 'Color', [0.6, 0.1, 0.6], ...
    'MarkerFaceColor', [0.6, 0.1, 0.6], 'MarkerSize', 6);
physical_axes(ax, 13);
title(ax, {'(d) Open-loop approach to the reference', 'Dense early path, then cycle-start samples'}, ...
    'FontWeight', 'normal');
legend(ax, [early, tail, target, final, crossing], ...
    {sprintf('First %d cycles', benchmark.cycle_count), 'Later cycle-start samples', ...
    'Reference periodic trajectory', sprintf('Cycle starting at k = %d', last_cycle), ...
    sprintf('Threshold crossing, k = %d', data.convergence_cycle)}, ...
    'Location', 'southoutside', 'FontSize', 11, 'Box', 'off');
exportgraphics(fig, fullfile(output, 'open_loop_convergence.pdf'), 'ContentType', 'vector');
end

function physical_axes(ax, font_size)
xlabel(ax, '$v_{C_1}$ (V)', 'Interpreter', 'latex');
ylabel(ax, '$v_{C_2}$ (V)', 'Interpreter', 'latex');
zlabel(ax, '$i_L$ (A)', 'Interpreter', 'latex');
% Keep the reference curve and endpoint markers visible over the transient samples.
set(ax, 'FontName', 'Times New Roman', 'FontSize', font_size, 'SortMethod', 'childorder');
grid(ax, 'on'); view(ax, 42, 24);
end
