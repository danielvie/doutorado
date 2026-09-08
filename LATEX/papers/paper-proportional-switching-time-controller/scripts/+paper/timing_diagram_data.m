function data = timing_diagram_data(benchmark, response)
%TIMING_DIAGRAM_DATA Numerical content of the three explanatory schedule panels.
% The isolated +12 us offset is an illustration, not an LQR simulation sample.
nominal = benchmark.config.Ts(:) * 1e6;
N = numel(nominal) - 1;
assert(N == 9, 'These explanatory panels use the nine-interval converter benchmark.');
raw_offsets = response.raw_offsets(:, 1) * 1e6;
assert(numel(raw_offsets) == N - 1, 'Wrong number of interior offsets.');
raw = nominal + [0; raw_offsets; 0];
assert(max(abs(diff(raw) - response.raw_dwell(:, 1)*1e6)) < 1e-7, ...
    'Raw timing diagram disagrees with the recorded dwell durations.');
assert(raw(end-1) > nominal(end), 'The selected raw action does not invert the last interval.');
shift_us = 12;
coupling_offsets = zeros(N - 1, 1);
coupling_offsets(end) = shift_us;
applied = nominal + [0; coupling_offsets; 0];
assert(all(diff(applied) >= benchmark.applied_schedule_dwell_bound*1e6), ...
    'The isolated-offset illustration must remain dwell-feasible.');
data = struct('nominal', nominal, 'dwell', diff(nominal), ...
    'raw', raw, 'raw_dwell', diff(raw), 'raw_offsets', raw_offsets, ...
    'coupling', applied, 'coupling_dwell', diff(applied), ...
    'coupling_offsets', coupling_offsets, 'shift_us', shift_us, ...
    'period_us', nominal(end) - nominal(1), ...
    'dwell_bound_us', benchmark.applied_schedule_dwell_bound*1e6);
end
