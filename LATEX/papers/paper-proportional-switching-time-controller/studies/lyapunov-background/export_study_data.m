function export_study_data()
%EXPORT_STUDY_DATA  Write the data embedded in lyapunov-convex-optimization.html.
%
%   The document draws every figure in the browser, so this file only has to
%   export matrices, scalars, and short sequences.  Anything the browser can
%   recompute from those (level sets, trajectories, contraction curves) is left
%   out on purpose, to keep the page small enough to stay self-contained.
%
%   Writes study_data.json next to this file.  Run it after generate_results.m.

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
out = struct();

%% ---- Chapter 1: the generic switched system -------------------------------
A = {[ 1.3  0.6; -1.0 -0.3], ...
     [-0.1  0.8; -0.3 -1.1]};
[P, decrease] = common_lyapunov(A, 2);

P1 = dlyap(A{1}', eye(2));
P2 = dlyap(A{2}', eye(2));

out.generic = struct( ...
    'A1', A{1}, 'A2', A{2}, 'P', P, 'decrease', decrease, ...
    'P_mode1', P1, 'P_mode2', P2, ...
    'eigA1', sort(eig(A{1}))', 'eigA2', sort(eig(A{2}))', ...
    'rho', [max(abs(eig(A{1}))), max(abs(eig(A{2})))], ...
    'norm2', [norm(A{1}), norm(A{2})], ...
    'identity_gap', [max(eig(A{1}'*A{1} - eye(2))), ...
                     max(eig(A{2}'*A{2} - eye(2)))], ...
    'cross_gap', [max(eig(A{2}'*P1*A{2} - P1)), ...
                  max(eig(A{1}'*P2*A{1} - P2))], ...
    'q', [p_norm(A{1}, P), p_norm(A{2}, P)], ...
    'condP', cond(P), 'eigP', eig(P)', ...
    'diagonal_feasible', diagonal_feasible(A));

%% ---- The pair with no common quadratic ------------------------------------
B = {[0.75 1.6; 0 0.75], [0.75 0; -1.6 0.75]};
out.counter = struct('B1', B{1}, 'B2', B{2}, ...
    'rho', [max(abs(eig(B{1}))), max(abs(eig(B{2})))], ...
    'rho_product', max(abs(eig(B{1} * B{2}))), ...
    'feasible', quiet_feasible(B));

%% ---- Chapter 2: the paper -------------------------------------------------
loaded = load(fullfile(root, 'results', 'paper_results.mat'));
data = loaded.results;
Sx = data.controller.state_scale;
ts = data.controller.timing_scale;
Phi   = Sx \ data.linearization.Phi * Sx;
Gamma = Sx \ data.linearization.Gamma * ts;
K     = data.controller.K_aggressive_normalized;
A_cl  = Phi - Gamma * K;
Pp    = data.common_lyapunov_certificate.P;

out.paper = struct('Phi', Phi, 'Gamma', Gamma, 'K', K, 'A_cl', A_cl, 'P', Pp, ...
    'condP', cond(Pp), 'eigP', eig(Pp)', ...
    'q0', p_norm(Phi, Pp), 'q1', p_norm(A_cl, Pp), ...
    'decrease', min(eig((Pp - Phi'*Pp*Phi + (Pp - Phi'*Pp*Phi)')/2)), ...
    'rho', [max(abs(eig(Phi))), max(abs(eig(A_cl)))], ...
    'identity_gap', [max(eig(Phi'*Phi - eye(3))), ...
                     max(eig(A_cl'*A_cl - eye(3)))], ...
    'state_scale', diag(Sx)', 'timing_scale', ts);

%% ---- Uniform scaling versus per-component clipping ------------------------
m = size(Gamma, 2);
vertices = cell(1, 2^m);
radii = zeros(1, 2^m);
for v = 0:(2^m - 1)
    lambda = double(bitget(v, 1:m))';
    vertices{v+1} = Phi - Gamma * diag(lambda) * K;
    radii(v+1) = max(abs(eig(vertices{v+1})));
end
out.polytope = struct('vertex_count', 2^m, ...
    'max_radius', max(radii), ...
    'unstable_vertices', sum(radii >= 1), ...
    'radii_sorted', sort(radii, 'descend'), ...
    'feasible', quiet_feasible(vertices));

%% ---- The realized run -----------------------------------------------------
resp = readtable(fullfile(root, 'results', 'conditioned_control_response.csv'));
anchor = data.schedule.orbit_anchor(:);
z_cond = Sx \ ([resp.conditioned_vc1_v, resp.conditioned_vc2_v, resp.conditioned_il_a]' - anchor);
z_open = Sx \ ([resp.open_vc1_v, resp.open_vc2_v, resp.open_il_a]' - anchor);

raw_offset_columns = arrayfun(@(i) sprintf('raw_offset_%d_us', i), 1:m, ...
    'UniformOutput', false);
out.response = struct( ...
    'cycle', resp.cycle', 'beta', resp.beta', ...
    'conditioned_error', resp.conditioned_error', ...
    'conservative_error', resp.conservative_error', ...
    'open_loop_error', resp.open_loop_error', ...
    'conditioned_pnorm', sqrt(sum(z_cond .* (Pp * z_cond), 1)), ...
    'open_pnorm', sqrt(sum(z_open .* (Pp * z_open), 1)), ...
    'raw_offsets_cycle0', table2array(resp(1, raw_offset_columns)));

% The reconciled cycle boundaries, at full precision. The manuscript prints
% them rounded to three decimals; the conditioner is scanned against these, so
% that beta* here matches the value the simulation reports.
out.schedule = struct( ...
    'boundaries_us', data.schedule.Ts(:)' * 1e6, ...
    'modes', data.schedule.published_modes(:)', ...
    'applied_dwell_bound_us', 3, ...
    'benchmark_dwell_bound_us', 22, ...
    'anchor', anchor');

json = jsonencode(out);
fid = fopen(fullfile(here, 'study_data.json'), 'w');
fwrite(fid, json);
fclose(fid);
fprintf('wrote study_data.json (%.1f kB)\n', numel(json) / 1024);
fprintf('generic: q = %.6f, diagonal P feasible = %d\n', ...
    max(out.generic.q), out.generic.diagonal_feasible);
fprintf('paper:   q0 = %.6f, q1 = %.6f\n', out.paper.q0, out.paper.q1);
fprintf('polytope: %d vertices, %d unstable, max rho = %.6f, common P = %d\n', ...
    out.polytope.vertex_count, out.polytope.unstable_vertices, ...
    out.polytope.max_radius, out.polytope.feasible);
end

% -------------------------------------------------------------------------

function [P, decrease] = common_lyapunov(A, trace_target)
n = size(A{1}, 1);
P_var = sdpvar(n, n, 'symmetric');
t = sdpvar(1);
constraints = [P_var >= 1e-8 * eye(n), trace(P_var) == trace_target, t >= 0];
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

function ok = diagonal_feasible(A)
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

function ok = quiet_feasible(A)
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
