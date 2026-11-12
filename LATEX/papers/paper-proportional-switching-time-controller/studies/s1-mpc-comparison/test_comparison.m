function test_comparison()
%TEST_COMPARISON Check normalization, condensed cost, and dwell constraints.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'scripts'));
paths = paper.paths();
addpath(paths.simulation);
b = paper.benchmark();
model = paper.validate_model(b);
c = paper.design_feedback(b, model);
for horizon = 5
    p = mpc_problem(b, model, horizon);
    A = p.prediction.state_transition;
    B = p.prediction.input_matrix;
    n = size(A, 1); m = size(B, 2);
    assert(p.qp.plan_size == m*horizon);
    Q = eye(n) / b.aggressive_input_weight;
    [K, P] = dlqr(A, B, Q, eye(m));
    assert(norm(K - c.K_aggressive_normalized, 'fro') < 1e-9);
    assert(p.update_period_cycles == 1 && ~p.prediction.uses_previous_action);

    % Independently condense the thesis cost: states 0:N-1, terminal P at N.
    H = eye(m*horizon); G = zeros(m*horizon, n);
    F = eye(n); T = zeros(n, m*horizon);
    for j = 1:horizon
        F = A * F; T = A * T;
        columns = (j-1)*m + (1:m);
        T(:, columns) = B;
        W = Q;
        if j == horizon, W = P; end
        H = H + T' * W * T;
        G = G + T' * W * F;
    end
    assert(norm(p.qp.hessian - 2*H, 'fro') / norm(2*H, 'fro') < 1e-10);
    assert(norm(p.qp.gradient_map - 2*G, 'fro') / norm(2*G, 'fro') < 1e-10);
    z = 1e-4 * (b.state_scale \ (b.initial_state - b.orbit_anchor));
    [v, ~, flag] = Mpc.solve(p, z);
    assert(flag == 1 && norm(v + K*z, inf) < 1e-8, ...
        'Inactive-constraint MPC must recover the same LQR action.');

    % The last dwell changes by MINUS the final interior offset.
    D = diff([zeros(1,m); eye(m); zeros(1,m)]);
    assert(isequal(D(end,:), [zeros(1,m-1), -1]));
    assert(all(sum(D, 1) == 0));
    dwell_rows = numel(b.nominal_dwell)*horizon;
    assert(isequal(p.qp.inequality_matrix(1:dwell_rows,:), -kron(eye(horizon),D)));
    expected_bound = repmat((b.nominal_dwell - ...
        b.applied_schedule_dwell_bound)/b.timing_scale, horizon, 1);
    assert(norm(p.qp.inequality_base_bound(1:dwell_rows)-expected_bound, inf) < 1e-12);
    for scale = 1:3
        z = scale * (b.state_scale \ (b.initial_state - b.orbit_anchor));
        [v, ~, flag] = Mpc.solve(p, z);
        assert(flag == 1);
        dwell = diff(b.config.Ts(:) + [0; b.timing_scale*v; 0]);
        assert(all(dwell >= b.applied_schedule_dwell_bound - 1e-12));
    end
end
fprintf('MPC comparison checks passed.\n');
end
