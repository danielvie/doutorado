%% Optimize a stability certificate for beta = 0
% beta = 0 switches off the timing correction, so A(0) = Phi.
% This self-contained example embeds A(0), computes P with YALMIP and
% SeDuMi, then verifies the returned certificate with ordinary MATLAB.

clear;
clc;
yalmip('clear');

% Normalized open-loop cycle matrix A(0) = Sx\Phi*Sx.
A0 = [ ...
    0.9995280567716458, -0.003749611399359397,  0.011228748053280968; ...
    0.00087811583019049822, 0.99991947134024128, 0.003637231642537442; ...
    0.0055604993830638298, -0.00027660207248294416, 0.75173693112518947];

% Find P and the largest common Euclidean decrease margin t such that
%
%   P >= epsilon*I,
%   trace(P) = 1,
%   P - A(0)'*P*A(0) >= t*I,
%   t >= 0.
%
% A positive t proves strict decrease of V(z) = z'*P*z.
n = size(A0, 1);
P_variable = sdpvar(n, n, 'symmetric');
t_variable = sdpvar(1);
epsilon = 1e-8;
constraints = [ ...
    P_variable >= epsilon * eye(n), ...
    trace(P_variable) == 1, ...
    t_variable >= 0, ...
    P_variable - A0' * P_variable * A0 >= t_variable * eye(n)];
options = sdpsettings('solver', 'sedumi', 'verbose', 0, 'sedumi.eps', 1e-9);
diagnostics = optimize(constraints, -t_variable, options);
if diagnostics.problem ~= 0
    error('The beta = 0 SDP failed: %s', diagnostics.info);
end

% Never trust the solver status alone. Recheck the certificate numerically.
P = value(P_variable);
P = (P + P') / 2;
optimized_margin = value(t_variable);
Q0 = P - A0' * P * A0;
Q0 = (Q0 + Q0') / 2;

lambda_min_P = min(eig(P));
lambda_min_Q0 = min(eig(Q0));
tolerance = 1e-10;
assert(lambda_min_P > tolerance, 'P is not numerically positive definite.');
assert(lambda_min_Q0 > tolerance, ...
    'P - A(0)''*P*A(0) is not numerically positive definite.');

R = chol(P);
q0 = norm(R * A0 / R, 2);
rho0 = max(abs(eig(A0)));
assert(q0 < 1 - tolerance, 'A(0) is not a strict contraction in the P-norm.');

fprintf('Optimized stability certificate for beta = 0\n');
fprintf('P =\n');
disp(P);
fprintf('optimized t                          = %.12e\n', optimized_margin);
fprintf('lambda_min(P)                       = %.12e\n', lambda_min_P);
fprintf('lambda_min(P - A(0)''*P*A(0))       = %.12e\n', lambda_min_Q0);
fprintf('rho(A(0))                           = %.12f\n', rho0);
fprintf('||A(0)||_P                          = %.12f\n', q0);
fprintf('Conclusion: V(z) = z''Pz decreases strictly for every z ~= 0.\n');
fprintf('Therefore z(k+1) = A(0)z(k) is exponentially stable.\n');
