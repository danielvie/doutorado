function plot_trajectories(output, data, benchmark)
%PLOT_TRAJECTORIES Render saved physical trajectories without resimulating.
if ~isfolder(output), mkdir(output); end
figure_comparison(output, data, benchmark);
figure_states(output, data, benchmark);
end

function figure_comparison(output, data, benchmark)
fig = paper.publication_figure(10);
cleanup = onCleanup(@() close(fig));
blue = [0.00, 0.35, 0.70]; red = [0.75, 0.20, 0.15];
ax = axes(fig, 'Position', [0.09, 0.25, 0.36, 0.65]);
x = data.state_off;
open = plot3(ax, x(:,1), x(:,2), x(:,3), '--', 'Color', red, 'LineWidth', 0.6);
hold(ax, 'on');
x = data.state_on;
controlled = plot3(ax, x(:,1), x(:,2), x(:,3), '-', 'Color', blue);
r = data.reference_state;
target = plot3(ax, r(:,1), r(:,2), r(:,3), '-k', 'LineWidth', 1.5);
x = data.state_on(1,:);
start = plot3(ax, x(1), x(2), x(3), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
a = benchmark.orbit_anchor;
anchor = plot3(ax, a(1), a(2), a(3), 'kp', 'MarkerFaceColor', [1,0.8,0], 'MarkerSize', 7);
xlabel(ax, '$v_{C_1}$ (V)', 'Interpreter', 'latex');
ylabel(ax, '$v_{C_2}$ (V)', 'Interpreter', 'latex');
zlabel(ax, '$i_L$ (A)', 'Interpreter', 'latex');
set(ax, 'SortMethod', 'childorder', 'GridAlpha', 0.12);
grid(ax, 'on'); view(ax, 42, 24);
title(ax, sprintf('(a) First %d cycles', benchmark.cycle_count));
leg = legend(ax, [controlled,open,target,start,anchor], ...
    {'Closed loop','Open loop','Reference','Initial state','Cycle anchor'}, ...
    'NumColumns', 3, 'Box', 'off');
set(leg, 'Units', 'normalized', 'Position', [0.08,0.015,0.84,0.10]);

% Recover actual cycle starts. Do not extrapolate feedback beyond the saved run
% or clamp small errors to the lower plotting boundary.
n = size(data.reference_state,1)-1;
assert(size(data.state_on,1) == benchmark.cycle_count*n+1, 'Unexpected dense sample count.');
cycle_states = data.state_on(1:n:end,:)';
feedback_error = vecnorm(benchmark.state_scale \ (cycle_states-benchmark.orbit_anchor),2,1)';
open_error = data.long_open_loop_error(:);
last = numel(open_error)-1;
assert(last == benchmark.long_simulation_cycles, 'Long-run horizon mismatch.');
threshold = 0.01;
feedback_cross = find(feedback_error < threshold,1)-1;
last_outside = find(open_error >= threshold,1,'last');
if isempty(last_outside), open_cross = 0; else, open_cross = last_outside; end
assert(~isempty(feedback_cross) && feedback_cross >= 1, 'Expected a feedback threshold crossing.');
assert(open_cross == data.convergence_cycle && open_cross >= 1 && open_cross <= last, ...
    'Persistent open-loop crossing differs from saved evidence.');
ax = axes(fig, 'Position', [0.62,0.25,0.35,0.65], 'XScale', 'log', 'YScale', 'log');
hold(ax, 'on');
ybounds = [1e-8,3];
patch(ax, [1,benchmark.cycle_count,benchmark.cycle_count,1], ...
    [ybounds(1),ybounds(1),ybounds(2),ybounds(2)], [0.92,0.94,0.97], 'EdgeColor', 'none');
plot(ax, (1:last)',open_error(2:end),'--','Color',red);
plot(ax, (1:benchmark.cycle_count)',feedback_error(2:end),'-','Color',blue);
yline(ax, threshold, ':k');
plot(ax,feedback_cross,feedback_error(feedback_cross+1),'o','Color',blue, ...
    'MarkerFaceColor',blue,'MarkerSize',4);
plot(ax,open_cross,open_error(open_cross+1),'o','Color',red, ...
    'MarkerFaceColor',red,'MarkerSize',4);
text(ax,2,1.4,'Panel (a)','FontSize',9);
text(ax,150,threshold*1.8,'$E_k=0.01$','FontSize',9,'Interpreter','latex');
text(ax,15,7e-4,sprintf('Closed loop\nk = %d',feedback_cross), ...
    'Color',blue,'VerticalAlignment','top');
plot(ax,[open_cross,open_cross],[1.5e-3,open_error(open_cross+1)],':','Color',red);
text(ax,open_cross/1.3,1.2e-3,sprintf('Open loop\nk = %d',open_cross), ...
    'Color',red,'HorizontalAlignment','right','VerticalAlignment','top');
xlim(ax,[1,last]); ylim(ax,ybounds);
xticks(ax,10.^(0:floor(log10(last)))); yticks(ax,10.^(-8:2:0));
xlabel(ax,'Cycle k (log scale)');
ylabel(ax,'Cycle-start error $E_k$','Interpreter','latex');
set(ax,'Layer','top','XMinorGrid','off','YMinorGrid','off','GridAlpha',0.12);
grid(ax,'on'); title(ax,'(b) Long-horizon error');
paper.export_publication_figure(fig,fullfile(output,'trajectory_comparison.pdf'));
end

function figure_states(output, data, benchmark)
v = paper.state_history_data(data, benchmark);
fig = paper.publication_figure(11.5);
cleanup = onCleanup(@() close(fig));
labels = {'$v_{C_1}(t)$ (V)','$v_{C_2}(t)$ (V)','$i_L(t)$ (A)'};
blue = [0,0.35,0.70]; red = [0.75,0.20,0.15];
for i = 1:3
    ax(i) = axes(fig,'Position',[0.12,0.71-(i-1)*0.29,0.85,0.22]);
    hold(ax(i),'on');
    open = plot(ax(i),v.time_off*1e3,v.state_off(:,i),'--','Color',red);
    closed = plot(ax(i),v.time_on*1e3,v.state_on(:,i),'-','Color',blue);
    reference = plot(ax(i),v.reference_time*1e3,v.reference_state(:,i),':k','LineWidth',0.9);
    ylabel(ax(i),labels{i},'Interpreter','latex');
    xlim(ax(i),[0,v.cycles*benchmark.period*1e3]);
    text(ax(i),0,1.06,sprintf('(%c)','a'+i-1),'Units','normalized', ...
        'VerticalAlignment','bottom');
    range = ylim(ax(i));
    ylim(ax(i),range+[-1,1]*0.06*diff(range));
    set(ax(i),'GridAlpha',0.12); grid(ax(i),'on');
    if i < 3, set(ax(i),'XTickLabel',[]); end
    if i == 1
        leg = legend(ax(i),[closed,open,reference],{'Closed loop','Open loop','Reference'}, ...
            'NumColumns',3,'Box','off');
        set(leg,'Units','normalized','Position',[0.15,0.95,0.80,0.04]);
    end
end
linkaxes(ax,'x'); xlabel(ax(3),'Time t (ms)');
paper.export_publication_figure(fig,fullfile(output,'state_time_comparison.pdf'));
end
