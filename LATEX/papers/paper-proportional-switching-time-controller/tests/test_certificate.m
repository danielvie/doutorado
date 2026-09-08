function tests = test_certificate
% Fast checks for the adopted common-P certificate and physical trajectory sampler.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.original_path = path;
addpath(fullfile(root, 'scripts'));
paths = paper.paths(); addpath(paths.simulation);
b = paper.benchmark(); m = paper.validate_model(b);
testCase.TestData.b = b;
testCase.TestData.m = m;
testCase.TestData.c = paper.design_feedback(b, m);
testCase.TestData.certificate = jsondecode(fileread(fullfile(root, ...
    'studies', 'lyapunov', 'results', 'lyapunov_analysis_julia_certificate.json')));
end

function teardownOnce(testCase)
path(testCase.TestData.original_path);
end

function testCertificateAndSchurComplement(testCase)
b = testCase.TestData.b; m = testCase.TestData.m; c = testCase.TestData.c;
P = testCase.TestData.certificate.P;
A0 = b.state_scale \ m.Phi * b.state_scale;
A1 = A0 - (b.state_scale \ m.Gamma * b.timing_scale) * c.K_aggressive_normalized;
certificate = paper.verify_common_lyapunov(A0, A1, P);
verifyGreaterThan(testCase, certificate.q, 2.9e-4);
verifyLessThan(testCase, certificate.rho_bound, 1);
Q0 = P - A0' * P * A0; Q1 = P - A1' * P * A1;
n = size(P, 1); Id = eye(n); eta = certificate.q;
S0 = [P - eta*Id, A0'*P; P*A0, P];
S1 = [P - eta*Id, A1'*P; P*A1, P];
% Regress the Schur-complement proof and an independent expansion identity.
% These samples check implementation, not the theorem's continuous interval.
for beta = [0, 1e-12, 0.2, 0.5, 0.9, 1]
    A = (1 - beta) * A0 + beta * A1;
    Q = P - A' * P * A;
    S = [P - eta*Id, A'*P; P*A, P];
    verifyEqual(testCase, S, (1 - beta)*S0 + beta*S1, 'AbsTol', 1e-14);
    verifyGreaterThanOrEqual(testCase, min(eig((S + S')/2)), -1e-13);
    schur = S(1:n, 1:n) - S(1:n, n+1:end) * (P \ S(n+1:end, 1:n));
    verifyEqual(testCase, schur, Q - eta*Id, 'AbsTol', 1e-14);
    T = [Id, zeros(n); -A, Id];
    verifyEqual(testCase, T'*S*T, blkdiag(Q - eta*Id, P), 'AbsTol', 1e-14);
    rhs = (1 - beta) * Q0 + beta * Q1 + ...
        beta * (1 - beta) * (A1 - A0)' * P * (A1 - A0);
    verifyEqual(testCase, Q, rhs, 'AbsTol', 1e-14);
    verifyGreaterThanOrEqual(testCase, min(eig((Q + Q')/2)), certificate.q - 1e-14);
end
z = [1; -0.5; 0.25];
for k = 1:100
    % State-dependent factors deliberately unrelated to the physical conditioner.
    beta = 1 / (1 + norm(z));
    next = ((1 - beta) * A0 + beta * A1) * z;
    verifyLessThanOrEqual(testCase, next' * P * next, ...
        z' * P * z - certificate.q * norm(z)^2 + 1e-14);
    z = next;
end
end

function testInvalidCertificatesRejected(testCase)
verifyError(testCase, @() paper.verify_common_lyapunov(0.5*eye(3), ...
    0.8*eye(3), -eye(3)), '');
verifyError(testCase, @() paper.verify_common_lyapunov(0.5*eye(3), ...
    1.1*eye(3), eye(3)), '');
verifyError(testCase, @() paper.verify_common_lyapunov(eye(3), ...
    0.5*eye(3), eye(3)), '');
verifyError(testCase, @() paper.verify_common_lyapunov(0.5*eye(3), ...
    0.8*eye(3), 2*eye(3)), '');
end

function testPublicationExportAndStaleModelRejection(testCase)
output = tempname; mkdir(output);
cleanup = onCleanup(@() rmdir(output, 's'));
paths = paper.paths(output); mkdir(paths.results); mkdir(fullfile(output, 'latex'));
b = testCase.TestData.b; m = testCase.TestData.m; c = testCase.TestData.c;
certificate = paper.export_lyapunov(paths, b, m, c);
verifyGreaterThan(testCase, certificate.q, 0);
verifyTrue(testCase, isfile(fullfile(paths.results, 'lyapunov_certificate.json')));
verifyTrue(testCase, isfile(fullfile(output, 'latex', 'lyapunov_metrics.tex')));
m.Phi = m.Phi + 0.01*eye(3);
verifyError(testCase, @() paper.export_lyapunov(paths, b, m, c), '');
end

function testDenseTrajectoryMatchesEveryBoundary(testCase)
b = testCase.TestData.b; c = testCase.TestData.c;
raw = -c.K_aggressive_physical * (b.initial_state - b.orbit_anchor);
[offsets, beta] = condition_dwell_times(b.config.Ts, raw, b.applied_schedule_dwell_bound);
verifyLessThan(testCase, beta, 1);
[time, state] = paper.sample_cycle(b.config, b.initial_state, offsets, 30);
boundaries = paper.cycle_boundaries(b.config, b.initial_state, offsets);
verifyEqual(testCase, state(1:30:end, :)', boundaries, 'AbsTol', 1e-12);
verifyEqual(testCase, time([1, end]), [0; b.period], 'AbsTol', 1e-15);
verifyGreaterThan(testCase, min(diff(time)), 0);
[~, nominal] = paper.sample_cycle(b.config, b.orbit_anchor, zeros(8, 1), 30);
verifyEqual(testCase, nominal(end, :)', b.orbit_anchor, 'AbsTol', 1e-10);
verifyError(testCase, @() paper.sample_cycle(b.config, b.initial_state, raw, 30), '');
end
