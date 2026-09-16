function benchmark_matlab(output_dir)
%BENCHMARK_MATLAB Host timing, not an ESP32 or plant-time measurement.
% The production conditioner is called unchanged. The beta-only variant is
% an explicitly separate arithmetic extraction, not a production replacement.
study = fileparts(mfilename('fullpath'));
paper_root = fileparts(fileparts(study));
addpath(fullfile(paper_root, 'scripts'));
if nargin == 0
    output_dir = fullfile(study, 'results');
end
if ~isfolder(output_dir), mkdir(output_dir); end
response = readtable(fullfile(paper_root, 'results', 'conditioned_control_response.csv'));
schedule = readtable(fullfile(paper_root, 'results', 'reference_schedule_orbit.csv'));
response = response(isfinite(response.beta), :);
nominal = [schedule.start_us(1); schedule.end_us] * 1e-6;
bound = 3e-6;
inputs = cell(height(response), 1);
for i = 1:height(response)
    u = zeros(8, 1);
    expected_offsets = zeros(8, 1);
    expected_dwell = zeros(9, 1);
    for j = 1:8
        u(j) = response.(sprintf('raw_offset_%d_us', j))(i) * 1e-6;
        expected_offsets(j) = response.(sprintf('applied_offset_%d_us', j))(i) * 1e-6;
    end
    for j = 1:9
        expected_dwell(j) = response.(sprintf('applied_dwell_%d_us', j))(i) * 1e-6;
    end
    inputs{i} = u;
    [applied, beta, dwell] = condition_dwell_times(nominal, u, bound);
    assert(abs(beta - response.beta(i)) < 1e-12);
    assert(max(abs(applied - expected_offsets)) < 1e-14);
    assert(max(abs(dwell - expected_dwell)) < 1e-14);
    assert(abs(beta_only(nominal, u, bound) - beta) < 1e-12);
end
% Corner cases, outside timed regions.
assert(beta_only(nominal, zeros(8, 1), bound) == 1);
assert(beta_only([0; 3; 6] * 1e-6, [-1e-6], bound) == 0);
assert(beta_only([0; 3; 6] * 1e-6, [1e-6], bound) == 0);
[~, nominal_beta, ~] = condition_dwell_times(nominal, zeros(8, 1), bound);
assert(nominal_beta == 1);

single_count = 10000;
batch_count = 500;
batch_size = 200;
warmup_count = 5000;
groups = {1:height(response), find(response.beta < 1 - 1e-12)', ...
    find(response.beta >= 1 - 1e-12)'};
group_names = {'mixed_100', 'conditioned_3', 'unconditioned_97'};
assert(isequal(cellfun(@numel, groups), [100, 3, 97]));

fid = fopen(fullfile(output_dir, 'matlab_samples.csv'), 'w');
assert(fid >= 0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'implementation,scenario,measurement,sample,calls,elapsed_ns,per_call_ns\n');
checksum = 0;
% Warm up both JIT paths and all input directions before sampling.
for i = 1:warmup_count
    u = inputs{mod(i - 1, numel(inputs)) + 1};
    [a, b, d] = condition_dwell_times(nominal, u, bound);
    checksum = checksum + sum(a) + b + sum(d);
    checksum = checksum + beta_only(nominal, u, bound);
end
baseline = zeros(single_count, 1);
for i = 1:single_count
    clock = tic;
    baseline(i) = toc(clock) * 1e9;
end
write_samples(fid, 'matlab_timer_only', 'baseline', 'individual', baseline, 1);

for group = 1:numel(groups)
    selected = inputs(groups{group});
    count = numel(selected);
    for variant = 1:2
        if variant == 1
            name = 'matlab_existing_conditioner';
        else
            name = 'matlab_beta_only';
        end
        fprintf('Timing %s / %s\n', name, group_names{group});
        samples = zeros(single_count, 1);
        for i = 1:single_count
            % Input indexing and post-call consumption are outside this timer.
            u = selected{mod(i - 1, count) + 1};
            if variant == 1
                clock = tic;
                [a, b, d] = condition_dwell_times(nominal, u, bound);
                elapsed = toc(clock);
                checksum = checksum + sum(a) + b + sum(d);
            else
                clock = tic;
                b = beta_only(nominal, u, bound);
                elapsed = toc(clock);
                checksum = checksum + b;
            end
            samples(i) = elapsed * 1e9;
        end
        write_samples(fid, name, group_names{group}, 'individual', samples, 1);
        samples = zeros(batch_count, 1);
        for batch = 1:batch_count
            acc = 0;
            clock = tic;
            for j = 1:batch_size
                u = selected{mod((batch - 1) * batch_size + j - 1, count) + 1};
                if variant == 1
                    [a, b, d] = condition_dwell_times(nominal, u, bound);
                    acc = acc + sum(a) + b + sum(d);
                else
                    acc = acc + beta_only(nominal, u, bound);
                end
            end
            samples(batch) = toc(clock) * 1e9;
            checksum = checksum + acc;
        end
        write_samples(fid, name, group_names{group}, 'batch_mean', samples, batch_size);
    end
end
metadata = struct('matlab_version', version, 'release', version('-release'), ...
    'computer', computer, 'production_function', which('condition_dwell_times'), ...
    'single_count', single_count, 'batch_count', batch_count, ...
    'batch_size', batch_size, 'warmup_count', warmup_count, ...
    'verified_article_inputs', height(response), 'checksum', checksum);
meta = fopen(fullfile(output_dir, 'matlab_environment.json'), 'w');
assert(meta >= 0);
fprintf(meta, '%s\n', jsonencode(metadata, PrettyPrint=true));
fclose(meta);
fprintf('MATLAB validation passed for %d saved cycles; checksum %.17g\n', height(response), checksum);
end

function beta = beta_only(nominal_boundaries, raw_offsets, bound)
% Arithmetic equivalent of production lines 9-24, excluding assertions,
% input reshaping, output scaling and applied-schedule reconstruction.
nominal_dwell = diff(nominal_boundaries);
available_dwell = nominal_dwell - bound;
gap_change = diff([0; raw_offsets; 0]);
shrinking = gap_change < 0;
beta = 1;
if any(shrinking)
    beta = min(1, min(available_dwell(shrinking) ./ -gap_change(shrinking)));
end
beta = min(1, max(0, beta));
end

function write_samples(fid, implementation, scenario, measurement, elapsed, calls)
% File I/O is outside all timed regions.
for i = 1:numel(elapsed)
    fprintf(fid, '%s,%s,%s,%d,%d,%.9f,%.9f\n', ...
        implementation, scenario, measurement, i, calls, elapsed(i), elapsed(i) / calls);
end
end
