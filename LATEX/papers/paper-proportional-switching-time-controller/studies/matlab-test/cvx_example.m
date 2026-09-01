% CVX example: solve a constrained, regularized least-squares problem.
%
%   minimize    ||A*x - b||_2^2 + lambda*||D*x||_2^2
%   subject to  sum(x) = 3
%               x >= 0
%
% The second term penalizes differences between neighboring components of x.

if exist('cvx_begin', 'file') ~= 2
    error('CVX is not on the MATLAB path. Run cvx_setup first.');
end

A = [1 2 0;
     0 1 1;
     1 0 1];
b = [4; 3; 2];
D = [1 -1 0;
     0  1 -1];
lambda = 0.5;

cvx_begin
    variable x(3)
    minimize(sum_square(A*x - b) + lambda*sum_square(D*x))
    subject to
        sum(x) == 3
        x >= 0
        x(1) <= 1
        x(3) >= 0.5
cvx_end

if isempty(strfind(cvx_status, 'Solved'))
    error('CVX did not solve the problem. Status: %s', cvx_status);
end

% The solution and objective value are known analytically for this example.
expected_x = [9/13; 89/65; 61/65];
expected_optval = 82/65;
assert(norm(x - expected_x, inf) < 1e-5, ...
    'Unexpected solution: x = [%g; %g; %g].', x(1), x(2), x(3));
assert(abs(cvx_optval - expected_optval) < 1e-5, ...
    'Unexpected optimal value: %g.', cvx_optval);

fprintf('CVX status: %s\n', cvx_status);
fprintf('Optimal value: %.6g\n', cvx_optval);
fprintf('x = [%.6g; %.6g; %.6g]\n', x(1), x(2), x(3));
fprintf('CVX constrained least-squares example passed.\n');
