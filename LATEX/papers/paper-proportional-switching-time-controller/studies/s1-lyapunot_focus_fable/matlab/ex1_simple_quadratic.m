%% EX1 -- Simple example: quadratic Lyapunov function for a stable LTI system
%
%   xdot = A x,   A = [0 1; -2 -3]   (eigenvalues -1 and -2)
%
% Part A: the CLASSICAL route -- solve the Lyapunov EQUATION by hand / lyap()
% Part B: the CONVEX OPTIMIZATION route -- solve the Lyapunov INEQUALITY with CVX
% Part C: push further with CVX -- certify a decay rate alpha (bisection)
%
% Requires: CVX (http://cvxr.com), Control System Toolbox (for lyap)

clear; clc;
A = [0 1; -2 -3];

fprintf('=== EX1: xdot = A x with A = [0 1; -2 -3] ===\n');
fprintf('eig(A) = %s\n\n', mat2str(eig(A).', 4));

%% Part A -- classical: solve A'P + PA = -Q (an EQUATION) with Q = I
% By hand (see tutor document) the unique solution is P = [5/4 1/4; 1/4 1/4].
P_hand = lyap(A', eye(2));       % lyap(A',Q) solves A'P + P A = -Q
fprintf('--- Part A: Lyapunov EQUATION  A''P + PA = -I ---\n');
disp(P_hand);
fprintf('eig(P_hand)              = %s   (both > 0  ->  P > 0)\n', ...
    mat2str(eig(P_hand).', 4));
fprintf('eig(A''P + PA)            = %s   (= -I by construction)\n\n', ...
    mat2str(eig(A'*P_hand + P_hand*A).', 4));

%% Part B -- convex optimization: solve the Lyapunov INEQUALITY (an LMI)
%   find P  s.t.  P >= I  and  A'P + PA <= -I
% (">= I" instead of "> 0" makes strictness numerically meaningful;
%  any positive multiple of a solution is also a solution.)
fprintf('--- Part B: Lyapunov INEQUALITY via CVX (SDP feasibility) ---\n');
cvx_begin sdp quiet
    variable P(2,2) symmetric
    minimize( trace(P) )          % any objective; feasibility is the point
    P >= eye(2);
    A'*P + P*A <= -eye(2);
cvx_end
fprintf('cvx_status = %s\n', cvx_status);
disp(P);
fprintf('eig(P)                   = %s\n', mat2str(eig(P).', 4));
fprintf('eig(A''P + PA)            = %s   (all <= -1  ->  strict decrease)\n\n', ...
    mat2str(eig(A'*P + P*A).', 4));

%% Part C -- decay-rate certificate: largest alpha with A'P + PA <= -2*alpha*P
% For fixed alpha this is an LMI in P; sweep alpha by bisection.
fprintf('--- Part C: decay rate  Vdot <= -2*alpha*V  (bisection over alpha) ---\n');
lo = 0; hi = 5; P_best = [];
for it = 1:40
    alpha = (lo + hi)/2;
    cvx_begin sdp quiet
        variable P(2,2) symmetric
        P >= eye(2);
        A'*P + P*A <= -2*alpha*P;
    cvx_end
    if strcmp(cvx_status, 'Solved')
        lo = alpha; P_best = P;
    else
        hi = alpha;
    end
end
alpha = lo;
fprintf('certified alpha  = %.6f   (theory: min |Re eig(A)| = 1)\n', alpha);
disp(P_best);
kappa = sqrt(max(eig(P_best))/min(eig(P_best)));
fprintf('norm bound: ||x(t)|| <= %.4f * exp(-%.4f t) * ||x(0)||\n', kappa, alpha);
