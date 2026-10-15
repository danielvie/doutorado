function summary = benchmark_matched_timing()
%BENCHMARK_MATCHED_TIMING Matched physical-state to validated-schedule timing.
% No plant propagation or offline controller construction. Native Mpc.solve
% starts every QP from an all-zero plan, including warmed calls.
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, 'scripts'));
paths = paper.paths();
addpath(paths.simulation);
source = fullfile(here, 'results', 'error-scale-1x', 'study.mat');
loaded = load(source, 'study'); s = loaded.study;
b = s.benchmark; c = s.controller; p = s.problems{2};
assert(isequal(s.names, {'daniel','mpc-5'}) && s.error_scale == 1);
assert(p.prediction_horizon == 5 && p.update_period_cycles == 1);
assert(~p.prediction.uses_previous_action);
assert(strcmp(p.solver_options.Algorithm, 'active-set'));
names = string(s.names);
output = fullfile(here, 'results', 'matched-timing');
if ~isfolder(output), mkdir(output); end

% Keep duplicate initial states: each saved response contributes 12 states.
states = [s.responses{1}.states(:,1:12), s.responses{2}.states(:,1:12)];
state_count = size(states,2);
origin = [repmat(names(1),12,1); repmat(names(2),12,1)];
cycle = repmat((0:11)',2,1);
assert(state_count == 24 && all(isfinite(states(:))));
warmup_blocks = 42; measured_blocks = 240;
assert(warmup_blocks*state_count >= 1000);
assert(measured_blocks*state_count >= 5000);

% First observations precede both validation calls and deliberate warmup.
% These are process-first controller calls, not machine-cache cold bounds.
x = states(:,1);
cold_seconds = zeros(2,1);
for method = 1:2
    started = tic;
    [offsets,dwell] = controller_call(method,x,b,c,p);
    cold_seconds(method) = toc(started);
    assert(norm(offsets-s.responses{method}.offsets(2:end,1),inf) < 1e-12);
    assert(norm(dwell-s.responses{method}.dwell(:,1),inf) < 1e-12);
end
cold = table(names',cold_seconds,'VariableNames',{'method','seconds'});

% Check every source action and schedule before collecting warmed timings.
reference_offsets = zeros(numel(b.nominal_dwell)-1,state_count,2);
dwell_active = false(state_count,2);
conditioned = false(state_count,2);
action_differs_from_lqr = false(state_count,2);
for id = 1:state_count
    x = states(:,id);
    raw = -c.K_aggressive_physical*(x-b.orbit_anchor);
    for method = 1:2
        [offsets,dwell,beta] = controller_call(method,x,b,c,p);
        reference_offsets(:,id,method) = offsets;
        dwell_active(id,method) = any(dwell <= b.applied_schedule_dwell_bound+1e-12);
        conditioned(id,method) = isfinite(beta) && beta < 1-1e-12;
        action_differs_from_lqr(id,method) = norm(offsets-raw,inf) > 1e-10;
        if origin(id) == names(method)
            k = cycle(id)+1; r = s.responses{method};
            assert(norm(offsets-r.offsets(2:end,k),inf) < 1e-12);
            assert(norm(dwell-r.dwell(:,k),inf) < 1e-12);
        end
    end
end
state_table = table((1:state_count)',origin,cycle,states(1,:)',states(2,:)', ...
    states(3,:)',vecnorm(b.state_scale\(states-b.orbit_anchor),2,1)', ...
    'VariableNames',{'state_id','source_method','source_cycle','vc1_v', ...
    'vc2_v','il_a','normalized_error'});

% State selection and post-call checksums stay outside each timed interval.
% Alternate the leading controller by block and state, never batch one method.
checksum = 0;
for block = 1:warmup_blocks
    for id = 1:state_count
        x = states(:,id);
        order = 1:2;
        if mod(block+id,2) == 0, order = [2,1]; end
        for method = order
            [offsets,dwell] = controller_call(method,x,b,c,p);
            checksum = checksum + sum(offsets) + sum(dwell);
        end
    end
end
count = measured_blocks*state_count*2;
method_id = zeros(count,1); state_id = zeros(count,1);
block_id = zeros(count,1); pair_order = zeros(count,1);
seconds = zeros(count,1); row = 0;
for block = 1:measured_blocks
    for id = 1:state_count
        x = states(:,id);
        order = 1:2;
        if mod(block+id,2) == 0, order = [2,1]; end
        for position = 1:2
            method = order(position);
            started = tic;
            [offsets,dwell] = controller_call(method,x,b,c,p);
            elapsed = toc(started);
            row = row+1;
            seconds(row) = elapsed;
            method_id(row) = method; state_id(row) = id;
            block_id(row) = block; pair_order(row) = position;
            assert(norm(offsets-reference_offsets(:,id,method),inf) < 1e-12);
            checksum = checksum + sum(offsets) + sum(dwell);
        end
    end
end
assert(isfinite(checksum) && all(isfinite(seconds)) && all(seconds > 0));
indices = sub2ind(size(dwell_active),state_id,method_id);
samples = table(names(method_id)',block_id,state_id,pair_order,seconds, ...
    dwell_active(indices),conditioned(indices),action_differs_from_lqr(indices), ...
    'VariableNames',{'method','block','state_id','order_in_pair','seconds', ...
    'dwell_active','conditioned','action_differs_from_lqr'});
summary = table(); state_summary = table();
for method = 1:2
    rows = samples.method == names(method);
    assert(sum(rows) == measured_blocks*state_count);
    assert(sum(samples.order_in_pair(rows) == 1) == sum(rows)/2);
    summary = [summary; timing_row(names(method),samples.seconds(rows))]; %#ok<AGROW>
    for id = 1:state_count
        rows = samples.method == names(method) & samples.state_id == id;
        assert(sum(rows) == measured_blocks);
        t = timing_row(names(method),samples.seconds(rows));
        t.state_id = id; t.source_method = origin(id); t.source_cycle = cycle(id);
        t.dwell_active = dwell_active(id,method);
        t.conditioned = conditioned(id,method);
        t.action_differs_from_lqr = action_differs_from_lqr(id,method);
        state_summary = [state_summary; t]; %#ok<AGROW>
    end
end

% Timer-only observations are reported, never subtracted from controller times.
timer_seconds = zeros(measured_blocks*state_count,1);
for k = 1:numel(timer_seconds)
    started = tic;
    timer_seconds(k) = toc(started);
end
timer_baseline = table(timer_seconds,'VariableNames',{'seconds'});
timer_summary = timing_row("timer-only",timer_seconds);
environment = struct();
environment.timestamp = char(datetime('now','TimeZone','local'));
environment.matlab_version = version;
environment.matlab_release = version('-release');
environment.computer = computer;
environment.hostname = getenv('COMPUTERNAME');
environment.processor = getenv('PROCESSOR_IDENTIFIER');
environment.logical_processors = getenv('NUMBER_OF_PROCESSORS');
environment.max_computation_threads = maxNumCompThreads;
environment.os = char(java.lang.System.getProperty('os.name'));
environment.os_version = char(java.lang.System.getProperty('os.version'));
environment.toolboxes = [ver('matlab'),ver('optim'),ver('control')];
environment.solver = 'quadprog';
environment.solver_options = struct('Algorithm',p.solver_options.Algorithm, ...
    'Display',p.solver_options.Display, ...
    'ConstraintTolerance',p.solver_options.ConstraintTolerance, ...
    'OptimalityTolerance',p.solver_options.OptimalityTolerance, ...
    'StepTolerance',p.solver_options.StepTolerance, ...
    'MaxIterations',p.solver_options.MaxIterations, ...
    'ObjectiveLimit',p.solver_options.ObjectiveLimit, ...
    'UseCodegenSolver',p.solver_options.UseCodegenSolver);
environment.warm_start_policy = 'Native Mpc.solve: zeros(plan_size,1) on EVERY call; no reused plan.';
environment.workload = ['First 12 cycle-start physical states from each saved 1x response, ' ...
    '24 states including duplicates; identical pool for both controllers; no propagation.'];
environment.order = 'For each block and state, alternate [1,2]/[2,1] by parity of block+state.';
environment.warmup_calls_per_controller = warmup_blocks*state_count;
environment.measured_calls_per_controller = measured_blocks*state_count;
environment.included = ['Function dispatch, physical error x-anchor, Daniel physical gain and ' ...
    'condition_dwell_times OR MPC state normalization, native QP solve, first-action extraction ' ...
    'and physical schedule conversion; common finite-offset/dwell, minimum-dwell and period checks.'];
environment.excluded = ['MAT loading, offline design/build, state selection, output checksum and ' ...
    'reference-action comparison, plant propagation, plotting, file export.'];
environment.timer_policy = 'Individual tic/toc calls; timer overhead retained, not subtracted.';
environment.cold_policy = ['One first call per controller on the shared initial state, Daniel first, ' ...
    'before validation/warmup; shared helpers may already be loaded by Daniel before MPC.'];
environment.label_policy = ['dwell_active: min dwell within 1e-12 s of bound; conditioned: ' ...
    'Daniel beta<1-1e-12; action_differs_from_lqr: offset infinity error >1e-10 s, ' ...
    'not a claim about the full QP active set.'];
measured_sources = {mfilename('fullpath'),which('condition_dwell_times'), ...
    which('Mpc.solve'),which('quadprog'),source};
measured_sources{1} = [measured_sources{1},'.m'];
source_hashes = struct('path',measured_sources,'sha256',cell(size(measured_sources)));
for k = 1:numel(source_hashes)
    source_hashes(k).sha256 = sha256(source_hashes(k).path);
end
environment.source_hashes = source_hashes;

writetable(samples,fullfile(output,'samples.csv'));
writetable(summary,fullfile(output,'summary.csv'));
writetable(state_summary,fullfile(output,'state_summary.csv'));
writetable(state_table,fullfile(output,'states.csv'));
writetable(cold,fullfile(output,'cold.csv'));
writetable(timer_baseline,fullfile(output,'timer_baseline.csv'));
writetable(timer_summary,fullfile(output,'timer_summary.csv'));
fid = fopen(fullfile(output,'environment.json'),'w'); assert(fid ~= -1);
close_file = onCleanup(@() fclose(fid));
fprintf(fid,'%s\n',jsonencode(environment,PrettyPrint=true));
clear close_file;
copyfile([mfilename('fullpath'),'.m'],fullfile(output,'benchmark_matched_timing.m'));
save(fullfile(output,'timing.mat'),'samples','summary','state_summary','state_table', ...
    'cold','timer_baseline','timer_summary','environment','checksum','reference_offsets');

% Re-read exported numbers, checking aggregate and per-state summaries.
exported_samples = readtable(fullfile(output,'samples.csv'),TextType='string');
exported_summary = readtable(fullfile(output,'summary.csv'),TextType='string');
exported_states = readtable(fullfile(output,'state_summary.csv'),TextType='string');
for k = 1:height(exported_summary)
    r = exported_summary(k,:);
    expected = timing_row(r.method,exported_samples.seconds(exported_samples.method == r.method));
    assert(r.count == expected.count);
    assert(max(abs(r{1,3:6}-expected{1,3:6})) < 1e-8);
end
for k = 1:height(exported_states)
    r = exported_states(k,:);
    rows = exported_samples.method == r.method & exported_samples.state_id == r.state_id;
    expected = timing_row(r.method,exported_samples.seconds(rows));
    assert(r.count == expected.count);
    assert(max(abs(r{1,3:6}-expected{1,3:6})) < 1e-8);
end
disp(summary); disp(timer_summary);
fprintf('Matched timing checks passed. Outputs: %s\n',output);
end

function [offsets,dwell,beta] = controller_call(method,x,b,c,p)
error = x-b.orbit_anchor;
beta = NaN;
if method == 1
    raw = -c.K_aggressive_physical*error;
    [offsets,beta,dwell] = condition_dwell_times( ...
        b.config.Ts(:),raw,b.applied_schedule_dwell_bound);
else
    normalized_error = b.state_scale\error;
    [v,~,flag] = Mpc.solve(p,normalized_error);
    assert(flag == 1,'MPC QP failed; no fallback or failed candidate is timed as success.');
    offsets = b.timing_scale*v;
    dwell = diff(b.config.Ts(:)+[0;offsets;0]);
end
assert(all(isfinite(offsets)) && all(isfinite(dwell)));
assert(all(dwell >= b.applied_schedule_dwell_bound-1e-12));
assert(abs(sum(dwell)-b.period) < 1e-12);
end

function row = timing_row(method,seconds)
us = seconds*1e6;
row = table(method,numel(us),median(us),prctile(us,95),prctile(us,99),max(us), ...
    'VariableNames',{'method','count','median_us','p95_us','p99_us','max_us'});
end

function value = sha256(path)
fid = fopen(path,'rb'); assert(fid ~= -1);
close_file = onCleanup(@() fclose(fid));
bytes = fread(fid,Inf,'*uint8');
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(bytes);
value = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[]));
end
