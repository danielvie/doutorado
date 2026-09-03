%% Optimize a common certificate for every beta in [0, 1]
% The conditioned linearized family is
%
%   A(beta) = (1 - beta)A(0) + beta A(1).
%
% This self-contained example embeds both endpoints and computes one P that
% contracts both. Convexity of the induced P-norm then proves contraction
% for the full segment without sampling beta.

clear;
clc;
yalmip('clear');

% Normalized endpoint matrices from the paper's generated linear model.
A0 = [ ...
    0.9995280567716458, -0.003749611399359397,  0.011228748053280968; ...
    0.00087811583019049822, 0.99991947134024128, 0.003637231642537442; ...
    0.0055604993830638298, -0.00027660207248294416, 0.75173693112518947];
A1 = [ ...
     0.18935732287372764,  0.090979279144644237, -0.021282549873311941; ...
     0.091998670607239333, 0.53885359203736816,  -0.025611841026874037; ...
    -0.03717344743950296, -0.058593575297072341,  0.27745469771450704];

% Find one P and the largest common Euclidean decrease margin t such that
%
%   P >= epsilon*I,
%   trace(P) = 1,
%   P - A(0)'*P*A(0) >= t*I,
%   P - A(1)'*P*A(1) >= t*I,
%   t >= 0.
%
% A positive t means the same V(z) = z'*P*z decreases at both endpoints.
n = size(A0, 1);
P_variable = sdpvar(n, n, 'symmetric');
t_variable = sdpvar(1);
epsilon = 1e-8;
constraints = [ ...
    P_variable >= epsilon * eye(n), ...
    trace(P_variable) == 1, ...
    t_variable >= 0, ...
    P_variable - A0' * P_variable * A0 >= t_variable * eye(n), ...
    P_variable - A1' * P_variable * A1 >= t_variable * eye(n)];
options = sdpsettings('solver', 'sedumi', 'verbose', 0, 'sedumi.eps', 1e-9);
diagnostics = optimize(constraints, -t_variable, options);
if diagnostics.problem ~= 0
    error('The beta in [0,1] common-P SDP failed: %s', diagnostics.info);
end

% Never trust the solver status alone. Recheck both endpoint inequalities.
P = value(P_variable);
P = (P + P') / 2;
optimized_margin = value(t_variable);
Q0 = P - A0' * P * A0;
Q1 = P - A1' * P * A1;
Q0 = (Q0 + Q0') / 2;
Q1 = (Q1 + Q1') / 2;

lambda_min_P = min(eig(P));
lambda_min_Q0 = min(eig(Q0));
lambda_min_Q1 = min(eig(Q1));
tolerance = 1e-10;
assert(lambda_min_P > tolerance, 'P is not numerically positive definite.');
assert(lambda_min_Q0 > tolerance, ...
    'The beta = 0 endpoint does not satisfy the strict Lyapunov inequality.');
assert(lambda_min_Q1 > tolerance, ...
    'The beta = 1 endpoint does not satisfy the strict Lyapunov inequality.');

R = chol(P);
q0 = norm(R * A0 / R, 2);
q1 = norm(R * A1 / R, 2);
q = max(q0, q1);
assert(q < 1 - tolerance, ...
    'The common P-norm does not strictly contract both endpoints.');

fprintf('Optimized common certificate for beta in [0, 1]\n');
fprintf('P =\n');
disp(P);
fprintf('optimized common t                   = %.12e\n', optimized_margin);
fprintf('lambda_min(P)                       = %.12e\n', lambda_min_P);
fprintf('lambda_min(P - A(0)''*P*A(0))       = %.12e\n', lambda_min_Q0);
fprintf('lambda_min(P - A(1)''*P*A(1))       = %.12e\n', lambda_min_Q1);
fprintf('q0 = ||A(0)||_P                     = %.12f\n', q0);
fprintf('q1 = ||A(1)||_P                     = %.12f\n', q1);
fprintf('q  = max(q0, q1)                    = %.12f\n', q);
fprintf('\nFor every beta in [0, 1]:\n');
fprintf('  ||A(beta)||_P <= (1-beta)q0 + beta*q1 <= q < 1.\n');
fprintf('For every sequence beta(k) in [0, 1]:\n');
fprintf('  ||z(k)||_P <= q^k ||z(0)||_P.\n');
fprintf('Conclusion: the conditioned linearized family is uniformly exponentially stable.\n');
