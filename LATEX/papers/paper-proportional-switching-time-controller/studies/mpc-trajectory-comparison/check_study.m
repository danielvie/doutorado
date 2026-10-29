function metrics = check_study()
%CHECK_STUDY Runnable saved-evidence regression checks, without solving QPs.
here = fileparts(mfilename('fullpath')); root = fileparts(fileparts(here));
addpath(fullfile(root,'scripts')); paths = paper.paths(); addpath(paths.simulation);
saved = load(fullfile(here,'evidence.mat')); e = saved.evidence; b = e.benchmark;
assert(isequaln(b,paper.benchmark()),'Current benchmark differs from saved study.');
assert(b.cycle_count == 100 && b.trajectory_samples_per_interval == 30);
assert(isequal(b.initial_state,[7.5143;20.8211;0.0314]));
p = e.publication; stride = numel(b.nominal_dwell)*30;
assert(isequal(size(p.state_off),[100*stride+1,3]));
assert(norm(p.state_off(1,:)'-b.initial_state,inf) < 1e-12);
assert(norm(p.long_open_loop_states(:,1)-b.initial_state,inf) < 1e-12);
assert(size(p.long_open_loop_states,2) == 100001 && numel(p.long_open_loop_error) == 100001);
open_error = vecnorm(b.state_scale\(p.long_open_loop_states-b.orbit_anchor),2,1)';
assert(max(abs(open_error-p.long_open_loop_error(:))) < 1e-12);
assert(max(abs(p.state_off(1:stride:end,:)'-p.long_open_loop_states(:,1:101)),[],'all') < 1e-10);
[t,ref] = paper.sample_cycle(b.config,b.orbit_anchor,zeros(8,1),30);
assert(max(abs(ref-p.reference_state),[],'all') < 1e-12);
assert(max(abs(t-p.reference_time)) < 1e-15);
minimum = zeros(2,1); period_residual = minimum; endpoint_residual = minimum;
state_reference_residual = minimum; offset_reference_residual = minimum; first_crossing = minimum;
for j = 1:2
    r = e.responses{j};
    assert(r.completed_cycles == 100 && size(r.states,2) == 101);
    assert(isequal(r.states(:,1),b.initial_state));
    assert(all(isfinite(r.states),'all') && all(isfinite(r.dense),'all'));
    assert(isequal(size(r.offsets),[8,100]),'Only interior offsets belong in sample_cycle.');
    if j == 2, assert(all(r.exitflag == 1)); end
    dwell = diff(b.config.Ts(:)+[zeros(1,100);r.offsets;zeros(1,100)],1,1);
    assert(max(abs(dwell-r.dwell),[],'all') < 1e-15);
    minimum(j) = min(dwell,[],'all')*1e6;
    period_residual(j) = max(abs(sum(dwell,1)-b.period));
    assert(minimum(j) >= (b.applied_schedule_dwell_bound-1e-12)*1e6);
    assert(period_residual(j) < 1e-12);
    assert(isequal(size(r.dense),[27001,3]) && all(diff(r.time)>0));
    assert(abs(r.time(end)-100*b.period) < 1e-12);
    assert(max(abs(r.dense(1:stride:end,:)'-r.states),[],'all') < 1e-11);
    assert(max(abs(vecnorm(b.state_scale\(r.states-b.orbit_anchor),2,1)'-r.error)) < 1e-14);
    endpoint_residual(j) = max(r.interval_endpoint_residual);
    for k = 1:100
        rows = (k-1)*stride+(1:stride+1);
        expected_times = (k-1)*b.period+b.config.Ts(:)+[0;r.offsets(:,k);0];
        assert(max(abs(r.time(rows(1:30:end))-expected_times)) < 1e-12);
        actual_boundaries = paper.cycle_boundaries(b.config,r.states(:,k),r.offsets(:,k));
        residual = max(abs(r.dense(rows(1:30:end),:)'-actual_boundaries),[],'all');
        assert(residual < 1e-11);
        next = paper.exact_cycle(b.config,r.states(:,k),r.offsets(:,k));
        assert(norm(next-r.states(:,k+1),inf) < 1e-11);
    end
    if j == 1
        ref_states = e.reference_proposed.states;
        % The older study includes a fixed zero offset at the first boundary.
        assert(all(e.reference_proposed.offsets(1,:)==0));
        ref_offsets = e.reference_proposed.offsets(2:end,:);
        assert(max(abs(r.dense-p.state_on),[],'all') < 1e-8);
    else
        ref_states = e.reference_mpc.mpc_states; ref_offsets = e.reference_mpc.mpc_offsets;
    end
    state_reference_residual(j) = max(abs(r.states-ref_states),[],'all');
    offset_reference_residual(j) = max(abs(r.offsets-ref_offsets),[],'all');
    % Absolute tolerances accommodate solver/BLAS roundoff, far below plotting resolution.
    assert(state_reference_residual(j) < 1e-8 && offset_reference_residual(j) < 1e-11);
    assert(max(abs(b.state_scale\(r.states-ref_states)),[],'all') < 1e-8);
    first_crossing(j) = find(r.error < 0.01,1)-1;
    assert(first_crossing(j)>=1 && r.error(first_crossing(j)+1)<0.01);
    assert(all(r.error(1:first_crossing(j))>=0.01));
end
open_crossing = find(open_error>=0.01,1,'last');
assert(open_crossing == p.convergence_cycle && all(open_error(open_crossing+1:end)<0.01));
metrics = table(string(e.names)',minimum,period_residual,endpoint_residual, ...
    state_reference_residual,offset_reference_residual,first_crossing, ...
    'VariableNames',{'method','minimum_dwell_us','period_residual_s','dense_endpoint_residual', ...
    'saved_state_residual','saved_offset_residual_s','first_cycle_below_001'});
disp(metrics); fprintf('All checks passed. Persistent open-loop crossing: k=%d.\n',open_crossing);
fid = fopen(fullfile(here,'validation.txt'),'w'); assert(fid>=0);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%s\nAll checks passed. 100/100 MPC QPs successful.\nPersistent open-loop crossing: k=%d.\n',evalc('disp(metrics)'),open_crossing);
writetable(metrics,fullfile(here,'validation.csv'));
end
