function export_timing()
%EXPORT_TIMING Build the report table from saved measurements, without simulation.
output = fullfile(fileparts(mfilename('fullpath')), 'results');
metrics = readtable(fullfile(output, 'metrics.csv'), 'TextType', 'string');
fid = fopen(fullfile(output, 'computation-time.tex'), 'w');
assert(fid ~= -1); cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '\\begin{tabular}{llrrr}\n\\toprule\n');
fprintf(fid, 'Scale & Method & Calls & Median ($\\mu$s) & 95th percentile ($\\mu$s) \\\\ \\midrule\n');
failed = [];
for i = 1:height(metrics)
    r = metrics(i,:);
    history = readtable(fullfile(output, ...
        sprintf('error-scale-%dx',r.error_scale),'cycle_history.csv'), ...
        'TextType','string');
    rows = history.method == r.method & isfinite(history.compute_ms);
    times = history.compute_ms(rows)*1000;
    assert(numel(times) == r.completed_cycles + ~isnan(r.failed_cycle));
    if ~isnan(r.failed_cycle)
        failed = [failed; r.error_scale,times(end)]; %#ok<AGROW>
        times(end) = [];
    end
    if isempty(times)
        median_text = '--'; p95_text = '--';
    else
        % Check both the saved summaries and the milliseconds-to-microseconds conversion.
        assert(abs(median(times)-r.host_compute_median_ms*1000) < 1e-8);
        assert(abs(prctile(times,95)-r.host_compute_p95_ms*1000) < 1e-8);
        median_text = sprintf('%.2f',median(times));
        p95_text = sprintf('%.2f',prctile(times,95));
    end
    fprintf(fid, '%dx & %s & %d & %s & %s \\\\ \n', ...
        r.error_scale,r.method,r.completed_cycles,median_text,p95_text);
end
fprintf(fid, '\\bottomrule\n\\end{tabular}\n');
for i = 1:size(failed,1)
    fprintf(fid, '\n\\par\\medskip At %dx, the single infeasible MPC solve took %.2f $\\mu$s; it is excluded from the successful-call summaries.\n', ...
        failed(i,1),failed(i,2));
end
end
