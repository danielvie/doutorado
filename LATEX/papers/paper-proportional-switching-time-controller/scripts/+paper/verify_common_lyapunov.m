function certificate = verify_common_lyapunov(A0, A1, P)
%VERIFY_COMMON_LYAPUNOV Check a fixed common-P certificate without an SDP solver.
% Endpoint decrease implies decrease on the entire matrix segment analytically.
assert(ismatrix(A0) && size(A0, 1) == size(A0, 2), 'A0 must be square.');
assert(isequal(size(A0), size(A1), size(P)), 'Certificate dimensions differ.');
assert(all(isfinite([A0(:); A1(:); P(:)])), 'Non-finite certificate input.');
assert(norm(P - P', 'fro') < 1e-10, 'P must be symmetric.');
P = (P + P') / 2;
eigP = eig(P);
assert(min(eigP) > 1e-7, 'P fails the positive-definiteness floor.');
assert(abs(trace(P) - size(P, 1)) < 1e-6, 'P fails trace normalization.');
Q0 = P - A0' * P * A0;
Q1 = P - A1' * P * A1;
eigQ0 = eig((Q0 + Q0') / 2);
eigQ1 = eig((Q1 + Q1') / 2);
q = min([eigQ0; eigQ1]);
assert(q > 1e-9, 'An endpoint fails strict Lyapunov decrease.');
certificate = struct('A0', A0, 'A1', A1, 'P', P, ...
    'eigP', eigP, 'eigQ0', eigQ0, 'eigQ1', eigQ1, 'q', q, ...
    'rho_bound', sqrt(max(0, 1 - q / max(eigP))));
end
