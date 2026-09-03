%% Optimize a stability certificate for beta = 1
% beta = 1 applies the raw timing correction without scaling, so
% A(1) = A_cl. This self-contained example embeds A(1), computes P with
% YALMIP and SeDuMi, then verifies the returned certificate with MATLAB.

clear;
clc;
yalmip('clear');

% Normalized aggressive closed-loop matrix A(1) = A0 - B*K.
A1 = [ ...
     0.18935732287372764,  0.090979279144644237, -0.021282549873311941; ...
     0.091998670607239333, 0.53885359203736816,  -0.025611841026874037; ...
    -0.03717344743950296, -0.058593575297072341,  0.27745469771450704];

% Find P and the largest Euclidean decrease margin t such that
%
%   P >= epsilon*I,
%   trace(P) = 1,
%   P - A(1)'*P*A(1) >= t*I,
%   t >= 0.
%
% A positive t proves strict decrease of V(z) = z'*P*z.
n = size(A1, 1);
P_variable = sdpvar(n, n, 'symmetric');
t_variable = sdpvar(1);
epsilon = 1e-8;
constraints = [ ...
    P_variable >= epsilon * eye(n), ...
    trace(P_variable) == 1, ...
    t_variable >= 0, ...
    P_variable - A1' * P_variable * A1 >= t_variable * eye(n)];
options = sdpsettings('solver', 'sedumi', 'verbose', 0, 'sedumi.eps', 1e-9);
diagnostics = optimize(constraints, -t_variable, options);
if diagnostics.problem ~= 0
    error('The beta = 1 SDP failed: %s', diagnostics.info);
end

% Never trust the solver status alone. Recheck the certificate numerically.
P = value(P_variable);
P = (P + P') / 2;
optimized_margin = value(t_variable);
Q1 = P - A1' * P * A1;
Q1 = (Q1 + Q1') / 2;

lambda_min_P = min(eig(P));
lambda_min_Q1 = min(eig(Q1));
tolerance = 1e-10;
assert(lambda_min_P > tolerance, 'P is not numerically positive definite.');
assert(lambda_min_Q1 > tolerance, ...
    'P - A(1)''*P*A(1) is not numerically positive definite.');

R = chol(P);
q1 = norm(R * A1 / R, 2);
rho1 = max(abs(eig(A1)));
assert(q1 < 1 - tolerance, 'A(1) is not a strict contraction in the P-norm.');

fprintf('Optimized stability certificate for beta = 1\n');
fprintf('P =\n');
disp(P);
fprintf('optimized t                          = %.12e\n', optimized_margin);
fprintf('lambda_min(P)                       = %.12e\n', lambda_min_P);
fprintf('lambda_min(P - A(1)''*P*A(1))       = %.12e\n', lambda_min_Q1);
fprintf('rho(A(1))                           = %.12f\n', rho1);
fprintf('||A(1)||_P                          = %.12f\n', q1);
fprintf('Conclusion: V(z) = z''Pz decreases strictly for every z ~= 0.\n');
fprintf('Therefore the beta = 1 linearized closed loop is exponentially stable.\n');
fprintf('With strict dwell margin, beta remains 1 near the orbit, so the exact\n');
fprintf('nonlinear cycle map is locally exponentially stable there.\n');
