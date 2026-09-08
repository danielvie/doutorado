function plot_conditioned_response(output, response, benchmark)
%PLOT_CONDITIONED_RESPONSE Align error, applied fraction, and dwell feasibility.
% Use saved cycle-start errors and candidate/applied actions, not new simulations.
fig = paper.publication_figure(12);
cleanup = onCleanup(@() close(fig));
blue = [0, 0.35, 0.70]; red = [0.75, 0.20, 0.15];
cycles = 0:numel(response.conditioned_error)-1;
action_cycles = 0:numel(response.conditioning_beta)-1;
last = min(25, action_cycles(end));
beta = response.conditioning_beta(:)';
active = action_cycles(beta < 1 & action_cycles < last);

ax(1) = axes(fig, 'Position', [0.12, 0.65, 0.85, 0.28], 'YScale', 'log');
hold(ax(1), 'on');
shade_active(ax(1), active, [1e-8, 2]);
closed = semilogy(ax(1), cycles, response.conditioned_error, '-', 'Color', blue);
open = semilogy(ax(1), cycles, response.open_loop_error, '--', 'Color', red);
yline(ax(1), 0.01, ':k', '$E_k=0.01$', 'FontSize', 9, ...
    'LabelHorizontalAlignment', 'right', 'Interpreter', 'latex');
crossing = find(response.conditioned_error < 0.01, 1) - 1;
if ~isempty(crossing) && crossing <= last
    plot(ax(1), crossing, response.conditioned_error(crossing+1), 'o', ...
        'MarkerSize', 4, 'MarkerFaceColor', blue, 'Color', blue);
    text(ax(1), crossing+0.7, 0.3*response.conditioned_error(crossing+1), ...
        sprintf('Cycle %d', crossing), 'Color', blue, 'VerticalAlignment', 'top');
end
ylim(ax(1), [1e-8, 2]); yticks(ax(1), 10.^(-8:2:0));
ylabel(ax(1), '$E_k$', 'Interpreter', 'latex');
title(ax(1), '(a) Cycle-start error');
legend(ax(1), [closed, open], {'Closed loop', 'Open loop'}, ...
    'Location', 'southwest', 'NumColumns', 2, 'Box', 'off');

ax(2) = axes(fig, 'Position', [0.12, 0.43, 0.85, 0.10]);
hold(ax(2), 'on');
shade_active(ax(2), active, [0, 1.15]);
stairs(ax(2), action_cycles, beta, 'Color', blue);
ylim(ax(2), [0, 1.15]); yticks(ax(2), [0, 1]);
ylabel(ax(2), '$\beta_k$', 'Interpreter', 'latex');
title(ax(2), '(b) Fraction of the requested adjustment applied');
text(ax(2), 0.98, 0.35, 'Shading: scaling active', 'Units', 'normalized', ...
    'HorizontalAlignment', 'right');

ax(3) = axes(fig, 'Position', [0.12, 0.10, 0.85, 0.21]);
hold(ax(3), 'on');
bound = benchmark.applied_schedule_dwell_bound * 1e6;
raw = min(response.raw_dwell, [], 1) * 1e6;
applied = min(response.applied_dwell, [], 1) * 1e6;
shown = action_cycles <= last;
low = 10 * floor(min([raw(shown), 0]) / 10);
high = 10 * ceil(max([applied(shown), bound]) / 10);
patch(ax(3), [0,last,last,0], [low,low,bound,bound], [0.98,0.92,0.91], ...
    'EdgeColor', 'none', 'HandleVisibility', 'off');
requested = plot(ax(3), action_cycles, raw, '--', 'Color', red);
executed = plot(ax(3), action_cycles, applied, '-', 'Color', blue);
yline(ax(3), bound, ':k', sprintf('$%g\\,\\mu$s minimum', bound), ...
    'FontSize', 9, 'Interpreter', 'latex', 'LabelHorizontalAlignment', 'right');
text(ax(3), last*0.98, low+0.14*(high-low), 'Forbidden dwell', ...
    'HorizontalAlignment', 'right', 'Color', red);
ylim(ax(3), [low, high]);
ylabel(ax(3), 'Minimum dwell (\mus)');
title(ax(3), '(c) Requested and applied schedule');
legend(ax(3), [requested, executed], {'Requested', 'Applied'}, ...
    'Location', 'southwest', 'NumColumns', 2, 'Box', 'off');
xlabel(ax(3), 'Cycle k');
for a = ax
    xlim(a, [0, last]); xticks(a, 0:5:last);
    grid(a, 'on');
    set(a, 'Layer', 'top', 'XMinorGrid', 'off', 'YMinorGrid', 'off', 'GridAlpha', 0.12);
end
linkaxes(ax, 'x');
paper.export_publication_figure(fig, fullfile(output, 'conditioned_control_response.pdf'));
end

function shade_active(ax, cycles, limits)
for k = cycles(:)'
    patch(ax, [k,k+1,k+1,k], [limits(1),limits(1),limits(2),limits(2)], ...
        [0.98,0.93,0.80], 'EdgeColor', 'none', 'HandleVisibility', 'off');
end
end
