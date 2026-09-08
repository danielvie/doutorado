function export_timing_diagrams(paths, benchmark, response)
%EXPORT_TIMING_DIAGRAMS Paper-style vector schematics with live numerical labels.
% Tutorial HTML is a visual reference only; labels use the current article data.
data = paper.timing_diagram_data(benchmark, response);
for directory = {paths.article_figures, paths.diagnostic_figures}
    if ~isfolder(directory{1}), mkdir(directory{1}); end
end
palette = struct('blue', [0, 0.35, 0.70], 'red', [0.75, 0.20, 0.15], ...
    'gray', [0.45, 0.45, 0.45], 'neutral', [0.94, 0.94, 0.94], ...
    'blue_fill', [0.89, 0.94, 0.98], 'red_fill', [0.98, 0.91, 0.90]);
figure_coordinates(paths, data, palette);
figure_coupling(paths, data, palette);
figure_failure(paths, data, palette);
end

function figure_coordinates(paths, data, c)
[fig, ax] = canvas(210);
cleanup = onCleanup(@() close(fig));
label(ax, 25, 15, '(a) Fixed period, movable interior switching instants', 'left', 'k', 15);
label(ax, 960, 15, 'Interval / dwell ($\mu$s)', 'right', c.gray, 12);
sx = @(t) 70 + 880 * (t - data.nominal(1)) / data.period_us;
for i = 1:9
    a = sx(data.nominal(i)); b = sx(data.nominal(i+1));
    box(ax, a, b, 60, 44, c.neutral, c.gray);
    label(ax, (a+b)/2, 74, sprintf('%d', i), 'center', 'k', 14);
    label(ax, (a+b)/2, 92, sprintf('%.1f', data.dwell(i)), 'center', c.gray, 12);
end
for j = 0:9
    x = sx(data.nominal(j+1));
    if j == 0 || j == 9
        plot(ax, [x, x], [46, 111], '-k', 'LineWidth', 2);
        plot(ax, x, 43, 'sk', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
    else
        plot(ax, [x, x], [50, 111], '-', 'Color', c.blue, 'LineWidth', 1.2);
        arrow(ax, x-11, x+11, 41, c.blue, true);
    end
    label(ax, x, 126, sprintf('$\\bar t_%d$', j), 'center', 'k', 12);
    label(ax, x, 145, sprintf('%.1f', data.nominal(j+1)), 'center', c.gray, 11);
end
plot(ax, [sx(0), sx(0), sx(data.period_us), sx(data.period_us)], ...
    [164, 171, 171, 164], '-', 'Color', c.gray, 'LineWidth', 0.8);
label(ax, 510, 188, sprintf('$T=%.0f\\,\\mu$s, fixed', data.period_us), 'center', 'k', 13);
label(ax, 70, 188, 'Boundary times in $\mu$s', 'left', c.gray, 11);
export_panel(paths, fig, 'timing_coordinates');
end

function figure_coupling(paths, data, c)
[fig, ax] = canvas(225);
cleanup = onCleanup(@() close(fig));
label(ax, 25, 15, '(b) One shifted instant changes two adjacent dwells', 'left', 'k', 15);
lo = data.nominal(7); hi = data.nominal(10);
sx = @(t) 135 + 815 * (t - lo) / (hi - lo);
for row = 1:2
    if row == 1
        times = data.nominal; dwell = data.dwell; y = 49; name = 'Nominal';
    else
        times = data.coupling; dwell = data.coupling_dwell; y = 135; name = 'Shifted';
    end
    label(ax, 110, y+16, name, 'right', c.gray, 13);
    for i = 7:9
        fill = c.neutral; edge = c.gray;
        if row == 2 && i == 8, fill = c.blue_fill; edge = c.blue; end
        if row == 2 && i == 9, fill = c.red_fill; edge = c.red; end
        a = sx(times(i)); b = sx(times(i+1));
        box(ax, a, b, y, 32, fill, edge);
        if row == 1, format = '$\\bar d_%d=%.3f$'; else, format = '$d_%d=%.3f$'; end
        label(ax, (a+b)/2, y+16, sprintf(format, i, dwell(i)), 'center', edge, 13);
    end
    for j = 6:9
        x = sx(times(j+1));
        color = c.gray; width = 1;
        if j == 9, color = 'k'; width = 2; end
        if row == 2 && j == 8, color = c.blue; width = 2; end
        plot(ax, [x, x], [y-6, y+38], '-', 'Color', color, 'LineWidth', width);
    end
end
old = sx(data.nominal(9)); moved = sx(data.coupling(9));
plot(ax, [old, old], [83, 171], ':', 'Color', c.blue, 'LineWidth', 1);
arrow(ax, old, moved, 111, c.blue, false);
label(ax, (old+moved)/2, 97, sprintf('$+%.0f\\,\\mu$s', data.shift_us), 'center', c.blue, 13);
label(ax, sx(hi), 35, '$T$, fixed', 'center', 'k', 12);
label(ax, sx((data.coupling(7)+data.coupling(8))/2), 189, 'Unchanged', 'center', c.gray, 12);
label(ax, sx((data.coupling(8)+data.coupling(9))/2), 189, ...
    sprintf('$\\Delta d_8=+%.0f\\,\\mu$s', data.shift_us), 'center', c.blue, 13);
label(ax, sx((data.coupling(9)+data.coupling(10))/2), 189, ...
    sprintf('$\\Delta d_9=-%.0f\\,\\mu$s', data.shift_us), 'center', c.red, 13);
label(ax, 510, 214, 'Illustrative single-offset action; all other offsets are zero. Dwells in $\mu$s.', ...
    'center', c.gray, 12);
export_panel(paths, fig, 'dwell_coupling');
end

function figure_failure(paths, data, c)
[fig, ax] = canvas(250);
cleanup = onCleanup(@() close(fig));
label(ax, 25, 15, '(c) A raw timing request can reverse the boundary order', 'left', 'k', 15);
lo = min(data.raw(8), data.nominal(7)) - 8;
hi = data.raw(9) + 12;
sx = @(t) 115 + 815 * (t - lo) / (hi - lo);
period = sx(data.nominal(end)); raw_end = sx(data.raw(9));
label(ax, period, 39, sprintf('$T=%.0f\\,\\mu$s, fixed', data.period_us), 'center', 'k', 13);
label(ax, 100, 76, 'Nominal', 'right', c.gray, 13);
for i = 7:9
    a = sx(data.nominal(i)); b = sx(data.nominal(i+1));
    box(ax, a, b, 60, 32, c.neutral, c.gray);
    label(ax, (a+b)/2, 76, sprintf('$\\bar d_%d=%.1f$', i, data.dwell(i)), 'center', c.gray, 12);
end
old = sx(data.nominal(9));
plot(ax, [old, old], [94, 160], ':', 'Color', c.gray, 'LineWidth', 1);
label(ax, old-5, 108, sprintf('$\\bar t_8=%.3f$', data.nominal(9)), 'right', c.gray, 12);
arrow(ax, old, raw_end, 132, c.red, false);
label(ax, (old+raw_end)/2, 117, ...
    sprintf('$\\delta\\tau_8^{\\rm raw}=+%.3f\\,\\mu$s', data.raw_offsets(8)), 'center', c.red, 13);
label(ax, 100, 179, 'Raw', 'right', c.red, 13);
box(ax, sx(data.raw(8)), raw_end, 163, 32, c.neutral, c.gray);
label(ax, (sx(data.raw(8))+period)/2, 179, ...
    sprintf('$d_8^{\\rm raw}=%.3f\\,\\mu$s', data.raw_dwell(8)), 'center', c.gray, 13);
box(ax, period, raw_end, 163, 32, c.red_fill, c.red);
for start = period-20:10:raw_end
    x1 = max(start, period); x2 = min(start+20, raw_end);
    if x2 > x1
        plot(ax, [x1, x2], 195 - (32/20)*([x1, x2]-start), '-', ...
            'Color', c.red, 'LineWidth', 0.5);
    end
end
plot(ax, [period, period], [48, 100], '-k', 'LineWidth', 2);
plot(ax, [period, period], [153, 216], '-k', 'LineWidth', 2);
plot(ax, [raw_end, raw_end], [155, 202], '-', 'Color', c.red, 'LineWidth', 1.5);
label(ax, raw_end, 150, sprintf('$t_8^{\\rm raw}=%.3f$', data.raw(9)), 'center', c.red, 12);
arrow(ax, raw_end, period, 214, c.red, false);
label(ax, (period+raw_end)/2, 235, ...
    sprintf('$d_9^{\\rm raw}=%.3f\\,\\mu$s $<0$', data.raw_dwell(9)), 'center', c.red, 13);
label(ax, 115, 235, 'Candidate only: not an executable schedule', 'left', c.gray, 12);
export_panel(paths, fig, 'inadmissible_request');
end

function [fig, ax] = canvas(height)
fig = paper.publication_figure(16 * height / 1000);
ax = axes(fig, 'Position', [0, 0, 1, 1], 'XLim', [0, 1000], ...
    'YLim', [0, height], 'YDir', 'reverse', 'Visible', 'off');
hold(ax, 'on');
% Keep all three panel viewports the same width when exporting tight vector PDFs.
patch(ax, [0, 1000, 1000, 0], [0, 0, height, height], 'w', 'EdgeColor', 'none');
end

function label(ax, x, y, value, alignment, color, size)
assert(all(double(value) >= 32), 'A diagram label contains an unintended control character.');
% Source sizes denote hierarchy; these are final printed point sizes.
printed_size = interp1([11,12,13,14,15], [8.5,9,9.5,9.5,10], size);
text(ax, x, y, value, 'HorizontalAlignment', alignment, 'VerticalAlignment', 'middle', ...
    'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', printed_size, 'Color', color);
end

function box(ax, left, right, top, height, fill, edge)
assert(right > left, 'A drawn duration bar must have positive geometric width.');
rectangle(ax, 'Position', [left, top, right-left, height], ...
    'FaceColor', fill, 'EdgeColor', edge, 'LineWidth', 0.8);
end

function arrow(ax, from, to, y, color, double)
plot(ax, [from, to], [y, y], '-', 'Color', color, 'LineWidth', 1.1);
direction = sign(to-from);
patch(ax, [to, to-direction*6, to-direction*6], [y, y-3, y+3], color, 'EdgeColor', color);
if double
    patch(ax, [from, from+direction*6, from+direction*6], [y, y-3, y+3], color, 'EdgeColor', color);
end
end

function export_panel(paths, fig, name)
paper.export_publication_figure(fig, fullfile(paths.article_figures, [name, '.pdf']));
exportgraphics(fig, fullfile(paths.diagnostic_figures, [name, '.png']), 'Resolution', 180);
end
