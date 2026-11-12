function test_relaxed_dwell_condition()
%TEST_RELAXED_DWELL_CONDITION Runnable checks for the restored handoff rule.
nominal = [0; 5; 9; 12];
[actual, beta, dwell] = relaxed_dwell_condition(nominal, [3; 2], 2);
assert(beta == 1 && isequal(actual, [0; 8; 11; 13]));
assert(isequal(dwell, [8; 3; 2]));
[actual, beta] = relaxed_dwell_condition(nominal, [0; -5], 2);
assert(abs(beta - 0.4) < 1e-14 && isequal(actual, [0; 5; 7; 12]));
[actual, beta] = relaxed_dwell_condition(nominal, [0; 0], 2);
assert(beta == 1 && isequal(actual, nominal));
[actual, beta] = relaxed_dwell_condition([0; 2; 4], [-1], 2);
assert(beta == 0 && isequal(actual, [0; 2; 4]));

% Check feasibility, maximal interior scaling, and minimal terminal extension.
rng(0);
for k = 1:100
    raw = 20 * randn(2,1);
    [actual, beta, dwell] = relaxed_dwell_condition(nominal, raw, 2);
    assert(beta >= 0 && beta <= 1 && all(dwell >= 2 - 1e-12));
    assert(norm(actual(2:end-1) - nominal(2:end-1) - beta*raw, inf) < 1e-12);
    assert(actual(end) == max(nominal(end), actual(end-1) + 2));
    if beta < 1
        larger = nominal + [0; min(1,beta+1e-6)*raw; 0];
        interior = diff(larger);
        assert(any(interior(1:end-1) < 2));
    end
end
fprintf('Relaxed dwell conditioner checks passed.\n');
end
