function comparison = simulate_comparison()
%SIMULATE_COMPARISON Three fixed-period policies on the unchanged exact plant.
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'scripts'));
paths = paper.paths();
addpath(paths.simulation);
addpath(fullfile(root,'studies','mpc-comparison'));
output = fullfile(here,'results');
synthesis = jsondecode(fileread(fullfile(output,'synthesis.json')));
b = paper.benchmark();
model = paper.validate_model(b);
c = paper.design_feedback(b,model);
assert(b.cycle_count == 100 && numel(b.nominal_dwell) == 9);
assert(b.period == 286e-6 && b.applied_schedule_dwell_bound == 3e-6);
assert(b.aggressive_input_weight == 0.001);
validate_synthesis(synthesis,b,model,c);
problem = mpc_problem(b,model,5);
names = {'current','mpc5','kawa_decay'};
gains = {c.K_aggressive_physical,[],synthesis.candidates.decay.Kphysical};
nmethods = numel(names);
responses = cell(3,nmethods);
summary = table(); history = table(); commands = table(); trajectories = table();
for scale = 1:3
    initial = b.orbit_anchor + scale*(b.initial_state-b.orbit_anchor);
    saved = load(fullfile(root,'studies','mpc-comparison','results', ...
        sprintf('error-scale-%dx',scale),'study.mat'),'study');
    assert(isequal(saved.study.names,{'daniel','mpc-5'}));
    assert(saved.study.error_scale == scale);
    trajectories = [trajectories; dense_reference(b,scale)]; %#ok<AGROW>
    for method = 1:nmethods
        r = simulate(b,problem,gains{method},initial);
        if method <= 2
            verify_baseline(r,saved.study.responses{method});
        end
        if scale == 1 && method == 1
            verify_article(r,fullfile(paths.results,'conditioned_control_response.csv'));
        end
        dense = dense_response(b,r,names{method},scale);
        extrema = min([r.states'; dense{:,4:6}],[],1);
        summary = [summary; score(r,names{method},scale,extrema)]; %#ok<AGROW>
        history = [history; history_rows(b,r,names{method},scale)]; %#ok<AGROW>
        commands = [commands; command_rows(r,names{method},scale)]; %#ok<AGROW>
        trajectories = [trajectories; dense]; %#ok<AGROW>
        responses{scale,method} = r;
    end
end
assert(height(summary) == 3*nmethods && height(history) == 3*nmethods*101);
assert(height(commands) == 3*nmethods*100*9);
metadata = struct('matlab_release',version('-release'),'matlab_version',version, ...
    'computer',computer,'processor',getenv('PROCESSOR_IDENTIFIER'), ...
    'dense_horizon_cycles',12,'samples_per_interval',30);
metadata.extrema_scope = ['Minimum over all 101 saved cycle states and exact ' ...
    'samples from the first 12 cycles, 30 samples per mode interval on each method''s ' ...
    'own switching grid. Not continuous-time global extrema over 100 cycles.'];
metadata.evaluation_cost = 'J100 = sum(error(1:100).^2) + 0.001*sum((applied_offsets/timing_scale).^2,all).';
metadata.threshold = ['Strict error < 0.01; first crossing and persistent crossing ' ...
    'are separate, zero-based completed-cycle indices; NaN means no crossing.'];
metadata.mpc_action = 'Native Mpc.solve, zero initial plan, exitflag 1 required; no fallback or postconditioning. Raw equals applied; beta is NaN.';
metadata.command_boundary_offsets = 'Each command row stores the start-boundary offset; interval 1 starts at zero and the final end boundary has zero offset.';
writetable(summary,fullfile(output,'summary.csv'));
writetable(history,fullfile(output,'history.csv'));
writetable(commands,fullfile(output,'commands.csv'));
writetable(trajectories,fullfile(output,'trajectories.csv'));
[timing_summary,environment] = benchmark_timing(b,problem,gains,responses,output);
metadata.environment = environment;
save(fullfile(output,'comparison.mat'),'b','model','c','problem','names', ...
    'responses','synthesis','metadata','summary','timing_summary');
comparison = struct('b',b,'model',model,'c',c,'problem',problem, ...
    'names',{names},'responses',{responses},'synthesis',synthesis, ...
    'metadata',metadata,'summary',summary,'timing_summary',timing_summary);
disp(summary);
fprintf('Kawa synthesis comparison outputs: %s\n',output);
end

function validate_synthesis(s,b,model,c)
relative_match(s.A,b.state_scale\model.Phi*b.state_scale,'normalized A');
relative_match(s.B,b.state_scale\model.Gamma*b.timing_scale,'normalized B');
relative_match(s.K_current,c.K_aggressive_normalized,'current normalized gain');
relative_match(s.boundaries_us(:),b.config.Ts(:)*1e6,'nominal boundaries');
relative_match(s.state_scale,b.state_scale,'state scale');
relative_match(s.timing_scale,b.timing_scale,'timing scale');
assert(isequal(size(s.P_current),[3,3]) && all(isfinite(s.P_current(:))));
candidate = s.candidates.decay;
assert(isequal(size(candidate.K),[8,3]));
assert(isequal(size(candidate.P),[3,3]) && all(isfinite(candidate.P(:))));
assert(numel(candidate.endpoint_decreases) == 2 && ...
    all(isfinite(candidate.endpoint_decreases(:))));
relative_match(candidate.Kphysical, ...
    b.timing_scale*candidate.K/b.state_scale,'decay physical gain');
radius = max(abs(eig(s.A-s.B*candidate.K)));
relative_match(candidate.raw_radius,radius,'decay raw radius');
end

function relative_match(actual,expected,label)
assert(isequal(size(actual),size(expected)) && all(isfinite(actual(:))), ...
    'Invalid synthesis dimensions or values: %s.',label);
assert(norm(actual-expected,'fro') <= 1e-8*max(norm(expected,'fro'),realmin), ...
    'Synthesis disagrees with fresh MATLAB inputs: %s.',label);
end

function r = simulate(b,problem,gain,initial)
N = b.cycle_count;
r = struct('states',NaN(3,N+1),'error',NaN(N+1,1), ...
    'raw_offsets',NaN(8,N),'applied_offsets',NaN(8,N), ...
    'dwell',NaN(9,N),'raw_dwell',NaN(9,N),'beta',NaN(N,1), ...
    'exitflag',NaN(N,1),'completed_cycles',0);
r.states(:,1) = initial;
for k = 1:N
    error = r.states(:,k)-b.orbit_anchor;
    if isempty(gain)
        [v,~,r.exitflag(k)] = Mpc.solve(problem,b.state_scale\error);
        assert(r.exitflag(k) == 1, ...
            'MPC failed at cycle %d; no fallback or failed action is accepted.',k);
        raw = b.timing_scale*v;
        applied = raw;
        dwell = diff(b.config.Ts(:)+[0;applied;0]);
    else
        raw = -gain*error;
        [applied,r.beta(k),dwell] = condition_dwell_times( ...
            b.config.Ts(:),raw,b.applied_schedule_dwell_bound);
        assert(r.beta(k) >= 0 && r.beta(k) <= 1);
    end
    raw_dwell = diff(b.config.Ts(:)+[0;raw;0]);
    assert(all(isfinite([raw;applied;raw_dwell;dwell])));
    assert(all(dwell >= 3e-6-1e-12));
    assert(abs(sum(dwell)-286e-6) < 1e-12);
    assert(abs(sum(raw_dwell)-286e-6) < 1e-12);
    r.raw_offsets(:,k) = raw;
    r.applied_offsets(:,k) = applied;
    r.raw_dwell(:,k) = raw_dwell;
    r.dwell(:,k) = dwell;
    r.states(:,k+1) = paper.exact_cycle(b.config,r.states(:,k),applied);
    assert(all(isfinite(r.states(:,k+1))));
    r.completed_cycles = k;
end
r.error = vecnorm(b.state_scale\(r.states-b.orbit_anchor),2,1)';
r.stage_cost = r.error(1:N).^2 + ...
    0.001*sum((r.applied_offsets/b.timing_scale).^2,1)';
r.cumulative_cost = [0;cumsum(r.stage_cost)];
end

function verify_baseline(r,old)
assert(old.completed_cycles == 100 && r.completed_cycles == 100);
assert(max(abs(r.states-old.states),[],'all') < 1e-8, ...
    'Baseline state trajectory differs from the existing MPC study.');
assert(max(abs(r.error-old.error)) < 1e-8);
assert(max(abs(r.applied_offsets-old.offsets(2:end,:)),[],'all') < 1e-12);
assert(max(abs(r.dwell-old.dwell),[],'all') < 1e-12);
assert(isequal(isnan(r.beta),isnan(old.beta)));
assert(isequal(isnan(r.exitflag),isnan(old.exitflag)));
finite = isfinite(r.beta);
assert(all(abs(r.beta(finite)-old.beta(finite)) < 1e-8));
finite = isfinite(r.exitflag);
assert(isequal(r.exitflag(finite),old.exitflag(finite)));
end

function verify_article(r,path)
a = readtable(path);
assert(height(a) == 101 && isequal(a.cycle,(0:100)'));
assert(max(abs(r.error-a.conditioned_error)) < 1e-8);
x = [a.conditioned_vc1_v,a.conditioned_vc2_v,a.conditioned_il_a]';
assert(max(abs(r.states-x),[],'all') < 1e-8);
assert(max(abs(r.beta-a.beta(1:100))) < 1e-8);
for j = 1:8
    raw = a.(sprintf('raw_offset_%d_us',j));
    applied = a.(sprintf('applied_offset_%d_us',j));
    assert(max(abs(r.raw_offsets(j,:)'*1e6-raw(1:100))) < 1e-8);
    assert(max(abs(r.applied_offsets(j,:)'*1e6-applied(1:100))) < 1e-8);
end
for j = 1:9
    raw = a.(sprintf('raw_dwell_%d_us',j));
    applied = a.(sprintf('applied_dwell_%d_us',j));
    assert(max(abs(r.raw_dwell(j,:)'*1e6-raw(1:100))) < 1e-8);
    assert(max(abs(r.dwell(j,:)'*1e6-applied(1:100))) < 1e-8);
end
end

function row = score(r,name,scale,extrema)
first = find(r.error < 0.01,1)-1;
if isempty(first), first = NaN; end
last_bad = find(r.error >= 0.01,1,'last');
sustained = NaN;
if isempty(last_bad)
    sustained = 0;
elseif last_bad < numel(r.error)
    sustained = last_bad;
end
minimum_beta = NaN; conditioned = 0;
if any(isfinite(r.beta))
    minimum_beta = min(r.beta);
    conditioned = sum(r.beta < 1-1e-12);
end
row = table(string(name),scale,r.completed_cycles,first,sustained, ...
    r.cumulative_cost(end),r.error(end),min(r.dwell,[],'all')*1e6, ...
    min(r.raw_dwell,[],'all')*1e6,minimum_beta,conditioned, ...
    extrema(1),extrema(2),extrema(3),'VariableNames', ...
    {'method','error_scale','completed_cycles','first_cycle_below_001', ...
    'sustained_cycle_below_001','evaluation_cost','final_error', ...
    'minimum_dwell_us','minimum_raw_dwell_us','minimum_beta', ...
    'conditioned_cycles','min_vc1_v','min_vc2_v','min_il_a'});
end

function rows = history_rows(b,r,name,scale)
k = (0:100)';
rows = table(repmat(string(name),101,1),repmat(scale,101,1),k, ...
    k*b.period*1e3,r.states(1,:)',r.states(2,:)',r.states(3,:)', ...
    r.error,[r.beta;NaN],[min(r.dwell,[],1)'*1e6;NaN], ...
    [min(r.raw_dwell,[],1)'*1e6;NaN],[r.stage_cost;NaN], ...
    r.cumulative_cost,'VariableNames',{'method','error_scale','cycle', ...
    'time_ms','vc1_v','vc2_v','il_a','normalized_error','beta', ...
    'minimum_dwell_us','minimum_raw_dwell_us','stage_cost','cumulative_cost'});
end

function rows = command_rows(r,name,scale)
raw_start = [zeros(1,100);r.raw_offsets];
applied_start = [zeros(1,100);r.applied_offsets];
rows = table(repmat(string(name),900,1),repmat(scale,900,1), ...
    repelem((0:99)',9),repmat((1:9)',100,1),r.raw_dwell(:)*1e6, ...
    r.dwell(:)*1e6,raw_start(:)*1e6,applied_start(:)*1e6, ...
    'VariableNames',{'method','error_scale','cycle','interval', ...
    'raw_dwell_us','applied_dwell_us','raw_boundary_offset_us', ...
    'applied_boundary_offset_us'});
end

function rows = dense_response(b,r,name,scale)
times = 0; states = r.states(:,1)';
for k = 1:12
    [t,x] = paper.sample_cycle(b.config,r.states(:,k),r.applied_offsets(:,k),30);
    assert(norm(x(end,:)'-r.states(:,k+1),inf) < 1e-9, ...
        'Dense endpoint disagrees with the saved exact cycle state.');
    times = [times;(k-1)*b.period+t(2:end)]; %#ok<AGROW>
    states = [states;x(2:end,:)]; %#ok<AGROW>
end
rows = table(repmat(string(name),numel(times),1),repmat(scale,numel(times),1), ...
    times*1e3,states(:,1),states(:,2),states(:,3),'VariableNames', ...
    {'method','error_scale','time_ms','vc1_v','vc2_v','il_a'});
end

function rows = dense_reference(b,scale)
[t,x] = paper.sample_cycle(b.config,b.orbit_anchor,zeros(8,1),30);
assert(norm(x(end,:)'-b.orbit_anchor,inf) < 1e-9);
times = 0; states = b.orbit_anchor';
for k = 1:12
    times = [times;(k-1)*b.period+t(2:end)]; %#ok<AGROW>
    states = [states;x(2:end,:)]; %#ok<AGROW>
end
rows = table(repmat("reference",numel(times),1),repmat(scale,numel(times),1), ...
    times*1e3,states(:,1),states(:,2),states(:,3),'VariableNames', ...
    {'method','error_scale','time_ms','vc1_v','vc2_v','il_a'});
end
