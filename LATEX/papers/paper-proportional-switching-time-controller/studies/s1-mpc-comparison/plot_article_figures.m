function plot_article_figures()
%PLOT_ARTICLE_FIGURES Replot Daniel/MPC-5 evidence without simulation or solvers.
root = fileparts(mfilename('fullpath'));
results = fullfile(root, 'results');
output = fullfile(results, 'article-figures');
if ~isfolder(output), mkdir(output); end
metrics = readtable(fullfile(results,'metrics.csv'),'TextType','string');
methods = ["daniel", "mpc-5"];
names = {'LQR-Daniel', 'MPC-5'};
colors = [0.10 0.37 0.71; 0.87 0.35 0.12];
styles = {'-', '--'};
scales = unique(metrics.error_scale)';
responses = cell(numel(scales),numel(methods)); cumulative = responses; studies = cell(numel(scales),1);
for s = 1:numel(scales)
    folder = fullfile(results,sprintf('error-scale-%dx',scales(s)));
    data = load(fullfile(folder,'study.mat'),'study');
    studies{s} = data.study; b = data.study.benchmark;
    history = readtable(fullfile(folder,'cycle_history.csv'),'TextType','string');
    for j = 1:numel(methods)
        row = metrics(metrics.error_scale == scales(s) & metrics.method == methods(j),:);
        assert(height(row) == 1 && row.completed_cycles == b.cycle_count, ...
            'Expected one complete saved trial for each selected controller.');
        h = history(history.method == methods(j),:);
        index = find(string(data.study.names) == methods(j));
        assert(isscalar(index));
        r = data.study.responses{index}; responses{s,j} = r;
        assert(height(h) == b.cycle_count+1 && r.completed_cycles == b.cycle_count);
        assert(max(abs(h.normalized_error-r.error)) < 1e-12);
        times = h.compute_ms(isfinite(h.compute_ms));
        assert(numel(times) == b.cycle_count);
        assert(abs(median(times)-row.host_compute_median_ms) < 1e-10);
        assert(abs(prctile(times,95)-row.host_compute_p95_ms) < 1e-10);
        last_bad = find(r.error >= 0.01,1,'last');
        settled = 0;
        if ~isempty(last_bad), settled = last_bad; end
        if last_bad == numel(r.error), settled = NaN; end
        assert(isequaln(settled,row.sustained_cycle_below_001));
        assert(all(r.dwell(:) >= b.applied_schedule_dwell_bound-1e-12));
        z = b.state_scale \ (r.states(:,1:end-1)-b.orbit_anchor);
        v = r.offsets(2:end,:)/b.timing_scale;
        stages = sum(z.^2,1)+b.aggressive_input_weight*sum(v.^2,1);
        cumulative{s,j} = [0 cumsum(stages)];
        assert(abs(sum(stages)-row.sampled_stage_cost) < 1e-9, ...
            'Cumulative cost must reproduce the saved 100-cycle metric.');
    end
end

% The same elapsed-time window makes early convergence and cost buildup visible.
f = figure('Visible','off','Units','centimeters','Position',[2 2 17 18]);
tiledlayout(f,numel(scales),2,'TileSpacing','compact','Padding','compact');
for s = 1:numel(scales)
    b = studies{s}.benchmark;
    time = (0:b.cycle_count)*b.period*1e3;
    for panel = 1:2
        nexttile; hold on;
        for j = 1:numel(methods)
            r = responses{s,j}; values = r.error;
            if panel == 2, values = cumulative{s,j}; end
            plot(time,values,styles{j},'Color',colors(j,:),'LineWidth',1.4);
            if panel == 1
                row = metrics(metrics.error_scale == scales(s) & metrics.method == methods(j),:);
                k = row.sustained_cycle_below_001;
                plot(time(k+1),r.error(k+1),'o','Color',colors(j,:), ...
                    'MarkerFaceColor','w','MarkerSize',4,'HandleVisibility','off');
            end
        end
        xlim([0 25*b.period*1e3]); xlabel('Elapsed time (ms)'); grid on;
        title(sprintf('%dx initial error',scales(s)),'FontSize',10);
        if panel == 1
            set(gca,'YScale','log'); ylim([1e-10 4]);
            yline(0.01,':k','0.01','HandleVisibility','off','FontSize',8);
            ylabel('Normalized cycle-start error');
            if s == 1, legend(names,'Location','southwest','FontSize',8); end
        else
            ylabel('Accumulated cost J(t)');
        end
    end
end
save_figure(f,output,'error-cost-histories');

s = find(scales == 3); assert(isscalar(s));
b = studies{s}.benchmark;
r = responses{s,1};
raw = -studies{s}.controller.K_aggressive_physical*(r.states(:,1:end-1)-b.orbit_anchor);
raw_dwell = b.nominal_dwell+diff([zeros(1,b.cycle_count);raw;zeros(1,b.cycle_count)],1,1);
assert(max(abs(r.offsets(2:end,:)-raw.*r.beta'),[],'all') < 1e-12);
assert(max(abs(r.dwell-(b.nominal_dwell+diff( ...
    [zeros(1,b.cycle_count);r.offsets(2:end,:);zeros(1,b.cycle_count)],1,1))),[],'all') < 1e-12);
f = figure('Visible','off','Units','centimeters','Position',[2 2 17 18]);
tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
nexttile; hold on;
for j = 1:numel(methods)
    plot((0:b.cycle_count)*b.period*1e3,responses{s,j}.error,styles{j}, ...
        'Color',colors(j,:),'LineWidth',1.4);
end
set(gca,'YScale','log'); ylim([1e-10 4]);
yline(0.01,':k','0.01','HandleVisibility','off','FontSize',8);
ylabel('Normalized error'); legend(names,'Location','southwest','FontSize',8);
title('(a) Cycle-start error','FontSize',10);
nexttile; hold on;
time = (0:b.cycle_count-1)*b.period*1e3;
stairs(time,r.beta,'Color',colors(1,:),'LineWidth',1.4);
ylim([0 1.08]); ylabel('Conditioning factor beta');
text(0.98,0.15,'MPC-5 optimizes offsets; it has no beta factor', ...
    'Units','normalized','HorizontalAlignment','right','FontSize',8);
title('(b) LQR-Daniel conditioning','FontSize',10);
nexttile; hold on;
window = time <= 25*b.period*1e3;
ymin = min(raw_dwell(:,window),[],'all')*1e6;
patch([0 25*b.period*1e3 25*b.period*1e3 0],[ymin ymin 3 3], ...
    [1 0.94 0.94],'EdgeColor','none','HandleVisibility','off');
plot(time,min(raw_dwell,[],1)*1e6,':','Color',colors(1,:),'LineWidth',1.4);
for j = 1:numel(methods)
    plot(time,min(responses{s,j}.dwell,[],1)*1e6,styles{j}, ...
        'Color',colors(j,:),'LineWidth',1.4);
end
yline(3,':k','3 us minimum','HandleVisibility','off','FontSize',8);
ylabel('Minimum dwell (us)');
legend({'LQR-Daniel raw','LQR-Daniel applied','MPC-5 applied'}, ...
    'Location','southeast','FontSize',8);
title('(c) Requested versus applied minimum dwell','FontSize',10);
axes_list = findall(f,'Type','axes');
for ax = axes_list'
    xlim(ax,[0 25*b.period*1e3]); xlabel(ax,'Elapsed time (ms)'); grid(ax,'on');
end
save_figure(f,output,'conditioning-3x');

% Plot every saved sample at its own physical timestamp; do not interpolate.
dense = readtable(fullfile(results,'error-scale-3x','trajectory_samples.csv'), ...
    'TextType','string');
f = figure('Visible','off','Units','centimeters','Position',[2 2 17 15]);
tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
state_names = ["reference", methods];
state_labels = {'Fixed-clock reference',names{:}};
state_colors = [0.25 0.25 0.25; colors];
state_styles = {'-.',styles{:}};
labels = {'v_{C1} (V)','v_{C2} (V)','i_L (A)'};
for panel = 1:4
    nexttile; hold on;
    for j = 1:numel(state_names)
        rows = dense.method == state_names(j);
        t = dense.time_ms(rows);
        values = [dense.vc1_v(rows),dense.vc2_v(rows),dense.il_a(rows)];
        assert(numel(t) > 1 && all(diff(t) >= 0));
        if panel == 1
            plot3(values(:,1),values(:,2),values(:,3),state_styles{j}, ...
                'Color',state_colors(j,:),'LineWidth',1.2);
            plot3(values(1,1),values(1,2),values(1,3),'o', ...
                'Color',state_colors(j,:),'MarkerSize',3,'HandleVisibility','off');
        else
            plot(t,values(:,panel-1),state_styles{j}, ...
                'Color',state_colors(j,:),'LineWidth',1.2);
        end
    end
    grid on;
    if panel == 1
        view(40,25); xlabel(labels{1}); ylabel(labels{2}); zlabel(labels{3});
        title('(a) State-space trajectory','FontSize',10);
    else
        xlabel('Elapsed time (ms)'); ylabel(labels{panel-1});
        xlim([0 12*b.period*1e3]);
        title(sprintf('(%c) %s',char('a'+panel-1),labels{panel-1}),'FontSize',10);
        if panel == 2, legend(state_labels,'Location','southeast','FontSize',7); end
    end
end
save_figure(f,output,'physical-trajectories-3x');

% Keep scalar summaries in a compact generated table rather than sparse charts.
fid = fopen(fullfile(output,'summary.tex'),'w');
assert(fid ~= -1); cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'\\begin{tabular}{llrrrr}\n\\toprule\n');
fprintf(fid,'Scale & Method & $J_{\\mathrm{eval}}$ & $t_{0.01}$ (ms) & Median ($\\mu$s) & p95 ($\\mu$s) \\\\ \\midrule\n');
for scale = scales
    for j = 1:numel(methods)
        row = metrics(metrics.error_scale == scale & metrics.method == methods(j),:);
        fprintf(fid,'%dx & %s & %.5g & %.3f & %.2f & %.2f \\\\ \n', ...
            scale,names{j},row.sampled_stage_cost,row.time_to_001_ms, ...
            1000*row.host_compute_median_ms,1000*row.host_compute_p95_ms);
    end
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n');
fprintf('Saved-evidence checks passed; Daniel/MPC-5 time histories and summary exported without simulation.\n');
end

function save_figure(f,output,name)
set(findall(f,'Type','axes'),'FontSize',9);
exportgraphics(f,fullfile(output,[name '.pdf']),'ContentType','vector');
exportgraphics(f,fullfile(output,[name '.png']),'Resolution',180);
close(f);
end
