function result = cvx_paper()
%CVX_PAPER  Solve the paper's common quadratic Lyapunov SDP with CVX.
%
%   The paper case is generated with Simulation(Enums.SimName.PATINO_2).
%   This function reads results/paper_results.mat, reconstructs the
%   normalized nominal and aggressive closed-loop cycle matrices, and solves
%
%       maximize    t
%       subject to  P >= 1e-8 I, trace(P) = 1, t >= 0,
%                   Phi' P Phi - P <= -t I,
%                   Acl' P Acl - P <= -t I.
%
%   The common P certifies the complete conditioned family
%       A(beta) = (1 - beta) Phi + beta Acl,  beta in [0, 1].
%
%   Requires CVX and a generated results/paper_results.mat file.  Generate
%   the latter with scripts/generate_results.m before calling this function.

here = fileparts(mfilename('fullpath'));
article_root = fileparts(fileparts(here));
results_path = fullfile(article_root, 'results', 'paper_results.mat');
assert(isfile(results_path), ...
    'Missing %s. Run scripts/generate_results.m first.', results_path);
assert(exist('cvx_begin', 'file') == 2, ...
    'CVX is not on the MATLAB path. Run cvx_setup first.');

loaded = load(results_path);
data = loaded.results;

% Work in the normalized coordinates used by the paper controller:
% z = state_scale \ e and v = delta_t / timing_scale.
state_scale = data.controller.state_scale;
timing_scale = data.controller.timing_scale;
Phi_physical = data.linearization.Phi;
Gamma_physical = data.linearization.Gamma;
K = data.controller.K_aggressive_normalized;

Phi = state_scale \ Phi_physical * state_scale;
Gamma = state_scale \ Gamma_physical * timing_scale;
Acl = Phi - Gamma * K;
n = size(Phi, 1);
assert(isequal(size(Phi), [n, n]) && isequal(size(Acl), [n, n]), ...
    'The paper endpoint matrices must be square and have the same size.');

% Common-P SDP. The trace constraint fixes the otherwise arbitrary scale of P.
eps_positive = 1e-8;
cvx_begin sdp quiet
    variable P(n, n) symmetric
    variable t
    maximize(t)
    subject to
        P - eps_positive * eye(n) == semidefinite(n)
        t >= 0
        trace(P) == 1
        P - Phi' * P * Phi - t * eye(n) == semidefinite(n)
        P - Acl' * P * Acl - t * eye(n) == semidefinite(n)
cvx_end

assert(~isempty(strfind(cvx_status, 'Solved')), ...
    'CVX did not solve the paper certificate. Status: %s', cvx_status);

% Re-check the returned certificate without relying on CVX's status alone.
P = (P + P') / 2;
phi_decrease = (P - Phi' * P * Phi);
acl_decrease = (P - Acl' * P * Acl);
phi_decrease = (phi_decrease + phi_decrease') / 2;
acl_decrease = (acl_decrease + acl_decrease') / 2;
phi_margin = min(eig(phi_decrease));
acl_margin = min(eig(acl_decrease));
q_phi = sqrt(max(real(eig(Phi' * P * Phi, P))));
q_acl = sqrt(max(real(eig(Acl' * P * Acl, P))));
q = max(q_phi, q_acl);

assert(min(eig(P)) > 0, 'The CVX matrix P is not positive definite.');
assert(phi_margin > 0 && acl_margin > 0, ...
    'The CVX certificate does not have strict decrease at both endpoints.');
assert(q < 1, 'The computed common-P contraction bound is not strict.');

fprintf('PATINO_2 paper common-P certificate via CVX\n');
fprintf('CVX status       : %s\n', cvx_status);
fprintf('optimal decrease: %.9e\n', t);
fprintf('P =\n');
disp(P);
fprintf('eig(P)           : %s\n', mat2str(eig(P)', 8));
fprintf('Phi margin       : %.9e\n', phi_margin);
fprintf('Acl margin       : %.9e\n', acl_margin);
fprintf('||Phi||_P        : %.9f\n', q_phi);
fprintf('||Acl||_P        : %.9f\n', q_acl);
fprintf('segment bound    : %.9f\n', q);

result = struct('status', cvx_status, 'optimal_value', cvx_optval, ...
    'Phi', Phi, 'Acl', Acl, 'P', P, 'decrease', t, ...
    'phi_margin', phi_margin, 'acl_margin', acl_margin, ...
    'q_phi', q_phi, 'q_acl', q_acl, 'q', q);
end
