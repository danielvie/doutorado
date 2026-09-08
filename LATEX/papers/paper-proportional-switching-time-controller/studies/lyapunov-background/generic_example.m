function results = generic_example()
%GENERIC_EXAMPLE  Compute a common quadratic Lyapunov function by SDP.
%
%   Companion script for lyapunov-convex-optimization.html, Chapter 1.
%
%   The plant is a discrete-time switched linear system
%
%       x(k+1) = A_{sigma(k)} x(k),    sigma(k) in {1,2},
%
%   with an arbitrary, unknown switching signal.  Both modes are Schur, but
%   both expand the Euclidean norm in some directions, so V(x) = x'x is not a
%   Lyapunov function, and neither is the Lyapunov matrix of either mode taken
%   alone.  We search for a common P by semidefinite programming.
%
%   Requires YALMIP and a semidefinite solver (SeDuMi is used here).

A = {[ 1.3  0.6; -1.0 -0.3], ...
     [-0.1  0.8; -0.3 -1.1]};
n = size(A{1}, 1);

section('1. Why the obvious candidates fail');

for i = 1:numel(A)
    fprintf('A%d spectral radius   %.4f   (Schur)\n', i, max(abs(eig(A{i}))));
    fprintf('A%d eigenvalues       %s\n', i, mat2str(sort(eig(A{i}))', 4));
    fprintf('A%d 2-norm            %.4f   %s\n', i, norm(A{i}), ...
        ternary(norm(A{i}) > 1, '(expands some direction)', ''));
end

% V(x) = x'x.  The decrease condition is A'A - I < 0, i.e. norm(A) < 1.
for i = 1:numel(A)
    fprintf('P = I : max eig(A%d''*A%d - I) = %+.4f\n', i, i, ...
        max(eig(A{i}' * A{i} - eye(n))));
end

% Each mode's own Lyapunov matrix, from the discrete Lyapunov equation
% A'*P*A - P = -I.  It certifies its own mode by construction; test the other.
P_own = cell(1, numel(A));
for i = 1:numel(A)
    P_own{i} = dlyap(A{i}', eye(n));
end
for i = 1:numel(A)
    j = 3 - i;
    fprintf('P from mode %d: max eig(A%d''*P*A%d - P) = %+.4f   %s\n', ...
        i, j, j, max(eig(A{j}' * P_own{i} * A{j} - P_own{i})), ...
        ternary(max(eig(A{j}' * P_own{i} * A{j} - P_own{i})) > 0, ...
        '-> fails for the other mode', '-> also works'));
end

% Restrict the search to diagonal P and the problem becomes infeasible.
fprintf('Diagonal P feasible: %d\n', diagonal_certificate(A));

section('2. The semidefinite program');

[P, decrease] = common_lyapunov(A);
fprintf('P =\n'); disp(P);
fprintf('eig(P)              %s   (positive definite)\n', mat2str(eig(P)', 5));
fprintf('cond(P)             %.4f\n', cond(P));
fprintf('decrease margin     %.6f\n', decrease);

section('3. Verifying the certificate independently of the solver');

q = zeros(1, numel(A));
for i = 1:numel(A)
    decrease_i = P - A{i}' * P * A{i};
    decrease_i = (decrease_i + decrease_i') / 2;
    q(i) = sqrt(max(real(eig(A{i}' * P * A{i}, P))));
    fprintf('mode %d: min eig(P - A''PA) = %+.6f   ||A%d||_P = %.6f\n', ...
        i, min(eig(decrease_i)), i, q(i));
end
fprintf('contraction factor  q = %.6f  (V drops by at least q^2 = %.6f per step)\n', ...
    max(q), max(q)^2);

section('4. The same P covers every convex combination');

betas = linspace(0, 1, 101);
mixed = zeros(size(betas));
for k = 1:numel(betas)
    Ab = (1 - betas(k)) * A{1} + betas(k) * A{2};
    mixed(k) = sqrt(max(real(eig(Ab' * P * Ab, P))));
end
fprintf('max over the segment ||(1-b)A1 + bA2||_P = %.6f <= max(||A1||_P,||A2||_P) = %.6f\n', ...
    max(mixed), max(q));

section('5. Adversarial switching: the norm rises, V falls');

x = [1; 0];
x = x / sqrt(x' * P * x);
steps = 24;
traj = zeros(n, steps + 1); traj(:, 1) = x;
mode = zeros(1, steps);
for k = 1:steps
    % Pick, at every step, the mode that grows the Euclidean norm the most.
    candidates = cellfun(@(Ai) norm(Ai * x), A);
    [~, mode(k)] = max(candidates);
    x = A{mode(k)} * x;
    traj(:, k + 1) = x;
end
euclid = sqrt(sum(traj.^2, 1));
lyap_value = sum(traj .* (P * traj), 1);
fprintf('switching sequence  %s\n', mat2str(mode));
fprintf('max ||x_k||_2 / ||x_0||_2 = %.4f at step %d\n', ...
    max(euclid) / euclid(1), find(euclid == max(euclid), 1) - 1);
fprintf('V monotonically decreasing: %d\n', all(diff(lyap_value) < 0));

section('6. A pair with no common quadratic Lyapunov function');

B = {[0.75 1.6; 0.00 0.75], ...
     [0.75 0.0; -1.6 0.75]};
fprintf('rho(B1) = %.4f, rho(B2) = %.4f  (both Schur)\n', ...
    max(abs(eig(B{1}))), max(abs(eig(B{2}))));
fprintf('rho(B1*B2) = %.4f  (the alternating sequence diverges)\n', ...
    max(abs(eig(B{1} * B{2}))));
try
    common_lyapunov(B);
    fprintf('unexpected: the SDP returned a certificate\n');
catch err
    fprintf('SDP status: %s\n', err.message);
end

results = struct('A', {A}, 'P', P, 'q', q, 'betas', betas, 'mixed', mixed, ...
    'trajectory', traj, 'mode', mode, 'euclidean', euclid, ...
    'lyapunov', lyap_value, 'decrease', decrease);
end

% -------------------------------------------------------------------------

function [P, decrease] = common_lyapunov(A)
%COMMON_LYAPUNOV  Largest-margin common quadratic Lyapunov matrix.
%
%   Solves, over the symmetric matrix P and the scalar t,
%
%       maximise    t
%       subject to  P >= eps*I,  trace(P) = n,  t >= 0,
%                   A_i'*P*A_i - P <= -t*I   for every mode i.
%
%   Both the constraints and the objective are linear in (P, t), so this is a
%   semidefinite program.  The trace equality removes the scale freedom that
%   would otherwise make t unbounded.
n = size(A{1}, 1);
P_var = sdpvar(n, n, 'symmetric');
t = sdpvar(1);

constraints = [P_var >= 1e-8 * eye(n), trace(P_var) == n, t >= 0];
for i = 1:numel(A)
    constraints = [constraints, ...
        A{i}' * P_var * A{i} - P_var <= -t * eye(n)];  %#ok<AGROW>
end

diagnostics = optimize(constraints, -t, ...
    sdpsettings('solver', 'sedumi', 'verbose', 0, 'sedumi.eps', 1e-9));
if diagnostics.problem ~= 0
    error('common_lyapunov:infeasible', '%s', diagnostics.info);
end

P = value(P_var);
P = (P + P') / 2;
decrease = value(t);
if min(eig(P)) <= 0 || decrease <= 0
    error('common_lyapunov:notStrict', 'the returned certificate is not strict');
end
end

function ok = diagonal_certificate(A)
%DIAGONAL_CERTIFICATE  Same SDP, restricted to diagonal P.
n = size(A{1}, 1);
p = sdpvar(n, 1);
P_var = diag(p);
constraints = [p >= 1e-6, sum(p) == n];
for i = 1:numel(A)
    constraints = [constraints, ...
        A{i}' * P_var * A{i} - P_var <= -1e-6 * eye(n)];  %#ok<AGROW>
end
diagnostics = optimize(constraints, [], ...
    sdpsettings('solver', 'sedumi', 'verbose', 0));
ok = (diagnostics.problem == 0);
end

function section(title_text)
fprintf('\n%s\n%s\n', title_text, repmat('-', 1, numel(title_text)));
end

function out = ternary(condition, a, b)
if condition, out = a; else, out = b; end
end
