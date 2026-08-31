function results = damped_oscillator_cvx()
%DAMPED_OSCILLATOR_CVX  Find a Lyapunov function for one system, using CVX.
%
%   Companion script for computing-v-with-cvx.html.
%
%   The system is a damped mass-spring oscillator written in state-space form.
%   We do three things with it:
%
%     1. test the mechanical energy as a Lyapunov function, and watch it fail
%        the strict-decrease requirement;
%     2. ask CVX for a P that does satisfy it;
%     3. ask CVX for the fastest decay rate that P can certify, and check that
%        answer against the eigenvalues of A.
%
%   Requires CVX. Run cvx_example first if you are not sure it is installed.

%% The system ------------------------------------------------------------
m = 1.0;      % mass, kg
c = 0.4;      % damping, N.s/m
k = 4.0;      % spring stiffness, N/m

A = [    0        1    ;
     -k/m      -c/m ];

section('1. The system');
fprintf('A =\n'); disp(A);
lambda = eig(A);
fprintf('eigenvalues       %.4f +/- %.4fi\n', real(lambda(1)), abs(imag(lambda(1))));
fprintf('all real parts negative: %d  (so the origin is asymptotically stable)\n', ...
    all(real(lambda) < 0));

%% The obvious guess: mechanical energy ----------------------------------
% Total energy is  E = 0.5*k*x^2 + 0.5*m*v^2,  which is x'*P_energy*x with
P_energy = [k/2   0  ;
             0   m/2];

section('2. The mechanical energy, tested as a Lyapunov function');
S_energy = A' * P_energy + P_energy * A;
fprintf('P_energy =\n'); disp(P_energy);
fprintf('A''*P + P*A =\n'); disp(S_energy);
fprintf('its eigenvalues   %s\n', mat2str(round(eig(S_energy), 10)', 6));
fprintf('negative definite: %d      (we need this, and we do not have it)\n', ...
    all(eig(S_energy) < 0));
fprintf('negative semidefinite: %d  (this is all the energy gives us)\n', ...
    all(eig(S_energy) <= 1e-12));
fprintf('\nThe zero eigenvalue is not a rounding artefact. Along the whole\n');
fprintf('x axis the velocity is zero, the damper does no work, and the\n');
fprintf('energy does not change at that instant.\n');

%% Ask CVX for a P that works --------------------------------------------
section('3. Asking CVX for a certificate');
n = size(A, 1);
cvx_begin sdp quiet
    variable P(n, n) symmetric
    minimize(0)                       % feasibility only: any P will do
    subject to
        P - eye(n) == semidefinite(n);              % P >= I
        -(A'*P + P*A) - eye(n) == semidefinite(n);  % A'P + PA <= -I
cvx_end

assert(strcmp(cvx_status, 'Solved'), ...
    'CVX did not find a certificate. Status: %s', cvx_status);
P = (P + P') / 2;                     % symmetrise what the solver returned
fprintf('CVX status        %s\n', cvx_status);
fprintf('P =\n'); disp(P);

%% Check the answer without trusting the solver --------------------------
section('4. Checking the certificate');
S = A' * P + P * A;
S = (S + S') / 2;
fprintf('eig(P)            %s        all positive: %d\n', ...
    mat2str(eig(P)', 6), all(eig(P) > 0));
fprintf('eig(A''P + PA)     %s   all negative: %d\n', ...
    mat2str(eig(S)', 6), all(eig(S) < 0));
fprintf('cond(P)           %.4f\n', cond(P));

%% Ask for the best decay rate -------------------------------------------
% V(x) = x'Px decays at least as fast as exp(-2*alpha*t) when
%     A'P + PA <= -2*alpha*P.
% For a fixed alpha that is still linear in P, so we bisect on alpha.
section('5. The fastest decay rate this form can certify');
lo = 0; hi = 5;
for iteration = 1:40
    mid = (lo + hi) / 2;
    if rate_feasible(A, mid)
        lo = mid;
    else
        hi = mid;
    end
end
alpha = lo;
fprintf('best certified alpha   %.6f\n', alpha);
fprintf('-max(real(eig(A)))     %.6f\n', -max(real(eig(A))));
fprintf('difference             %.2e   (they agree, as they must)\n', ...
    abs(alpha + max(real(eig(A)))));

[P_rate, ok] = rate_certificate(A, alpha * 0.999);
fprintf('\nP for that rate =\n'); disp(P_rate);
fprintf('cond(P_rate)      %.4f\n', cond(P_rate));
fprintf('so ||x(t)|| <= %.3f * exp(-%.4f t) * ||x(0)||\n', ...
    sqrt(cond(P_rate)), alpha * 0.999);

%% Trajectory, energy and V ----------------------------------------------
x0 = [1; 0];
t = linspace(0, 25, 2001);
X = zeros(2, numel(t));
for i = 1:numel(t)
    X(:, i) = expm(A * t(i)) * x0;
end
energy = sum(X .* (P_energy * X), 1);
lyapunov = sum(X .* (P * X), 1);

section('6. Along one trajectory');
fprintf('energy strictly decreasing at every sample: %d\n', ...
    all(diff(energy) < 0));
fprintf('V strictly decreasing at every sample:      %d\n', ...
    all(diff(lyapunov) < 0));
fprintf('smallest energy decrease per sample:  %.3e\n', max(diff(energy)));
fprintf('smallest V decrease per sample:       %.3e\n', max(diff(lyapunov)));

results = struct('A', A, 'P_energy', P_energy, 'P', P, 'P_rate', P_rate, ...
    'alpha', alpha, 'time', t, 'state', X, 'energy', energy, ...
    'lyapunov', lyapunov, 'rate_ok', ok);
end

% -------------------------------------------------------------------------

function ok = rate_feasible(A, alpha)
%RATE_FEASIBLE  Is there a P with A'P + PA <= -2*alpha*P and P >= I?
n = size(A, 1);
cvx_begin sdp quiet
    variable P(n, n) symmetric
    minimize(0)
    subject to
        P - eye(n) == semidefinite(n);
        -(A'*P + P*A + 2*alpha*P) == semidefinite(n);
cvx_end
ok = strcmp(cvx_status, 'Solved');
end

function [P, ok] = rate_certificate(A, alpha)
n = size(A, 1);
cvx_begin sdp quiet
    variable P(n, n) symmetric
    minimize(0)
    subject to
        P - eye(n) == semidefinite(n);
        -(A'*P + P*A + 2*alpha*P) == semidefinite(n);
cvx_end
ok = strcmp(cvx_status, 'Solved');
P = (P + P') / 2;
end

function section(title_text)
fprintf('\n%s\n%s\n', title_text, repmat('-', 1, numel(title_text)));
end
