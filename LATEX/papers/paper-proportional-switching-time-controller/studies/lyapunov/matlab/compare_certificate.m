function comparison = compare_certificate()
%COMPARE_CERTIFICATE Compare the Python SDP with MATLAB.
%
% Rebuilds the converter model and aggressive LQR gain from physical data,
% solves the same trace-normalized common-Lyapunov SDP with CVX/SDPT3, and
% compares the result with this study's results/certificate.json.
%
% From the paper root: task lyapunov:matlab

study_root = fileparts(fileparts(mfilename('fullpath')));
python_path = fullfile(study_root, 'results', 'certificate.json');
assert(isfile(python_path), ...
    'Missing %s. Run task lyapunov:python first.', python_path);
assert(exist('cvx_begin', 'file') == 2, ...
    'CVX is not on the MATLAB path. Run cvx_setup first.');

[A0, B, K, Kphysical, A1, Phi, Gtau, closure] = rebuild_model();
n = size(A0, 1);

cvx_begin sdp quiet
    cvx_solver sdpt3
    cvx_precision best
    variable Pvar(n, n) symmetric
    variable eta
    maximize(eta)
    subject to
        trace(Pvar) == 3                                            %#ok<NOPRT,VUNUS>
        Pvar - 1e-7 * eye(n) == semidefinite(n)                     %#ok<NOPRT,VUNUS>
        Pvar - A0' * Pvar * A0 - eta * eye(n) == semidefinite(n)    %#ok<NOPRT,VUNUS>
        Pvar - A1' * Pvar * A1 - eta * eye(n) == semidefinite(n)    %#ok<NOPRT,VUNUS>
cvx_end

assert(contains(cvx_status, 'Solved'), ...
    'CVX did not return a certificate. Status: %s', cvx_status);

P = (Pvar + Pvar') / 2;
Q0 = symmetric_part(P - A0' * P * A0);
Q1 = symmetric_part(P - A1' * P * A1);
eigP = sort(real(eig(P)));
eigQ0 = sort(real(eig(Q0)));
eigQ1 = sort(real(eig(Q1)));
q = min([eigQ0(1), eigQ1(1)]);
rho_bound = sqrt(1 - q / eigP(end));

assert(eigP(1) > 0, 'The MATLAB P is not positive definite.');
assert(q > 1e-9, 'The MATLAB certificate does not give strict endpoint decrease.');
assert(abs(trace(P) - 3) < 1e-6, 'The MATLAB P violates trace(P) = 3.');
assert(closure < 1e-10, 'The reconstructed nominal orbit does not close.');

python = jsondecode(fileread(python_path));
model = struct( ...
    'Phi_relative_error', relative_error(Phi, python.Phi), ...
    'Gtau_relative_error', relative_error(Gtau, python.Gtau), ...
    'Kphysical_relative_error', relative_error(Kphysical, python.Kphysical), ...
    'A0_relative_error', relative_error(A0, python.A0), ...
    'B_relative_error', relative_error(B, python.B), ...
    'A1_relative_error', relative_error(A1, python.A1), ...
    'closure', closure);
optimization = struct( ...
    'P_relative_error', relative_error(P, python.P), ...
    'eta_absolute_error', abs(eta - python.eta), ...
    'eta_relative_error', relative_error(eta, python.eta), ...
    'q_absolute_error', abs(q - python.q), ...
    'q_relative_error', relative_error(q, python.q), ...
    'rho_bound_absolute_error', abs(rho_bound - python.rho_bound));

assert(max([model.Phi_relative_error, model.Gtau_relative_error, ...
    model.Kphysical_relative_error, model.A0_relative_error, ...
    model.B_relative_error, model.A1_relative_error]) < 1e-7, ...
    'MATLAB and Python did not reconstruct the same model and controller.');
assert(optimization.eta_relative_error < 1e-3, ...
    'The MATLAB and Python SDP objective values differ by more than 0.1%%.');

matlab_result = struct( ...
    'solver', struct('interface', 'CVX', 'solver', 'SDPT3', 'status', cvx_status), ...
    'P', P, 'eigP', eigP, 'eigQs', [eigQ0'; eigQ1'], ...
    'eta', eta, 'q', q, 'rho_bound', rho_bound, ...
    'K', K, 'Kphysical', Kphysical, 'A0', A0, 'B', B, 'A1', A1);
comparison = struct('matlab', matlab_result, 'python', struct( ...
    'solver', python.solver, 'P', python.P, 'eigP', python.eigP, ...
    'eigQs', python.eigQs, 'eta', python.eta, 'q', python.q, ...
    'rho_bound', python.rho_bound), 'model_errors', model, ...
    'optimization_errors', optimization);

print_comparison(comparison);
output_path = fullfile(study_root, 'results', ...
    'lyapunov_analysis_matlab_comparison.json');
file = fopen(output_path, 'w');
assert(file ~= -1, 'Could not write %s', output_path);
cleanup = onCleanup(@() fclose(file));
fprintf(file, '%s\n', jsonencode(comparison, PrettyPrint=true));
end

function [A0, B, K, Kphysical, A1, Phi, Gtau, closure] = rebuild_model()
E = 30;
C1 = 40e-6;
C2 = 40e-6;
L = 10e-3;
R = 10;
modes = [0, 1, 3, 7, 2, 0, 4, 7, 4];
boundaries = [0, 63.889183506119, 87.556782881998, 109.556782881998, ...
    132.538059851499, 154.538059851499, 218.210068109424, ...
    240.380157440049, 263.827584831201, 286] * 1e-6;
dwell = diff(boundaries);
xstar = [9.9247; 19.2928; 0.9823];

intervals = numel(modes);
F = cell(1, intervals);
phis = cell(1, intervals);
X = zeros(4, intervals + 1);
X(:, 1) = [xstar; 1];
product = eye(4);
for i = 1:intervals
    bits = bitget(modes(i), [3, 2, 1]);
    u1 = bits(1);
    u2 = bits(2);
    u3 = bits(3);
    A = [0, 0, (u2 - u1) / C1; ...
         0, 0, (u3 - u2) / C2; ...
         (u1 - u2) / L, (u2 - u3) / L, -R / L];
    b = [0; 0; E * u3 / L];
    F{i} = [A, b; zeros(1, 4)];
    phis{i} = expm(F{i} * dwell(i));
    X(:, i + 1) = phis{i} * X(:, i);
    product = phis{i} * product;
end

Gaug = zeros(4, intervals);
downstream = eye(4);
for i = intervals:-1:1
    Gaug(:, i) = downstream * F{i} * X(:, i + 1);
    downstream = downstream * phis{i};
end

Pi = [eye(3), zeros(3, 1)];
D = zeros(intervals, intervals - 1);
for i = 1:(intervals - 1)
    D(i, i) = 1;
    D(i + 1, i) = -1;
end
Phi = Pi * product * Pi';
Gtau = Pi * Gaug * D;

S = diag([10, 20, 1]);
ts = 10e-6;
A0 = S \ (Phi * S);
B = (S \ Gtau) * ts;
K = dlqr(A0, B, eye(3), 0.001 * eye(8));
Kphysical = ts * K / S;
A1 = A0 - B * K;
closure = norm(X(1:3, end) - xstar, Inf);
end

function value = relative_error(actual, reference)
value = norm(actual - reference, 'fro') / norm(reference, 'fro');
end

function A = symmetric_part(A)
A = (A + A') / 2;
end

function print_comparison(comparison)
matlab_result = comparison.matlab;
python = comparison.python;
model = comparison.model_errors;
optimization = comparison.optimization_errors;

fprintf('\nCommon-P optimization comparison\n');
fprintf('--------------------------------\n');
fprintf('Python solver : %s / %s (%s)\n', python.solver.interface, ...
    python.solver.solver, python.solver.status);
fprintf('MATLAB solver : %s / %s (%s)\n\n', matlab_result.solver.interface, ...
    matlab_result.solver.solver, matlab_result.solver.status);
fprintf('%-24s %16s %16s %14s\n', 'Quantity', 'Python', 'MATLAB', 'relative error');
fprintf('%-24s %16.9e %16.9e %14.3e\n', 'eta', python.eta, ...
    matlab_result.eta, optimization.eta_relative_error);
fprintf('%-24s %16.9e %16.9e %14.3e\n', 'verified q', python.q, ...
    matlab_result.q, optimization.q_relative_error);
fprintf('%-24s %16.9f %16.9f %14s\n', 'rho bound', python.rho_bound, ...
    matlab_result.rho_bound, '-');
fprintf('%-24s %16s %16s %14.3e\n', 'P', '-', '-', ...
    optimization.P_relative_error);

fprintf('\nReconstruction relative errors\n');
fprintf('Phi       %.3e\n', model.Phi_relative_error);
fprintf('Gtau       %.3e\n', model.Gtau_relative_error);
fprintf('Kphysical  %.3e\n', model.Kphysical_relative_error);
fprintf('A0         %.3e\n', model.A0_relative_error);
fprintf('B          %.3e\n', model.B_relative_error);
fprintf('A1         %.3e\n', model.A1_relative_error);
fprintf('closure    %.3e\n', model.closure);

fprintf('\nMATLAB P =\n');
disp(matlab_result.P);
fprintf('Python P =\n');
disp(python.P);
end
