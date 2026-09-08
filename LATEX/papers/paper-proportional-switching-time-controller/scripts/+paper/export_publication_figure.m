function export_publication_figure(fig, filename)
%EXPORT_PUBLICATION_FIGURE Exact-size vector PDF; no tight-crop font rescaling.
% MATLAB can auto-reduce axes and legend fonts on small physical canvases.
% Freeze actual object sizes after plotting, not just figure defaults.
for ax = findall(fig, 'Type', 'axes')'
    set(ax, 'FontSize', 9);
    set([ax.XLabel, ax.YLabel, ax.ZLabel, ax.Title], 'FontSize', 10);
end
set(findall(fig, 'Type', 'legend'), 'FontSize', 9);
set(fig, 'Units', 'centimeters');
position = fig.Position;
set(fig, 'PaperUnits', 'centimeters', 'PaperSize', position(3:4), ...
    'PaperPosition', [0, 0, position(3:4)], 'PaperPositionMode', 'manual', ...
    'InvertHardcopy', 'off');
directory = fileparts(filename);
if ~isfolder(directory), mkdir(directory); end
print(fig, filename, '-dpdf', '-painters');
end
