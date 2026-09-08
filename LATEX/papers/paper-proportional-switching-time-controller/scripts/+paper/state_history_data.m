function view = state_history_data(data, benchmark, cycles)
%STATE_HISTORY_DATA Select complete saved cycles and repeat the nominal waveform.
% Controlled and open-loop samples have different within-cycle timestamps.
% Never put both arrays on one time grid or replace the periodic target by its mean.
if nargin < 3, cycles = min(12, benchmark.cycle_count); end
assert(cycles >= 1 && cycles == floor(cycles) && cycles <= benchmark.cycle_count, ...
    'Requested state-history window is outside the saved run.');
n = size(data.reference_state, 1)-1;
assert(numel(data.reference_time) == n+1 && n > 0, 'Invalid reference sampling.');
assert(abs(data.reference_time(1)) < 1e-14 && ...
    abs(data.reference_time(end)-benchmark.period) < 1e-14, 'Reference period mismatch.');
assert(norm(data.reference_state(1,:)'-benchmark.orbit_anchor, inf) < 1e-10, ...
    'Reference anchor mismatch.');
assert(norm(data.reference_state(end,:)-data.reference_state(1,:), inf) < 1e-8, ...
    'Reference waveform does not close.');
for name = {'on', 'off'}
    state = data.(['state_',name{1}]); time = data.(['time_',name{1}]);
    assert(size(state,1) == benchmark.cycle_count*n+1 && size(state,2) == 3 && ...
        numel(time) == size(state,1), 'Dense state/time sample mismatch.');
    assert(all(diff(time)>0), 'Saved within-cycle times must be increasing.');
    assert(abs(time(cycles*n+1)-cycles*benchmark.period) < 1e-12, 'Cycle endpoint mismatch.');
    assert(norm(state(1,:)'-benchmark.initial_state, inf) < 1e-10, 'Initial state mismatch.');
    view.(['time_',name{1}]) = time(1:cycles*n+1);
    view.(['state_',name{1}]) = state(1:cycles*n+1,:);
end
reference_time = data.reference_time(1:end-1) + (0:cycles-1)*benchmark.period;
view.reference_time = [reference_time(:); cycles*benchmark.period];
view.reference_state = [repmat(data.reference_state(1:end-1,:), cycles, 1); data.reference_state(end,:)];
view.cycles = cycles;
end
