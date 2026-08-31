function result = cvx_example()
%CVX_EXAMPLE  Solve a small convex optimization problem with MATLAB CVX.
%
%   Minimize the squared distance to [1; 2], subject to x + y >= 4 and
%   nonnegative decision variables.  The expected solution is [1.5; 2.5].
%
%   Requires CVX to be installed and initialized on the MATLAB path.

cvx_begin
    variables x y
    minimize((x - 1)^2 + (y - 2)^2)
    subject to
        x + y >= 4
        x >= 0
        y >= 0
cvx_end

if ~strcmp(cvx_status, 'Solved')
    error('cvx_example:solveFailed', ...
        'CVX did not solve the problem. Status: %s', cvx_status);
end

solution = [x; y];
expected = [1.5; 2.5];
assert(norm(solution - expected) < 1e-4, ...
    'Unexpected solution: [%g; %g].', solution(1), solution(2));

fprintf('CVX status: %s\n', cvx_status);
fprintf('Optimal value: %.6f\n', cvx_optval);
fprintf('Solution: x = %.6f, y = %.6f\n', x, y);

result = struct('status', cvx_status, 'optimal_value', cvx_optval, ...
    'solution', solution);
end
