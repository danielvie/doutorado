%% EX2 -- Complex example: switched linear system with NO common quadratic V
%
%   xdot = A_sigma x,  sigma(t) in {1,2}  (arbitrary switching)
%   A1 = [-1 -1; 1 -1],   A2 = [-1 -a; 1/a -1],   a = 10
%
% Both modes have eigenvalues -1 +/- i (individually very stable), yet for
% a >= 3 + 2*sqrt(2) ~ 5.83 NO single quadratic V works for both modes.
% For a = 10 even quartic and sextic V fail; the first success is degree 8.
%
% Part A: analytic obstruction (Shorten-Narendra product test)
% Part B: CVX PROVES the common-quadratic LMI is infeasible
% Part C: degree escalation -- search homogeneous V of degree 2,4,6,8 (SOS as SDP)
% Part D: independent verification of the winning certificate on a grid
% Part E: sanity check -- worst-case switching contracts, but barely
% Part F: the difficulty landscape -- minimal degree as a function of a
%
% Requires: CVX
%
% Key fact that keeps this LOSSLESS in 2 states: a nonnegative polynomial in
% TWO variables is always a sum of squares (Hilbert, 1888). So when the SDP
% says "Infeasible" at degree 2m, no homogeneous degree-2m Lyapunov function
% exists at all (up to the small strictness margin) -- it is a certificate
% of absence, not a weakness of the method.

clear; clc;
a  = 10;
A1 = [-1 -1; 1 -1];
A2 = [-1 -a; 1/a -1];

fprintf('=== EX2: switched system, a = %g ===\n', a);
fprintf('eig(A1) = %s\n', mat2str(eig(A1).', 4));
fprintf('eig(A2) = %s\n\n', mat2str(eig(A2).', 4));

%% Part A -- analytic obstruction: eigenvalues of A1*A2
% Shorten & Narendra: for two stable 2x2 systems a common quadratic V exists
% iff neither A1*A2 nor A1*inv(A2) has a real negative eigenvalue.
fprintf('--- Part A: product test ---\n');
fprintf('eig(A1*A2)      = %s\n', mat2str(eig(A1*A2).', 4));
fprintf('eig(A1*inv(A2)) = %s\n', mat2str(eig(A1/A2).', 4));
fprintf('trace(A1*A2) = 2 - a - 1/a = %.4f  (< -4 with det = 4 => real negative eigs => no CQLF)\n\n', ...
    trace(A1*A2));

%% Part B -- let CVX prove infeasibility of the common quadratic LMI
fprintf('--- Part B: common quadratic V via CVX (expect Infeasible) ---\n');
cvx_begin sdp quiet
    variable P(2,2) symmetric
    P >= eye(2);
    A1'*P + P*A1 <= -1e-6*eye(2);
    A2'*P + P*A2 <= -1e-6*eye(2);
cvx_end
fprintf('cvx_status = %s\n\n', cvx_status);

%% Part C -- degree escalation: homogeneous V of degree 2m, m = 1,2,3,4
% V(x) = sum_{k=0}^{2m} c_{k+1} x1^(2m-k) x2^k    (2m+1 coefficients)
% SOS certificate: V = z'Qz with z = [x1^m; x1^(m-1)x2; ...; x2^m], Q >= 0.
% Vdot along mode i is again homogeneous of degree 2m with coefficients
% Mder(Ai,m)*c -- LINEAR in c. Require -Vdot_i - eps*(x1^2+x2^2)^m to be SOS.
fprintf('--- Part C: degree escalation ---\n');
epsdec = 1e-2;
c = []; m = [];
for mtry = 1:4
    [ok, ctry] = find_homog_lf(A1, A2, mtry, epsdec);
    fprintf('degree %d: %s\n', 2*mtry, tern(ok, 'Solved', 'Infeasible'));
    if ok, m = mtry; c = ctry; break; end
end
fprintf('\nWinning certificate (degree %d), coefficients of x1^(%d-k) x2^k:\n', 2*m, 2*m);
fprintf('c = %s\n\n', mat2str(c.', 5));

%% Part D -- independent verification on the unit circle
% V is homogeneous, so checking on the unit circle checks everywhere.
th = linspace(0, 2*pi, 20001);
X  = [cos(th); sin(th)];
V   = evalform(c, X);
Vd1 = evalform(mder(A1, m)*c, X);
Vd2 = evalform(mder(A2, m)*c, X);
fprintf('--- Part D: grid check on unit circle (20001 points) ---\n');
fprintf('min V      = %.6f   (> 0)\n', min(V));
fprintf('max Vdot|1 = %.6f   (< 0)\n', max(Vd1));
fprintf('max Vdot|2 = %.6f   (< 0)\n', max(Vd2));
fprintf('certified decay: Vdot <= -2*alpha*V with alpha = %.6f\n\n', ...
    -max(max(Vd1, Vd2) ./ (2*V)));

%% Part E -- sanity: worst-case switching really is dangerous
% Both modes rotate counterclockwise (thetadot > 0 everywhere), so the most
% aggressive switching law picks, at every angle, the mode with the largest
% radial growth dr/dtheta. Integrate that around one revolution.
fprintf('--- Part E: worst-case switching, growth of r per revolution ---\n');
nth = 200000; dth = 2*pi/nth; logr = 0;
for k = 0:nth-1
    x = [cos(k*dth); sin(k*dth)];
    drdth = @(A) (x'*(A+A')/2*x) / (x(1)*(A(2,:)*x) - x(2)*(A(1,:)*x));
    logr = logr + max(drdth(A1), drdth(A2))*dth;
end
fprintf('r(2*pi)/r(0) under worst-case switching = %.6f  (< 1: contracts, barely)\n\n', exp(logr));

%% Part F -- difficulty landscape: minimal degree vs a
fprintf('--- Part F: minimal certificate degree as a function of a ---\n');
for atry = [3 5 5.8 6 7 8 9 10 11 12]
    B2 = [-1 -atry; 1/atry -1];
    mindeg = NaN;
    for mtry = 1:5
        if find_homog_lf(A1, B2, mtry, epsdec), mindeg = 2*mtry; break; end
    end
    fprintf('a = %5.1f  ->  min degree = %g\n', atry, mindeg);
end

%% ---------------- local functions ----------------
function [ok, c] = find_homog_lf(A1, A2, m, epsdec)
% Search a homogeneous degree-2m common Lyapunov function via CVX (SOS/SDP).
    n = 2*m + 1;
    w = zeros(n,1);                       % coeffs of (x1^2+x2^2)^m
    for k = 0:m, w(2*k+1) = nchoosek(m,k); end
    M1 = mder(A1, m); M2 = mder(A2, m);
    cvx_begin sdp quiet
        variable c(n)
        variable Q(m+1,m+1)  symmetric    % Gram matrix of V
        variable G1(m+1,m+1) symmetric    % Gram matrix of -Vdot|1 - eps*|x|^2m
        variable G2(m+1,m+1) symmetric    % Gram matrix of -Vdot|2 - eps*|x|^2m
        Q >= eye(m+1); G1 >= 0; G2 >= 0;
        d1 = -M1*c - epsdec*w;
        d2 = -M2*c - epsdec*w;
        for s = 0:2*m                     % match coefficients monomial by monomial
            i = (max(0,s-m):min(m,s)) + 1;  j = s + 2 - i;
            sum(Q (sub2ind(size(Q),  i, j))) == c (s+1);
            sum(G1(sub2ind(size(G1), i, j))) == d1(s+1);
            sum(G2(sub2ind(size(G2), i, j))) == d2(s+1);
        end
    cvx_end
    ok = strcmp(cvx_status, 'Solved');
end

function M = mder(A, m)
% Linear map: coefficients of V (degree 2m)  ->  coefficients of Vdot.
% Row j+1 gives the coefficient of x1^(2m-j) x2^j in grad(V)' * A * x.
    n = 2*m + 1; M = zeros(n);
    for j = 0:2*m
        r = j + 1;
        if j >= 1,   M(r, j)   = (2*m+1-j)*A(1,2);            end
        M(r, j+1) = (2*m-j)*A(1,1) + j*A(2,2);
        if j+2 <= n, M(r, j+2) = (j+1)*A(2,1);                end
    end
end

function v = evalform(c, X)
% Evaluate the binary form with coefficients c at columns of X.
    d = numel(c) - 1; v = zeros(1, size(X,2));
    for k = 0:d
        v = v + c(k+1) * X(1,:).^(d-k) .* X(2,:).^k;
    end
end

function s = tern(cond, sy, sn)
    if cond, s = sy; else, s = sn; end
end
