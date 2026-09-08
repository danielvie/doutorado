function [time, state] = sample_cycle(config, initial_state, offsets, samples_per_interval)
%SAMPLE_CYCLE Dense exact interval propagation, not a switching-boundary polygon.
assert(isscalar(samples_per_interval) && samples_per_interval >= 1 && ...
    samples_per_interval == fix(samples_per_interval), 'Invalid sampling count.');
boundaries = config.Ts(:) + [0; offsets(:); 0];
assert(all(diff(boundaries) > 0), 'Dense propagation requires positive dwells.');
n = numel(initial_state);
count = numel(config.Omega) * samples_per_interval + 1;
time = zeros(count, 1);
state = zeros(count, n);
time(1) = boundaries(1);
state(1, :) = initial_state(:)';
current = initial_state(:);
cursor = 1;
for interval = 1:numel(config.Omega)
    mode = config.Omega(interval);
    F = [config.A{mode}, config.b{mode}; zeros(1, n + 1)];
    duration = boundaries(interval + 1) - boundaries(interval);
    for sample = 1:samples_per_interval
        local_time = duration * sample / samples_per_interval;
        propagated = expm(F * local_time) * [current; 1];
        cursor = cursor + 1;
        time(cursor) = boundaries(interval) + local_time;
        state(cursor, :) = propagated(1:n)';
    end
    current = state(cursor, :)';
end
end
