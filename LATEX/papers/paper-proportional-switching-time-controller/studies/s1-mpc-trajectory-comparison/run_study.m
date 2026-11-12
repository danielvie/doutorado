function evidence = run_study()
%RUN_STUDY Fresh original-1x responses; no publication/study output writes.
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root,'scripts'),fullfile(root,'studies','mpc-comparison'));
paths = paper.paths(); addpath(paths.simulation);
b = paper.benchmark(); model = paper.validate_model(b);
c = paper.design_feedback(b,model); problem = mpc_problem(b,model,5);
source = load(fullfile(root,'studies','mpc-comparison','results','error-scale-1x','study.mat'));
s = source.study;
d = s.responses{find(string(s.names)=="daniel")};
response = struct('conditioned_states',d.states,'applied_offsets',d.offsets(2:end,:), ...
    'conditioned_error',d.error);
% Reuse the article's full setup/plant/QP/terminal-set/reference validator.
checked = paper.mpc_comparison_data(s,b,model,c,response);
publication = load(fullfile(paths.results,'publication_trajectories.mat'));
data = publication.trajectories;
assert(data.samples_per_interval == b.trajectory_samples_per_interval);
N = b.cycle_count; m = numel(b.nominal_dwell)-1;
names = {'Proposed controller','MPC-5'}; responses = cell(1,2);
for method = 1:2
    r = struct('states',zeros(3,N+1),'offsets',zeros(m,N), ...
        'dwell',zeros(m+1,N),'exitflag',NaN(N,1),'completed_cycles',0);
    r.states(:,1) = b.initial_state;
    for k = 1:N
        z = b.state_scale\(r.states(:,k)-b.orbit_anchor);
        if method == 1
            raw = -c.K_aggressive_physical*(r.states(:,k)-b.orbit_anchor);
            [offsets,~,dwell] = condition_dwell_times(b.config.Ts(:),raw,b.applied_schedule_dwell_bound);
        else
            [v,~,r.exitflag(k)] = Mpc.solve(problem,z);
            if r.exitflag(k) ~= 1
                failure = struct('method',names{method},'cycle',k,'exitflag',r.exitflag(k),'partial',r);
                save(fullfile(here,'failed-solve.mat'),'failure');
                error('MPC-5 failed at cycle %d, exitflag %d. No fallback applied.',k,r.exitflag(k));
            end
            offsets = b.timing_scale*v;
            dwell = diff(b.config.Ts(:)+[0;offsets;0]);
        end
        assert(all(dwell >= b.applied_schedule_dwell_bound-1e-12));
        assert(abs(sum(dwell)-b.period) < 1e-12);
        r.offsets(:,k) = offsets; r.dwell(:,k) = dwell;
        r.states(:,k+1) = paper.exact_cycle(b.config,r.states(:,k),offsets);
        r.completed_cycles = k;
    end
    r.error = vecnorm(b.state_scale\(r.states-b.orbit_anchor),2,1)';
    per_cycle = b.trajectory_samples_per_interval*numel(b.nominal_dwell);
    r.time = zeros(N*per_cycle+1,1); r.dense = zeros(N*per_cycle+1,3);
    r.interval_endpoint_residual = zeros(N,1);
    for k = 1:N
        [t,x] = paper.sample_cycle(b.config,r.states(:,k),r.offsets(:,k),b.trajectory_samples_per_interval);
        boundaries = paper.cycle_boundaries(b.config,r.states(:,k),r.offsets(:,k));
        r.interval_endpoint_residual(k) = max(abs(x(1:b.trajectory_samples_per_interval:end,:)'-boundaries),[],'all');
        assert(norm(x(end,:)'-r.states(:,k+1),inf) < 1e-11);
        rows = (k-1)*per_cycle+(1:per_cycle+1);
        r.time(rows) = (k-1)*b.period+t; r.dense(rows,:) = x;
    end
    responses{method} = r;
end
% Save the unchanged long-open-loop record locally with fresh controller data.
evidence = struct('benchmark',b,'model',model,'controller',c,'problem',problem, ...
    'names',{names},'responses',{responses},'publication',data, ...
    'reference_mpc',checked,'reference_proposed',d,'matlab_version',version,'computer',computer);
save(fullfile(here,'evidence.mat'),'evidence');
check_study();
end
