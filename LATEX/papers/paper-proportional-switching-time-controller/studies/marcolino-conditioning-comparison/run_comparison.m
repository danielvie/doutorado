function study = run_comparison(output_dir, error_scale)
%RUN_COMPARISON Compare Daniel, relaxed-terminal Daniel, and Marcolino.
% Default uses the article's initial state; run_comparison([],2) doubles its
% displacement from the orbit anchor and writes an isolated results folder.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 2 || isempty(error_scale), error_scale = 1; end
assert(isscalar(error_scale) && isfinite(error_scale) && error_scale > 0, ...
    'error_scale must be a positive finite scalar.');
if nargin < 1 || isempty(output_dir)
    if error_scale == 1
        output_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
    else
        output_dir = fullfile(fileparts(mfilename('fullpath')), 'results', ...
            sprintf('error-scale-%gx', error_scale));
    end
end
addpath(fullfile(root, 'scripts'));
paths = paper.paths();
addpath(paths.simulation);
benchmark = paper.benchmark();
model = paper.validate_model(benchmark);
controller = paper.design_feedback(benchmark, model);
benchmark.initial_state = benchmark.orbit_anchor + error_scale * ...
    (benchmark.initial_state - benchmark.orbit_anchor);
N = benchmark.cycle_count;
bound = benchmark.applied_schedule_dwell_bound;
assert(benchmark.config.Ts(1) == 0);

% A hand-check catches endpoint clamping, independent-offset clipping, and
% a wrong predecessor in the sequential recursion.
test_schedule = sequential_dwell_condition([0; 5; 9; 12], [1; -4], 2);
assert(isequal(test_schedule, [0; 6; 8; 12]));
test_extension = sequential_dwell_condition([0; 5; 9; 12], [3; 2], 2);
assert(isequal(test_extension, [0; 8; 11; 13]));
test_relaxed_dwell_condition();
uniform = simulate(benchmark, controller.K_aggressive_physical, 'uniform', N, bound);
relaxed = simulate(benchmark, controller.K_aggressive_physical, 'relaxed', N, bound);
sequential = simulate(benchmark, controller.K_aggressive_physical, 'sequential', N, bound);
open_loop = simulate(benchmark, zeros(size(controller.K_aggressive_physical)), ...
    'uniform', 25, bound); % First 25 cycles, for the article-style context panel.
assert(max(abs(uniform.raw_offsets(:, 1) - sequential.raw_offsets(:, 1))) < 1e-15);
assert(max(abs(uniform.states(:, 1) - sequential.states(:, 1))) == 0);
assert(all(uniform.dwell(:) >= bound - 1e-12));
assert(all(sequential.dwell(:) >= bound - 1e-12));
assert(all(relaxed.dwell(:) >= bound - 1e-12));
assert(max(abs(uniform.raw_offsets(:,1) - relaxed.raw_offsets(:,1))) < 1e-15);
assert(isequal(uniform.states(:,1), relaxed.states(:,1)));
assert(all(relaxed.beta >= 0 & relaxed.beta <= 1));
assert(all(relaxed.period >= benchmark.period - 1e-12));
assert(max(abs(relaxed.boundaries(2:end-1,:) - benchmark.config.Ts(2:end-1)' ...
    - relaxed.raw_offsets .* relaxed.beta'), [], 'all') < 1e-12, ...
    'Relaxed interior offsets must stay on the raw-command ray.');
assert(max(abs(diff(uniform.clock) - benchmark.period)) < 1e-12);
assert(max(abs(uniform.boundaries(end,:) - benchmark.config.Ts(end))) < 1e-12, ...
    'Daniel must keep the final cycle boundary fixed.');

% Cross-check this independent run against the current published 100-cycle
% uniform-conditioning evidence, without changing it.
record_file = fullfile(paths.results, 'conditioned_control_response.csv');
if error_scale == 1 && isfile(record_file)
    record = readtable(record_file);
    assert(height(record) == N + 1);
    assert(max(abs(record.conditioned_error - uniform.error)) < 1e-8, ...
        'Uniform response differs from the article record.');
    assert(abs(record.beta(1) - uniform.beta(1)) < 1e-10);
    assert(max(abs(record.open_loop_error(1:26) - open_loop.error)) < 1e-8);
end

if ~exist(output_dir, 'dir'), mkdir(output_dir); end
setup = table(error_scale, benchmark.initial_state(1), benchmark.initial_state(2), ...
    benchmark.initial_state(3), uniform.error(1), ...
    'VariableNames', {'error_scale', 'initial_vc1_v', 'initial_vc2_v', ...
    'initial_il_a', 'initial_normalized_error'});
writetable(setup, fullfile(output_dir, 'setup.csv'));
threshold = 0.01;
methods = {'daniel'; 'daniel-relaxed'; 'marcolino'};
responses = {uniform; relaxed; sequential};
values = zeros(3,17);
for i = 1:3
    r = responses{i};
    beta_count = NaN; % Marcolino has no scalar beta.
    if i < 3, beta_count = sum(r.beta < 1-1e-12); end
    values(i,:) = [r.error(end), r.global_phase_error(end), ...
        first_below(r.error, threshold), permanent_below(r.error, threshold), ...
        permanent_below(r.global_phase_error, threshold), time_to_threshold(r, threshold), ...
        sum(r.error(1:end-1).^2), min(r.dwell(:))*1e6, sum(r.changed), ...
        sum(r.extended), max(r.period)*1e6, r.period(end)*1e6, r.clock(end)*1e3, ...
        beta_count, r.period(1)*1e6, (r.clock(end)-N*benchmark.period)*1e6, r.beta(1)];
end
metrics = [table(methods, 'VariableNames', {'method'}), array2table(values, ...
    'VariableNames', {'final_phase_reset_error', ...
    'final_global_phase_error', 'first_anchor_cycle_below_001', ...
    'sustained_anchor_cycle_below_001', 'sustained_global_cycle_below_001', ...
    'time_to_anchor_001_ms', 'cycle_sampled_squared_error_sum', 'minimum_dwell_us', ...
    'conditioned_cycle_count', 'extended_cycle_count', ...
    'maximum_cycle_duration_us', 'final_cycle_duration_us', 'elapsed_time_ms', ...
    'beta_active_cycle_count', 'first_cycle_duration_us', 'total_boundary_delay_us', ...
    'first_beta'})];
writetable(metrics, fullfile(output_dir, 'metrics.csv'));
cycle = (0:N)';
trace = table(cycle, uniform.clock * 1e3, relaxed.clock * 1e3, sequential.clock * 1e3, ...
    uniform.error, relaxed.error, sequential.error, ...
    uniform.global_phase_error, relaxed.global_phase_error, sequential.global_phase_error, ...
    [uniform.beta; NaN], [relaxed.beta; NaN], ...
    uniform.clock * 1e6 - cycle * benchmark.period * 1e6, ...
    relaxed.clock * 1e6 - cycle * benchmark.period * 1e6, ...
    sequential.clock * 1e6 - cycle * benchmark.period * 1e6, ...
    'VariableNames', {'cycle', 'daniel_time_ms', 'daniel_relaxed_time_ms', 'marcolino_time_ms', ...
    'daniel_phase_reset_error', 'daniel_relaxed_phase_reset_error', 'marcolino_phase_reset_error', ...
    'daniel_global_phase_error', 'daniel_relaxed_global_phase_error', 'marcolino_global_phase_error', ...
    'daniel_beta', 'daniel_relaxed_beta', 'daniel_boundary_delay_us', ...
    'daniel_relaxed_boundary_delay_us', 'marcolino_boundary_delay_us'});
writetable(trace, fullfile(output_dir, 'cycle_history.csv'));
duration = table((1:N)', uniform.period * 1e6, relaxed.period * 1e6, sequential.period * 1e6, ...
    repmat(benchmark.period * 1e6, N, 1), ...
    'VariableNames', {'cycle', 'daniel_duration_us', 'daniel_relaxed_duration_us', ...
    'marcolino_duration_us', 'nominal_duration_us'});
writetable(duration, fullfile(output_dir, 'cycle_duration.csv'));
first = table((1:numel(benchmark.config.Omega))', ...
    diff(benchmark.config.Ts(:)) * 1e6, ...
    diff(benchmark.config.Ts(:) + [0;uniform.raw_offsets(:,1);0]) * 1e6, ...
    uniform.dwell(:,1) * 1e6, relaxed.dwell(:,1) * 1e6, sequential.dwell(:,1) * 1e6, ...
    'VariableNames', {'interval', 'nominal_us', 'raw_requested_us', ...
    'daniel_us', 'daniel_relaxed_us', 'marcolino_us'});
writetable(first, fullfile(output_dir, 'first_cycle_dwell.csv'));

blue = [0.10 0.37 0.71]; % Daniel in all study figures
green = [0.15 0.55 0.30]; % Daniel-relaxed
orange = [0.87 0.35 0.12]; % Marcolino
f = figure('Visible', 'off', 'Position', [80, 80, 1000, 950]);
tiledlayout(f, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile;
semilogy(cycle, max(uniform.error, 1e-15), 'Color', blue, 'LineWidth', 1.7); hold on;
semilogy(cycle, max(relaxed.error, 1e-15), 'Color', green, 'LineWidth', 1.7);
semilogy(cycle, max(relaxed.global_phase_error, 1e-15), '--', ...
    'Color', green, 'LineWidth', 1.4);
semilogy(cycle, max(sequential.error, 1e-15), 'Color', orange, 'LineWidth', 1.7);
semilogy(cycle, max(sequential.global_phase_error, 1e-15), '--', ...
    'Color', orange, 'LineWidth', 1.4);
yline(threshold, ':', '0.01', 'Color', [0.25 0.25 0.25]); grid on;
ylabel('Normalized error at cycle starts'); xlabel('Completed cycles');
legend('daniel, anchor = fixed clock', 'daniel-relaxed, anchor', ...
    'daniel-relaxed, fixed clock', 'marcolino, anchor', ...
    'marcolino, fixed clock', 'Threshold', 'Location', 'best');
nexttile;
shown_cycles = 1:min(12, N);
plot(shown_cycles, duration.daniel_duration_us(shown_cycles), '-o', ...
    'Color', blue, 'MarkerSize', 4, 'LineWidth', 1.6); hold on;
plot(shown_cycles, duration.daniel_relaxed_duration_us(shown_cycles), '-^', ...
    'Color', green, 'MarkerSize', 4, 'LineWidth', 1.6);
plot(shown_cycles, duration.marcolino_duration_us(shown_cycles), '-s', ...
    'Color', orange, 'MarkerSize', 4, 'LineWidth', 1.6);
yline(benchmark.period * 1e6, ':k', 'Nominal 286 µs', ...
    'HandleVisibility', 'off');
xlim([0.8, shown_cycles(end) + 0.2]); xticks(shown_cycles);
ylim([0.96 * benchmark.period * 1e6, ...
    1.04 * max(duration.marcolino_duration_us(shown_cycles))]); grid on;
ylabel('Cycle duration (µs)'); xlabel('Cycle number');
legend('daniel', 'daniel-relaxed', 'marcolino', 'Location', 'best');
nexttile;
plot(first.interval, first.raw_requested_us, 'o-', 'Color', [0.4 0.4 0.4], ...
    'LineWidth', 1.2); hold on;
plot(first.interval, first.daniel_us, 's-', 'Color', blue, 'LineWidth', 1.2);
plot(first.interval, first.daniel_relaxed_us, '^-', 'Color', green, 'LineWidth', 1.2);
plot(first.interval, first.marcolino_us, 'd-', 'Color', orange, 'LineWidth', 1.2);
yline(bound * 1e6, ':', 'Minimum dwell', 'Color', [0.25 0.25 0.25]); grid on;
ylabel('First-cycle dwell (µs)'); xlabel('Mode interval');
legend('Raw request', 'daniel', 'daniel-relaxed', 'marcolino', ...
    'Minimum dwell', 'Location', 'best');
sgtitle(sprintf('Three conditioners: same gain, initial error scale %g',error_scale));
exportgraphics(f, fullfile(output_dir, 'comparison.pdf'), 'ContentType', 'vector');
exportgraphics(f, fullfile(output_dir, 'comparison.png'), 'Resolution', 180);
close(f);
export_trajectory_figure(benchmark, uniform, relaxed, sequential, output_dir, error_scale);
plot_article_response_comparison(benchmark, uniform, relaxed, sequential, ...
    open_loop, output_dir, error_scale);

study = struct('benchmark', benchmark, 'controller', controller, ...
    'daniel', uniform, 'daniel_relaxed', relaxed, 'marcolino', sequential, 'open_loop', open_loop, ...
    'metrics', metrics, ...
    'error_scale', error_scale);
fprintf('Study outputs: %s\n', output_dir);
disp(metrics);
save(fullfile(output_dir, 'study.mat'), 'study');
fprintf('First-cycle durations: daniel %.6f us; daniel-relaxed %.6f us; marcolino %.6f us.\n', ...
    uniform.period(1)*1e6, relaxed.period(1)*1e6, sequential.period(1)*1e6);
end

function result = simulate(b, gain, method, N, bound)
nominal = b.config.Ts(:);
M = numel(b.config.Omega);
states = zeros(numel(b.initial_state), N+1);
states(:,1) = b.initial_state;
raw_offsets = zeros(M-1,N);
applied = zeros(M+1,N);
dwell = zeros(M,N);
period = zeros(N,1);
beta = NaN(N,1);
changed = false(N,1);
extended = false(N,1);
clock = zeros(N+1,1);
for k=1:N
    raw_offsets(:,k) = -gain*(states(:,k) - b.orbit_anchor);
    if strcmp(method,'uniform')
        [offsets,beta(k),dwell(:,k)] = condition_dwell_times( ...
            nominal, raw_offsets(:,k), bound);
        applied(:,k) = nominal + [0;offsets;0];
        changed(k) = beta(k) < 1-1e-12;
    elseif strcmp(method,'relaxed')
        [applied(:,k),beta(k),dwell(:,k)] = relaxed_dwell_condition( ...
            nominal, raw_offsets(:,k), bound);
        changed(k) = beta(k) < 1-1e-12 || applied(end,k) > nominal(end) + 1e-12;
    else
        applied(:,k) = sequential_dwell_condition(nominal,raw_offsets(:,k),bound);
        dwell(:,k) = diff(applied(:,k));
        raw_boundaries = nominal + [0;raw_offsets(:,k);0];
        changed(k) = any(abs(applied(:,k) - raw_boundaries) > 1e-12);
    end
    period(k) = applied(end,k) - applied(1,k);
    extended(k) = period(k) > b.period + 1e-12;
    clock(k+1) = clock(k) + period(k);
    config = b.config;
    config.Ts = applied(:,k);
    cycle_states = paper.cycle_boundaries(config, states(:,k), zeros(M-1,1));
    states(:,k+1) = cycle_states(:,end);
    assert(all(isfinite(states(:,k+1))), 'Nonfinite state at cycle %d',k);
end
error = vecnorm(b.state_scale \ (states - b.orbit_anchor), 2, 1)';
% Also score against the original nominal orbit on a fixed global clock.
% This differs from the moving cycle-start target if the actuator extends a cycle.
reference_states = paper.cycle_boundaries(b.config,b.orbit_anchor,zeros(M-1,1));
global_phase_error = zeros(N+1,1);
for k=1:N+1
    phase = mod(clock(k), b.period);
    if min(phase, b.period-phase) < 1e-12
        target = b.orbit_anchor;
    else
        interval = find(nominal <= phase,1,'last');
        mode = b.config.Omega(interval);
        generator = [b.config.A{mode}, b.config.b{mode}; ...
            zeros(1, numel(b.orbit_anchor)+1)];
        propagated = expm(generator * (phase - nominal(interval))) * ...
            [reference_states(:,interval); 1];
        target = propagated(1:numel(b.orbit_anchor));
    end
    global_phase_error(k) = norm(b.state_scale \ (states(:,k) - target),2);
end
result = struct('states',states,'error',error, ...
    'global_phase_error',global_phase_error,'raw_offsets',raw_offsets, ...
    'boundaries',applied,'dwell',dwell,'period',period,'beta',beta, ...
    'changed',changed,'extended',extended,'clock',clock);
end

function export_trajectory_figure(b, uniform, relaxed, sequential, output_dir, error_scale)
% Re-propagate the already-computed switching schedules at dense times.
% No controller step is repeated and no time grids are interpolated.
cycles = 12;
samples_per_interval = 30;
assert(cycles <= b.cycle_count);
[uniform_time, uniform_state] = dense_samples(b, uniform, cycles, samples_per_interval);
[relaxed_time, relaxed_state] = dense_samples(b, relaxed, cycles, samples_per_interval);
[sequential_time, sequential_state] = dense_samples(b, sequential, cycles, samples_per_interval);
[reference_cycle_time, reference_cycle_state] = paper.sample_cycle( ...
    b.config, b.orbit_anchor, zeros(numel(b.config.Omega)-1,1), samples_per_interval);
points_per_cycle = numel(reference_cycle_time) - 1;
reference_time = zeros(cycles * points_per_cycle + 1, 1);
reference_state = zeros(numel(reference_time), numel(b.orbit_anchor));
reference_time(1) = 0;
reference_state(1,:) = b.orbit_anchor(:)';
for k=1:cycles
    indices = (k-1)*points_per_cycle + (2:points_per_cycle+1);
    reference_time(indices) = (k-1)*b.period + reference_cycle_time(2:end);
    reference_state(indices,:) = reference_cycle_state(2:end,:);
end
assert(abs(reference_time(end) - uniform_time(end)) < 1e-12);
assert(abs(sequential_time(end) - sequential.clock(cycles+1)) < 1e-12);

samples = table(uniform_time*1e3, uniform_state(:,1), uniform_state(:,2), ...
    uniform_state(:,3), relaxed_time*1e3, relaxed_state(:,1), relaxed_state(:,2), ...
    relaxed_state(:,3), sequential_time*1e3, sequential_state(:,1), ...
    sequential_state(:,2), sequential_state(:,3), reference_time*1e3, ...
    reference_state(:,1), reference_state(:,2), reference_state(:,3), ...
    'VariableNames', {'daniel_time_ms','daniel_vc1_v','daniel_vc2_v', ...
    'daniel_il_a','daniel_relaxed_time_ms','daniel_relaxed_vc1_v', ...
    'daniel_relaxed_vc2_v','daniel_relaxed_il_a','marcolino_time_ms','marcolino_vc1_v', ...
    'marcolino_vc2_v','marcolino_il_a','reference_time_ms', ...
    'reference_vc1_v','reference_vc2_v','reference_il_a'});
writetable(samples, fullfile(output_dir, 'trajectory_samples.csv'));

% Compare at the same physical-time window; retain separate raw grids in CSV.
limit = cycles * b.period;
visible = sequential_time <= limit + 1e-12;
relaxed_visible = relaxed_time <= limit + 1e-12;
blue = [0.10 0.37 0.71];
green = [0.15 0.55 0.30];
orange = [0.87 0.35 0.12];
f = figure('Visible','off','Position',[80 80 1300 900]);
t = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
ax = nexttile(t,1);
h_ref = plot3(ax, reference_cycle_state(:,1), reference_cycle_state(:,2), ...
    reference_cycle_state(:,3), 'k--','LineWidth',1.4); hold(ax,'on');
h_uniform = plot3(ax, uniform_state(:,1), uniform_state(:,2), ...
    uniform_state(:,3),'Color',blue,'LineWidth',1.0);
h_relaxed = plot3(ax, relaxed_state(relaxed_visible,1), relaxed_state(relaxed_visible,2), ...
    relaxed_state(relaxed_visible,3),'Color',green,'LineWidth',1.0);
h_sequential = plot3(ax, sequential_state(visible,1), sequential_state(visible,2), ...
    sequential_state(visible,3),'Color',orange,'LineWidth',1.0);
plot3(ax,b.initial_state(1),b.initial_state(2),b.initial_state(3), ...
    'ko','MarkerFaceColor','k','MarkerSize',5,'HandleVisibility','off');
grid(ax,'on'); view(ax,-50,22);
xlabel(ax,'v_{C1} (V)'); ylabel(ax,'v_{C2} (V)'); zlabel(ax,'i_L (A)');
title(ax,'State-space trajectory');
legend(ax,[h_ref,h_uniform,h_relaxed,h_sequential], ...
    {'Fixed-clock reference','daniel','daniel-relaxed','marcolino'}, ...
    'Location','best');
labels = {'v_{C1} (V)', 'v_{C2} (V)', 'i_L (A)'};
for component=1:3
    ax = nexttile(t,component+1);
    plot(ax,reference_time*1e3,reference_state(:,component),'k--', ...
        'LineWidth',1.1); hold(ax,'on');
    plot(ax,uniform_time*1e3,uniform_state(:,component), ...
        'Color',blue,'LineWidth',1.2);
    plot(ax,relaxed_time(relaxed_visible)*1e3,relaxed_state(relaxed_visible,component), ...
        'Color',green,'LineWidth',1.2);
    plot(ax,sequential_time(visible)*1e3,sequential_state(visible,component), ...
        'Color',orange,'LineWidth',1.2);
    xlim(ax,[0 limit*1e3]); grid(ax,'on');
    ylabel(ax,labels{component}); xlabel(ax,'Elapsed time (ms)');
    if component==1
        legend(ax,{'Fixed-clock reference','daniel','daniel-relaxed','marcolino'}, ...
            'Location','best');
    end
end
sgtitle(t,sprintf('Exact trajectories, first 12 nominal periods; initial error scale %g',error_scale));
exportgraphics(f,fullfile(output_dir,'state_trajectories.pdf'),'ContentType','vector');
exportgraphics(f,fullfile(output_dir,'state_trajectories.png'),'Resolution',180);
close(f);
end

function [time, state] = dense_samples(b, response, cycles, samples_per_interval)
points_per_cycle = numel(b.config.Omega) * samples_per_interval;
time = zeros(cycles * points_per_cycle + 1,1);
state = zeros(numel(time),numel(b.orbit_anchor));
state(1,:) = response.states(:,1)';
for k=1:cycles
    config = b.config;
    config.Ts = response.boundaries(:,k);
    [local_time, local_state] = paper.sample_cycle( ...
        config, response.states(:,k), zeros(numel(config.Omega)-1,1), ...
        samples_per_interval);
    assert(norm(local_state(end,:)' - response.states(:,k+1),inf) < 1e-9, ...
        'Dense samples disagree with the recorded exact cycle endpoint.');
    indices = (k-1)*points_per_cycle + (2:points_per_cycle+1);
    time(indices) = response.clock(k) + local_time(2:end);
    state(indices,:) = local_state(2:end,:);
end
assert(all(diff(time)>0),'Dense trajectory time did not advance.');
end

function ms = time_to_threshold(result, threshold)
cycle = first_below(result.error, threshold);
ms = NaN;
if ~isnan(cycle), ms = result.clock(cycle+1)*1e3; end
end

function cycle = first_below(error, threshold)
index = find(error < threshold,1,'first');
cycle = NaN;
if ~isempty(index), cycle = index-1; end
end

function cycle = permanent_below(error, threshold)
index = find(error >= threshold,1,'last');
if isempty(index)
    cycle = 0;
elseif index == numel(error)
    cycle = NaN;
else
    cycle = index;
end
end
