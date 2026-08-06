function designs = design_robust_controllers(nominal_model, vertex_models)
% Design matched nominal, guaranteed-cost, and H-infinity state feedback.

assert(exist('sdpvar', 'file') == 2, ...
    'YALMIP is required to design the robust controllers.');
designs.nominal = dlqr(nominal_model.A, nominal_model.B, eye(3), eye(8));
[designs.guaranteed_cost, designs.guaranteed_cost_trace] = ...
    guaranteed_cost_gain(vertex_models);
[designs.hinfinity, designs.hinfinity_gamma] = ...
    hinfinity_gain(vertex_models);
end

function [K, cost_trace] = guaranteed_cost_gain(models)
n = size(models(1).A, 1);
m = size(models(1).B, 2);
X = sdpvar(n, n, 'symmetric');
Y = sdpvar(m, n, 'full');
S = sdpvar(n, n, 'symmetric');
margin = 1e-7;
constraints = [X >= margin * eye(n), S >= margin * eye(n), ...
    [S, eye(n); eye(n), X] >= margin * eye(2 * n)];

for index = 1:numel(models)
    F = models(index).A * X - models(index).B * Y;
    performance = [ ...
        X, F', X, Y'; ...
        F, X, zeros(n), zeros(n, m); ...
        X, zeros(n), eye(n), zeros(n, m); ...
        Y, zeros(m, n), zeros(m, n), eye(m)];
    constraints = [constraints, ...
        performance >= margin * eye(3 * n + m)]; %#ok<AGROW>
end

diagnostics = optimize(constraints, trace(S), solver_options());
assert(diagnostics.problem == 0, diagnostics.info);
assert(min(check(constraints)) >= -1e-7, ...
    'Guaranteed-cost LMI residual exceeds tolerance.');
K = value(Y) / value(X);
cost_trace = trace(inv(value(X)));
end

function [K, gamma_value] = hinfinity_gain(models)
n = size(models(1).A, 1);
m = size(models(1).B, 2);
nw = n;
nz = n + m;
X = sdpvar(n, n, 'symmetric');
Y = sdpvar(m, n, 'full');
gamma = sdpvar(1);
C = [eye(n); zeros(m, n)];
D = [zeros(n, m); eye(m)];
Bw = eye(n);
Dzw = zeros(nz, nw);
margin = 1e-7;
constraints = [X >= margin * eye(n), gamma >= margin];

for index = 1:numel(models)
    F = models(index).A * X - models(index).B * Y;
    G = C * X - D * Y;
    bounded_real = [ ...
        X, zeros(n, nw), F', G'; ...
        zeros(nw, n), gamma * eye(nw), Bw', Dzw'; ...
        F, Bw, X, zeros(n, nz); ...
        G, Dzw, zeros(nz, n), gamma * eye(nz)];
    constraints = [constraints, ...
        bounded_real >= margin * eye(2 * n + nw + nz)]; %#ok<AGROW>
end

diagnostics = optimize(constraints, gamma, solver_options());
assert(diagnostics.problem == 0, diagnostics.info);
assert(min(check(constraints)) >= -1e-7, ...
    'H-infinity LMI residual exceeds tolerance.');
K = value(Y) / value(X);
gamma_value = value(gamma);
end

function options = solver_options()
options = sdpsettings('solver', 'sedumi', 'verbose', 0, ...
    'sedumi.eps', 1e-7);
end
