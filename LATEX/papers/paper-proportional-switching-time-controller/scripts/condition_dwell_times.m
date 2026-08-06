function [applied_offsets, beta, applied_dwell] = condition_dwell_times( ...
        nominal_boundaries, raw_offsets, applied_dwell_bound)
% Uniformly scale switching offsets by the largest feasible factor.

nominal_boundaries = nominal_boundaries(:);
raw_offsets = raw_offsets(:);
assert(numel(nominal_boundaries) == numel(raw_offsets) + 2, ...
    'Switching offsets must correspond to the internal boundaries.');

nominal_dwell = diff(nominal_boundaries);
available_dwell = nominal_dwell - applied_dwell_bound;
tolerance = 1e-12;
assert(all(available_dwell >= -tolerance), ...
    'The nominal schedule violates the applied dwell bound.');

raw_dwell_change = diff([0; raw_offsets; 0]);
restricting_intervals = raw_dwell_change < 0;
beta = 1;
if any(restricting_intervals)
    beta = min(1, min(available_dwell(restricting_intervals) ./ ...
        -raw_dwell_change(restricting_intervals)));
end
beta = min(1, max(0, beta));
applied_offsets = beta * raw_offsets;
applied_boundaries = nominal_boundaries + [0; applied_offsets; 0];
applied_dwell = diff(applied_boundaries);

assert(all(applied_dwell >= applied_dwell_bound - tolerance), ...
    'The dwell-time conditioner produced an infeasible schedule.');
end
