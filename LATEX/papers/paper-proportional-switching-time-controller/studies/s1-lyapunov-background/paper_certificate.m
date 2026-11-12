function results = paper_certificate()
%PAPER_CERTIFICATE  Rebuild the common-Lyapunov certificate of the paper.
%
%   Companion script for lyapunov-convex-optimization.html, Chapter 2.
%
%   Reads the generated linearization and controller data, rebuilds the two
%   endpoint matrices of the conditioned family
%
%       A(beta) = (1 - beta) * Phi + beta * A_cl,   beta in [0, 1],
%
%   re-solves the semidefinite program for a common P, verifies the resulting
%   contraction bound along the whole segment, and contrasts the segment with
%   the polytope that per-component clipping would have produced.
%
%   Run from the repository root, or adjust results_path below.

results_path = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
    'results', 'paper_results.mat');
loaded = load(results_path);
data = loaded.results;

Phi_physical   = data.linearization.Phi;
Gamma_physical = data.linearization.Gamma;
state_scale    = data.controller.state_scale;
timing_scale   = data.controller.timing_scale;
K              = data.controller.K_aggressive_normalized;

% Normalized coordinates z = Sx \ e and v = dtau / ts.
Phi   = state_scale \ Phi_physical * state_scale;
Gamma = state_scale \ Gamma_physical * timing_scale;
A_cl  = Phi - Gamma * K;

section('1. The two endpoints of the conditioned family');
fprintf('state dimension n = %d, offsets m = %d\n', size(Phi, 1), size(Gamma, 2));
fprintf('rho(Phi)   = %.6f   ||Phi||_2   = %.6f\n', ...
    max(abs(eig(Phi))), norm(Phi));
fprintf('rho(A_cl)  = %.6f   ||A_cl||_2  = %.6f\n', ...
    max(abs(eig(A_cl))), norm(A_cl));
fprintf('P = I certifies Phi?  max eig(Phi''*Phi - I)  = %+.6f\n', ...
    max(eig(Phi' * Phi - eye(size(Phi, 1)))));
fprintf('P = I certifies A_cl? max eig(A_cl''*A_cl - I) = %+.6f\n', ...
    max(eig(A_cl' * A_cl - eye(size(Phi, 1)))));

section('2. The semidefinite program for a common P');
[P, decrease] = common_lyapunov({Phi, A_cl});
fprintf('P =\n'); disp(P);
fprintf('eig(P)          %s\n', mat2str(eig(P)', 6));
fprintf('cond(P)         %.4f\n', cond(P));
fprintf('decrease margin %.6e\n', decrease);
fprintf('matches stored P to %.3e\n', ...
    norm(P - data.common_lyapunov_certificate.P, 'fro'));

section('3. Endpoint contraction and the segment bound');
q0 = p_norm(Phi, P);
q1 = p_norm(A_cl, P);
fprintf('||Phi||_P  = q0 = %.6f\n', q0);
fprintf('||A_cl||_P = q1 = %.6f\n', q1);
fprintf('q = max(q0, q1) = %.6f   -> every A(beta) contracts by at most q\n', ...
    max(q0, q1));

betas = linspace(0, 1, 201);
segment = zeros(size(betas));
for k = 1:numel(betas)
    A_beta = (1 - betas(k)) * Phi + betas(k) * A_cl;
    segment(k) = p_norm(A_beta, P);
end
fprintf('sampled max over beta in [0,1]: %.6f (bound %.6f)\n', ...
    max(segment), max(q0, q1));
fprintf('spectral radius at beta = 0: %.6f, at beta = 1: %.6f\n', ...
    max(abs(eig(Phi))), max(abs(eig(A_cl))));

section('4. The uniform scaling is what makes it a segment');
% Uniform scaling:      dtau_app = beta * dtau_raw       -> a line segment.
% Per-component clipping: dtau_app = Lambda * dtau_raw   -> a polytope with
% 2^m vertices, because each component may be scaled independently.
offsets = size(Gamma, 2);
vertex_count = 2 ^ offsets;
vertices = cell(1, vertex_count);
for v = 0:(vertex_count - 1)
    lambda = double(bitget(v, 1:offsets))';
    vertices{v + 1} = Phi - Gamma * diag(lambda) * K;
end
unstable = 0;
worst = 0;
for v = 1:vertex_count
    radius = max(abs(eig(vertices{v})));
    worst = max(worst, radius);
    unstable = unstable + (radius >= 1);
end
fprintf('per-component clipping gives %d vertices\n', vertex_count);
fprintf('worst vertex spectral radius: %.6f, unstable vertices: %d\n', ...
    worst, unstable);
fprintf('common P over all %d vertices feasible: %d\n', vertex_count, ...
    is_feasible(vertices));

section('5. The realized conditioning sequence');
response = readtable(fullfile(fileparts(results_path), ...
    'conditioned_control_response.csv'));
beta_k = response.beta;
fprintf('cycles with beta < 1: %d of %d\n', sum(beta_k < 1 - 1e-12), numel(beta_k));
fprintf('minimum beta: %.6f\n', min(beta_k));
fprintf('first five beta values: %s\n', mat2str(beta_k(1:5)', 6));

results = struct('Phi', Phi, 'A_cl', A_cl, 'P', P, 'q0', q0, 'q1', q1, ...
    'betas', betas, 'segment', segment, 'beta_k', beta_k, ...
    'conditioned_error', response.conditioned_error, ...
    'open_loop_error', response.open_loop_error, ...
    'conservative_error', response.conservative_error);
end

% -------------------------------------------------------------------------

function [P, decrease] = common_lyapunov(A)
n = size(A{1}, 1);
P_var = sdpvar(n, n, 'symmetric');
t = sdpvar(1);
constraints = [P_var >= 1e-8 * eye(n), trace(P_var) == 1, t >= 0];
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
end

function ok = is_feasible(A)
n = size(A{1}, 1);
P_var = sdpvar(n, n, 'symmetric');
constraints = [P_var >= 1e-6 * eye(n), trace(P_var) == 1];
for i = 1:numel(A)
    constraints = [constraints, ...
        A{i}' * P_var * A{i} - P_var <= -1e-9 * eye(n)];  %#ok<AGROW>
end
diagnostics = optimize(constraints, [], ...
    sdpsettings('solver', 'sedumi', 'verbose', 0));
ok = (diagnostics.problem == 0);
end

function value_out = p_norm(A, P)
value_out = sqrt(max(real(eig(A' * P * A, P))));
end

function section(title_text)
fprintf('\n%s\n%s\n', title_text, repmat('-', 1, numel(title_text)));
end
