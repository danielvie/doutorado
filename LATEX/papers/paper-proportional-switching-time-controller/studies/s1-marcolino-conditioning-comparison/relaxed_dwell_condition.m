function [actual, beta, dwell] = relaxed_dwell_condition(nominal, raw_offsets, minimum_dwell)
%RELAXED_DWELL_CONDITION Scale interior offsets, then minimally extend the end.
nominal = nominal(:);
raw_offsets = raw_offsets(:);
assert(numel(nominal) == numel(raw_offsets) + 2);
assert(all(isfinite(nominal)) && all(isfinite(raw_offsets)));
assert(isscalar(minimum_dwell) && isfinite(minimum_dwell) && minimum_dwell > 0);
margin = diff(nominal) - minimum_dwell;
assert(all(margin >= -1e-12), 'Nominal schedule violates minimum dwell.');
change = diff([0; raw_offsets; 0]);
% The terminal dwell does not restrict beta; all interior dwells still do.
restricting = change(1:end-1) < 0;
beta = 1;
if any(restricting)
    interior_margin = margin(1:end-1);
    interior_change = change(1:end-1);
    beta = min(1, min(interior_margin(restricting) ./ -interior_change(restricting)));
end
beta = max(0, beta);
actual = nominal + [0; beta * raw_offsets; 0];
actual(end) = max(nominal(end), actual(end-1) + minimum_dwell);
dwell = diff(actual);
assert(all(dwell >= minimum_dwell - 1e-12), 'Relaxed schedule is infeasible.');
end
