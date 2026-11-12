function actual = sequential_dwell_condition(nominal, raw_offsets, minimum_dwell)
%SEQUENTIAL_DWELL_CONDITION Actuator-side rule adapted from Marcolino et al., Alg. 1.
% All times are relative to the current cycle start. The terminal switch can
% occur after the nominal boundary; do not silently truncate it.
nominal = nominal(:);
raw_offsets = raw_offsets(:);
assert(numel(nominal) == numel(raw_offsets) + 2);
assert(all(diff(nominal) >= minimum_dwell - 1e-12));
assert(isscalar(minimum_dwell) && minimum_dwell > 0);
actual = zeros(size(nominal));
actual(1) = nominal(1);
for i = 2:numel(nominal)-1
    actual(i) = max(nominal(i) + raw_offsets(i-1), ...
        actual(i-1) + minimum_dwell);
end
actual(end) = max(nominal(end), actual(end-1) + minimum_dwell);
assert(all(diff(actual) >= minimum_dwell - 1e-12));
end
