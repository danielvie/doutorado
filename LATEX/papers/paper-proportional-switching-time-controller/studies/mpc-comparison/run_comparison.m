function studies = run_comparison()
%RUN_COMPARISON Isolated article-controller/MPC evidence at 1x, 2x, and 3x.
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, 'scripts'));
paths = paper.paths();
addpath(paths.simulation);
b = paper.benchmark();
model = paper.validate_model(b);
c = paper.design_feedback(b, model);
problems = {[], mpc_problem(b, model, 5)};
names = {'daniel', 'mpc-5'};
output = fullfile(here, 'results');
if ~isfolder(output), mkdir(output); end
studies = cell(3,1);
metrics = table();
for scale = 1:3
    case_dir = fullfile(output, sprintf('error-scale-%dx', scale));
    if ~isfolder(case_dir), mkdir(case_dir); end
    initial_state = b.orbit_anchor + scale*(b.initial_state - b.orbit_anchor);
    responses = cell(numel(names),1);
    history = table(); dwell_history = table(); first_dwell = table();
    for i = 1:numel(names)
        r = simulate(b, model, c, problems{i}, initial_state);
        responses{i} = r;
        if i == 1 && scale == 1
            saved = readtable(fullfile(paths.results, 'conditioned_control_response.csv'));
            assert(max(abs(r.error - saved.conditioned_error)) < 1e-8, ...
                'Daniel differs from the article evidence.');
        end
        k = (0:b.cycle_count)';
        history = [history; table(repmat(string(names{i}),numel(k),1), k, ...
            k*b.period*1e3, r.states(1,:)', r.states(2,:)', r.states(3,:)', ...
            r.error, [r.beta;NaN], [min(r.dwell,[],1)';NaN]*1e6, ...
            [r.exitflag;NaN], [r.compute_seconds;NaN]*1e3, ...
            [r.prediction_residual;NaN], 'VariableNames', ...
            {'method','cycle','time_ms','vc1_v','vc2_v','il_a','normalized_error', ...
            'beta','minimum_dwell_us','qp_exitflag','compute_ms', ...
            'next_cycle_prediction_residual'})]; %#ok<AGROW>
        for cycle = 1:r.completed_cycles
            intervals = (1:numel(b.nominal_dwell))';
            dwell_history = [dwell_history; table( ...
                repmat(string(names{i}),numel(intervals),1), ...
                repmat(cycle,numel(intervals),1), intervals, r.dwell(:,cycle)*1e6, ...
                r.offsets(:,cycle)*1e6, 'VariableNames', ...
                {'method','cycle','interval','dwell_us','boundary_start_offset_us'})]; %#ok<AGROW>
        end
        first_dwell = [first_dwell; table( ...
            repmat(string(names{i}),numel(b.nominal_dwell),1), ...
            (1:numel(b.nominal_dwell))', b.nominal_dwell*1e6, ...
            r.dwell(:,1)*1e6, 'VariableNames', ...
            {'method','interval','nominal_us','applied_us'})]; %#ok<AGROW>
        metrics = [metrics; score(b, r, names{i}, scale)]; %#ok<AGROW>
    end
    writetable(history, fullfile(case_dir,'cycle_history.csv'));
    writetable(dwell_history, fullfile(case_dir,'dwell_history.csv'));
    writetable(first_dwell, fullfile(case_dir,'first_cycle_dwell.csv'));
    plot_response(b, responses, names, scale, case_dir);
    dense = plot_states(b, responses, names, scale, case_dir);
    writetable(dense, fullfile(case_dir,'trajectory_samples.csv'));
    study = struct('benchmark',b,'model',model,'controller',c, ...
        'problems',{problems},'names',{names},'responses',{responses}, ...
        'error_scale',scale,'initial_state',initial_state, ...
        'matlab_version',version,'computer',computer);
    save(fullfile(case_dir,'study.mat'),'study');
    studies{scale} = study;
end
writetable(metrics, fullfile(output,'metrics.csv'));
write_report(metrics, output);
disp(metrics);
fprintf('MPC comparison outputs: %s\n',output);
end

function r = simulate(b, model, c, problem, initial_state)
N = b.cycle_count; m = numel(b.nominal_dwell)-1;
r = struct('states',NaN(3,N+1),'error',NaN(N+1,1), ...
    'offsets',NaN(m+1,N),'dwell',NaN(m+1,N),'beta',NaN(N,1), ...
    'exitflag',NaN(N,1),'compute_seconds',NaN(N,1), ...
    'prediction_residual',NaN(N,1),'completed_cycles',0, ...
    'failed_cycle',NaN,'failure_exitflag',NaN);
r.states(:,1) = initial_state;
A = b.state_scale \ model.Phi * b.state_scale;
B = b.state_scale \ model.Gamma * b.timing_scale;
for k = 1:N
    z = b.state_scale \ (r.states(:,k)-b.orbit_anchor);
    started = tic;
    if isempty(problem)
        raw = -c.K_aggressive_physical*(r.states(:,k)-b.orbit_anchor);
        [offsets,r.beta(k),dwell] = condition_dwell_times( ...
            b.config.Ts(:),raw,b.applied_schedule_dwell_bound);
    else
        [v,~,r.exitflag(k)] = Mpc.solve(problem,z);
        r.compute_seconds(k) = toc(started);
        if r.exitflag(k) ~= 1
            % Never apply the failed solver's candidate or the runtime LQR fallback.
            r.failed_cycle = k; r.failure_exitflag = r.exitflag(k);
            fprintf('%s: stopped at cycle %d, QP exitflag %d.\n', ...
                sprintf('MPC-%d',problem.prediction_horizon),k,r.exitflag(k));
            break;
        end
        offsets = b.timing_scale*v;
        dwell = diff(b.config.Ts(:)+[0;offsets;0]);
    end
    if isempty(problem), r.compute_seconds(k) = toc(started); end
    assert(all(dwell >= b.applied_schedule_dwell_bound-1e-12), ...
        'Applied command violates the common dwell bound at cycle %d.',k);
    assert(abs(sum(dwell)-b.period) < 1e-12);
    r.offsets(:,k) = [0;offsets];
    r.dwell(:,k) = dwell;
    r.states(:,k+1) = paper.exact_cycle(b.config,r.states(:,k),offsets);
    assert(all(isfinite(r.states(:,k+1))));
    linear_next = A*z + B*(offsets/b.timing_scale);
    r.prediction_residual(k) = norm( ...
        b.state_scale \ (r.states(:,k+1)-b.orbit_anchor) - linear_next);
    r.completed_cycles = k;
end
r.error = vecnorm(b.state_scale \ (r.states-b.orbit_anchor),2,1)';
end

function row = score(b,r,name,scale)
complete = r.completed_cycles == b.cycle_count;
settled = NaN; final = NaN; cost = NaN;
if complete
    final = r.error(end);
    last_bad = find(r.error >= 0.01,1,'last');
    if isempty(last_bad), settled = 0;
    elseif last_bad < numel(r.error), settled = last_bad; end
    v = r.offsets(2:end,:)/b.timing_scale;
    cost = sum(r.error(1:end-1).^2) + b.aggressive_input_weight*sum(v(:).^2);
end
minimum = NaN; active = NaN; timing_median = NaN; timing_p95 = NaN;
if r.completed_cycles > 0
    dwells = r.dwell(:,1:r.completed_cycles);
    minimum = min(dwells(:))*1e6;
    active = sum(any(dwells <= b.applied_schedule_dwell_bound+1e-12,1));
    elapsed = r.compute_seconds(1:r.completed_cycles)*1e3;
    timing_median = median(elapsed); timing_p95 = prctile(elapsed,95);
end
row = table(string(name),scale,r.completed_cycles,r.failed_cycle, ...
    r.failure_exitflag,final,settled,settled*b.period*1e3,cost,minimum,active, ...
    timing_median,timing_p95,'VariableNames', ...
    {'method','error_scale','completed_cycles','failed_cycle','failure_exitflag', ...
    'final_error','sustained_cycle_below_001','time_to_001_ms', ...
    'sampled_stage_cost','minimum_dwell_us','dwell_active_cycles', ...
    'host_compute_median_ms','host_compute_p95_ms'});
end

function plot_response(b,responses,names,scale,output)
f = figure('Visible','off','Position',[80,80,1000,850]);
tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
colors = [0.10 0.37 0.71; 0.87 0.35 0.12];
nexttile; hold on;
for i = 1:numel(names)
    r = responses{i};
    style = '-'; if i == 2, style = '--'; end
    marker = 'none'; if r.completed_cycles == 0, marker = 'x'; end
    semilogy(0:b.cycle_count,r.error,style,'Color',colors(i,:), ...
        'LineWidth',1.5,'Marker',marker);
end
set(gca,'YScale','log'); yline(0.01,':k','0.01','HandleVisibility','off');
grid on; ylabel('Normalized cycle-start error'); xlabel('Completed cycles');
legend(names,'Location','best','Interpreter','none');
nexttile; hold on;
for i = 1:numel(names)
    style = '-o'; if i == 2, style = '--s'; end
    plot(1:12,min(responses{i}.dwell(:,1:12),[],1)*1e6, ...
        style,'Color',colors(i,:),'LineWidth',1.4,'MarkerSize',3);
end
yline(b.applied_schedule_dwell_bound*1e6,':k','Minimum dwell', ...
    'HandleVisibility','off');
grid on; ylabel('Minimum applied dwell (us)'); xlabel('Cycle');
nexttile; hold on;
for i = 1:numel(names)
    style = '-o'; if i == 2, style = '--s'; end
    plot((1:numel(b.nominal_dwell))',responses{i}.dwell(:,1)*1e6, ...
        style,'Color',colors(i,:),'LineWidth',1.4);
end
yline(b.applied_schedule_dwell_bound*1e6,':k','Minimum dwell', ...
    'HandleVisibility','off');
grid on; ylabel('First-cycle dwell (us)'); xlabel('Mode interval');
title_text = sprintf('Daniel and constrained MPC, initial error %dx',scale);
if ~isnan(responses{2}.failed_cycle)
    title_text = sprintf('%s. %s stopped before cycle %d.', ...
        title_text,names{2},responses{2}.failed_cycle);
end
sgtitle(title_text);
exportgraphics(f,fullfile(output,'comparison.pdf'),'ContentType','vector');
exportgraphics(f,fullfile(output,'comparison.png'),'Resolution',180); close(f);
end

function dense = plot_states(b,responses,names,scale,output)
[ref_time,ref_state] = paper.sample_cycle(b.config,b.orbit_anchor, ...
    zeros(numel(b.nominal_dwell)-1,1),30);
times = []; states = [];
for k = 1:12
    first = 2; if k == 1, first = 1; end
    times = [times; (k-1)*b.period+ref_time(first:end)]; %#ok<AGROW>
    states = [states; ref_state(first:end,:)]; %#ok<AGROW>
end
dense = table(repmat("reference",numel(times),1),times*1e3, ...
    states(:,1),states(:,2),states(:,3),'VariableNames', ...
    {'method','time_ms','vc1_v','vc2_v','il_a'});
for i = 1:numel(names)
    r = responses{i}; times = 0; states = r.states(:,1)';
    for k = 1:min(12,r.completed_cycles)
        [t,x] = paper.sample_cycle(b.config,r.states(:,k),r.offsets(2:end,k),30);
        assert(norm(x(end,:)'-r.states(:,k+1),inf) < 1e-9);
        times = [times; (k-1)*b.period+t(2:end)]; %#ok<AGROW>
        states = [states; x(2:end,:)]; %#ok<AGROW>
    end
    dense = [dense; table(repmat(string(names{i}),numel(times),1),times*1e3, ...
        states(:,1),states(:,2),states(:,3),'VariableNames',dense.Properties.VariableNames)]; %#ok<AGROW>
end
f = figure('Visible','off','Position',[80,80,1100,850]);
tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
all_names = [{'reference'},names];
colors = [0.3 0.3 0.3; 0.10 0.37 0.71; 0.87 0.35 0.12];
labels = {'v_{C1} (V)','v_{C2} (V)','i_L (A)'};
for panel = 1:4
    nexttile; hold on;
    for i = 1:numel(all_names)
        rows = dense.method == all_names{i};
        values = [dense.vc1_v(rows),dense.vc2_v(rows),dense.il_a(rows)];
        style = '-'; if i == 1 || i == 3, style = '--'; end
        marker = 'none'; if size(values,1) == 1, marker = 'x'; end
        if panel == 1
            plot3(values(:,1),values(:,2),values(:,3),style, ...
                'Color',colors(i,:),'LineWidth',1.3,'Marker',marker);
        else
            plot(dense.time_ms(rows),values(:,panel-1),style, ...
                'Color',colors(i,:),'LineWidth',1.3,'Marker',marker);
        end
    end
    grid on;
    if panel == 1
        view(40,25); xlabel(labels{1}); ylabel(labels{2}); zlabel(labels{3});
        legend(all_names,'Location','best','Interpreter','none');
    else
        xlabel('Time (ms)'); ylabel(labels{panel-1}); xlim([0,12*b.period*1e3]);
    end
end
sgtitle(sprintf('Exact switched-affine state trajectories, initial error %dx',scale));
exportgraphics(f,fullfile(output,'state_trajectories.pdf'),'ContentType','vector');
exportgraphics(f,fullfile(output,'state_trajectories.png'),'Resolution',180); close(f);
end

function write_report(metrics,output)
fid = fopen(fullfile(output,'metrics.tex'),'w');
assert(fid ~= -1); cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'\\begin{tabular}{llrrrr}\n\\toprule\n');
fprintf(fid,'Scale & Method & Completed & Settling cycle & Stage cost & Min. dwell ($\\mu$s) \\\\ \\midrule\n');
for i = 1:height(metrics)
    r = metrics(i,:);
    fprintf(fid,'%dx & %s & %d & %s & %s & %s \\\\ \n', ...
        r.error_scale,r.method,r.completed_cycles,number(r.sustained_cycle_below_001), ...
        number(r.sampled_stage_cost),number(r.minimum_dwell_us));
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n');
end

function value = number(x)
if isnan(x), value = '--'; else, value = sprintf('%.5g',x); end
end
