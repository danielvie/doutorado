function [switching_offsets, objective, exitflag] = solve(problem, model_state)
    % Solve one receding-horizon QP and return its first control action.

    linear_cost = problem.qp.gradient_map * model_state;
    inequality_bound = problem.qp.inequality_base_bound ...
        - problem.qp.inequality_state_map * model_state;
    initial_plan = zeros(problem.qp.plan_size, 1);

    [plan, objective, exitflag] = quadprog( ...
        problem.qp.hessian, linear_cost, ...
        problem.qp.inequality_matrix, inequality_bound, ...
        [], [], [], [], initial_plan, problem.solver_options);

    if isempty(plan)
        switching_offsets = zeros(problem.action_count, 1);
    else
        switching_offsets = plan(1:problem.action_count);
    end
end
