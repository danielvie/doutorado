function comparison = mpc_comparison_data(study,b,model,controller,response)
%MPC_COMPARISON_DATA Check the saved 1x predictive-control reference before adoption.
s = study.benchmark;
assert(study.error_scale == 1 && norm(study.initial_state-b.initial_state,inf) < 1e-12);
for name = {'state_scale','timing_scale','nominal_dwell','period', ...
        'orbit_anchor','initial_state','applied_schedule_dwell_bound', ...
        'aggressive_input_weight','cycle_count'}
    assert(isequal(s.(name{1}),b.(name{1})), 'Stale MPC benchmark: %s',name{1});
end
for name = {'A','b','Omega','Ts'}
    assert(isequal(s.config.(name{1}),b.config.(name{1})), ...
        'Stale MPC plant or schedule: %s',name{1});
end
assert(norm(study.model.Phi-model.Phi,'fro') < 1e-12);
assert(norm(study.model.Gamma-model.Gamma,'fro') < 1e-12);
assert(norm(study.controller.K_aggressive_physical-controller.K_aggressive_physical,'fro') < 1e-12);
index = find(string(study.names) == "mpc-5"); assert(isscalar(index));
p = study.problems{index}; r = study.responses{index};
assert(p.prediction_horizon == 5 && p.update_period_cycles == 1);
assert(~p.prediction.uses_previous_action && p.qp.plan_size == 40);
A = b.state_scale\model.Phi*b.state_scale;
B = b.state_scale\model.Gamma*b.timing_scale;
assert(norm(p.prediction.state_transition-A,'fro') < 1e-12);
assert(norm(p.prediction.input_matrix-B,'fro') < 1e-12);
Q = eye(3)/b.aggressive_input_weight;
[K,P] = dlqr(A,B,Q,eye(8));
assert(norm(p.feedback_gain-K,'fro') < 1e-9);
H = eye(40); G = zeros(40,3); F = eye(3); U = zeros(3,40);
for j = 1:5
    F = A*F; U = A*U; U(:,(j-1)*8+(1:8)) = B;
    W = Q; if j == 5, W = P; end
    H = H+U'*W*U; G = G+U'*W*F;
end
assert(norm(p.qp.hessian-2*H,'fro')/norm(2*H,'fro') < 1e-10);
assert(norm(p.qp.gradient_map-2*G,'fro')/norm(2*G,'fro') < 1e-10);
D = diff([zeros(1,8);eye(8);zeros(1,8)]);
assert(isequal(p.qp.inequality_matrix(1:45,:),-kron(eye(5),D)));
assert(norm(p.qp.inequality_base_bound(1:45)- ...
    repmat((b.nominal_dwell-b.applied_schedule_dwell_bound)/b.timing_scale,5,1),inf) < 1e-12);
assert(size(p.qp.inequality_matrix,1) > 45, 'Missing MPC terminal-set constraints.');
assert(r.completed_cycles == b.cycle_count && isnan(r.failed_cycle));
assert(all(r.exitflag == 1) && all(isfinite(r.states(:))));
assert(norm(r.states(:,1)-b.initial_state,inf) < 1e-12);
assert(max(abs(r.dwell-(b.nominal_dwell+D*r.offsets(2:end,:))),[],'all') < 1e-12);
assert(min(r.dwell,[],'all') >= b.applied_schedule_dwell_bound-1e-12);
assert(max(abs(sum(r.dwell,1)-b.period)) < 1e-12);
z = b.state_scale\(r.states-b.orbit_anchor);
assert(max(abs(vecnorm(z,2,1)'-r.error)) < 1e-12);
for k = 1:b.cycle_count
    next = paper.exact_cycle(b.config,r.states(:,k),r.offsets(2:end,k));
    assert(norm(next-r.states(:,k+1),inf) < 1e-10, 'Stale MPC exact-plant trajectory.');
end
index = find(string(study.names) == "daniel"); assert(isscalar(index));
d = study.responses{index};
assert(max(abs(d.states-response.conditioned_states),[],'all') < 1e-12);
assert(max(abs(d.offsets(2:end,:)-response.applied_offsets),[],'all') < 1e-12);
errors = [response.conditioned_error,r.error];
costs = zeros(1,2); crossings = zeros(1,2);
for j = 1:2
    states = response.conditioned_states; offsets = response.applied_offsets;
    if j == 2, states = r.states; offsets = r.offsets(2:end,:); end
    z = b.state_scale\(states(:,1:end-1)-b.orbit_anchor);
    v = offsets/b.timing_scale;
    costs(j) = sum(z.^2,'all')+b.aggressive_input_weight*sum(v.^2,'all');
    first = find(errors(:,j)<0.01,1); last = find(errors(:,j)>=0.01,1,'last');
    assert(~isempty(first) && first-1 == last, 'First/persistent threshold crossings differ.');
    crossings(j) = first-1;
end
comparison = struct('horizon',5,'cycle',(0:b.cycle_count)', ...
    'time_ms',(0:b.cycle_count)'*b.period*1e3,'error',errors, ...
    'mpc_states',r.states,'mpc_offsets',r.offsets(2:end,:),'mpc_dwell',r.dwell, ...
    'cost',costs,'threshold_cycle',crossings,'Phi',model.Phi,'Gamma',model.Gamma, ...
    'K',controller.K_aggressive_physical,'nominal_dwell',b.nominal_dwell, ...
    'state_scale',b.state_scale,'initial_state',b.initial_state,'period',b.period);
end
