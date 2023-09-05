
% Minimize J = x_1^2 + x_2^2
% Subject to C = x_1 + x_2 + 3 = 0

x = optimvar('x', 2, 1);
p = optimproblem();

p.Objective = x(1)^2 + x(2)^2;
p.Constraints.C = x(1) + x(2) + 3 == 0;

[sol, fval, extiflag, output, lambda] = solve(p);

sol.x
lambda.Constraints
