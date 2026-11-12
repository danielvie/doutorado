function [summary,environment] = benchmark_timing(b,problem,gains,responses,output)
%BENCHMARK_TIMING Matched host physical-state-to-validated-schedule timings.
% State selection, propagation and file I/O stay outside measured intervals.
% The native MPC solver retains its zero initial plan on every call.
names = ["current","mpc5","kawa_decay"];
nmethods = numel(names);
nstates = 12*nmethods;
warmup_passes = 2;
timed_passes = 20;
assert(isequal(size(responses),[3,nmethods]) && numel(gains) == nmethods);
assert(isempty(gains{2}));
assert(problem.prediction_horizon == 5 && problem.update_period_cycles == 1);
assert(~problem.prediction.uses_previous_action);
assert(strcmp(problem.solver_options.Algorithm,'active-set'));
assert(b.period == 286e-6 && b.applied_schedule_dwell_bound == 3e-6);
for method = [1,3:nmethods]
    assert(isequal(size(gains{method}),[8,3]) && all(isfinite(gains{method}(:))));
end

% Keep duplicates, including the initial state contributed by every policy.
states = zeros(3,nstates);
for method = 1:nmethods
    assert(responses{1,method}.completed_cycles == 100);
    states(:,(method-1)*12+(1:12)) = responses{1,method}.states(:,1:12);
end
assert(all(isfinite(states(:))));
source_method = repelem(names',12);
source_cycle = repmat((0:11)',nmethods,1);
state_table = table((1:nstates)',source_method,source_cycle,states(1,:)', ...
    states(2,:)',states(3,:)', ...
    'VariableNames',{'state_index','source_method','source_cycle', ...
    'vc1_v','vc2_v','il_a'});

% First benchmark observations, not process-first calls or cache-cold bounds.
x = states(:,1);
cold_us = zeros(nmethods,1);
for method = 1:nmethods
    gain = gains{method};
    started = tic;
    [offsets,dwell] = controller_call(method,x,b,problem,gain);
    cold_us(method) = toc(started)*1e6;
    r = responses{1,method};
    assert(norm(offsets-r.applied_offsets(:,1),inf) < 1e-12);
    assert(norm(dwell-r.dwell(:,1),inf) < 1e-12);
end

% Two complete passes cover the shared state pool for every method.
reference_offsets = zeros(8,nstates,nmethods);
checksum = 0;
for pass = 1:warmup_passes
    for id = 1:nstates
        x = states(:,id);
        order = mod((0:nmethods-1)+pass+id-2,nmethods)+1;
        for method = order
            gain = gains{method};
            [offsets,dwell] = controller_call(method,x,b,problem,gain);
            if pass == 1
                reference_offsets(:,id,method) = offsets;
                if source_method(id) == names(method)
                    r = responses{1,method}; k = source_cycle(id)+1;
                    assert(norm(offsets-r.applied_offsets(:,k),inf) < 1e-12);
                    assert(norm(dwell-r.dwell(:,k),inf) < 1e-12);
                end
            else
                assert(norm(offsets-reference_offsets(:,id,method),inf) < 1e-12);
            end
            checksum = checksum + sum(offsets) + sum(dwell);
        end
    end
end

% Rotate the leading method deterministically for each state and pass.
count = nmethods*nstates*timed_passes;
method_id = zeros(count,1); state_index = zeros(count,1);
repeat = zeros(count,1); elapsed_us = zeros(count,1); row = 0;
for pass = 1:timed_passes
    for id = 1:nstates
        x = states(:,id);
        order = mod((0:nmethods-1)+pass+id-2,nmethods)+1;
        for method = order
            gain = gains{method};
            started = tic;
            [offsets,dwell] = controller_call(method,x,b,problem,gain);
            elapsed = toc(started)*1e6;
            row = row+1;
            method_id(row) = method; state_index(row) = id;
            repeat(row) = pass; elapsed_us(row) = elapsed;
            assert(norm(offsets-reference_offsets(:,id,method),inf) < 1e-12);
            checksum = checksum + sum(offsets) + sum(dwell);
        end
    end
end
assert(row == count && all(isfinite(elapsed_us)) && all(elapsed_us > 0));
assert(isfinite(checksum));
method_names = names(method_id);
samples = table(method_names(:),state_index,repeat,elapsed_us, ...
    'VariableNames',{'method','state_index','repeat','elapsed_us'});
summary = table();
for method = 1:nmethods
    rows = method_id == method;
    assert(sum(rows) == nstates*timed_passes);
    for id = 1:nstates
        assert(sum(rows & state_index == id) == timed_passes);
    end
    us = elapsed_us(rows);
    summary = [summary; table(names(method),numel(us),nstates*warmup_passes,median(us), ...
        prctile(us,95),cold_us(method),'VariableNames', ...
        {'method','samples','warmup_calls','median_us','p95_us','cold_us'})]; %#ok<AGROW>
end

environment = struct();
environment.matlab_version = version;
environment.matlab_release = version('-release');
environment.computer = computer;
environment.processor = getenv('PROCESSOR_IDENTIFIER');
if isempty(environment.processor)
    environment.processor = char(java.lang.System.getProperty('os.arch'));
end
environment.solver = 'Native Mpc.solve / quadprog active-set; zero initial plan on every call.';
environment.workload = sprintf(['%d physical cycle-start states: first 12 from each 1x response, ' ...
    'including duplicates; identical pool for all %d methods.'],nstates,nmethods);
environment.warmup_calls_per_method = nstates*warmup_passes;
environment.measured_calls_per_method = nstates*timed_passes;
environment.order = sprintf( ...
    'For each pass and state, order = mod((0:%d)+pass+state_index-2,%d)+1.', ...
    nmethods-1,nmethods);
environment.included = ['Function dispatch, physical error x-anchor, gain and native conditioner ' ...
    'or required state normalization, native QP solve and physical action conversion; ' ...
    'finite action/dwell, minimum dwell and period checks.'];
environment.excluded = ['Input selection, offline construction, plant propagation, reference-action ' ...
    'comparison, checksums, file I/O.'];
environment.cold_policy = ['cold_us is the first observation within this benchmark, before its ' ...
    'warmup but after trajectory simulation; method order ' char(strjoin(names,', ')) '. ' ...
    'It is not process-cold or cache-cold timing.'];
environment.timer_policy = 'Individual tic/toc; timer overhead retained, not subtracted.';
environment.scope = 'Host MATLAB elapsed-time observations only; no embedded or worst-case execution-time claim.';
summary.Properties.UserData = environment;
writetable(summary,fullfile(output,'timing.csv'));
writetable(samples,fullfile(output,'timing_samples.csv'));
writetable(state_table,fullfile(output,'timing_states.csv'));
save(fullfile(output,'timing.mat'),'summary','samples','state_table', ...
    'environment','reference_offsets','checksum');
end

function [offsets,dwell] = controller_call(method,x,b,problem,gain)
error = x-b.orbit_anchor;
if method == 2
    [v,~,flag] = Mpc.solve(problem,b.state_scale\error);
    assert(flag == 1,'MPC failed; no fallback or failed action is accepted.');
    offsets = b.timing_scale*v;
    dwell = diff(b.config.Ts(:)+[0;offsets;0]);
else
    raw = -gain*error;
    [offsets,~,dwell] = condition_dwell_times( ...
        b.config.Ts(:),raw,b.applied_schedule_dwell_bound);
end
assert(isequal(size(offsets),[8,1]) && isequal(size(dwell),[9,1]));
assert(all(isfinite(offsets)) && all(isfinite(dwell)));
assert(all(dwell >= 3e-6-1e-12));
assert(abs(sum(dwell)-286e-6) < 1e-12);
end
