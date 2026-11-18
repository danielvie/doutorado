using LinearAlgebra
include("common.jl")
using .GainStudy

# Column-major vec(Z): five nullspace coordinates for each of three state inputs.
function parameter_scales(K0)
    repeat(reshape([norm(K0[:,j]) / sqrt(5) for j in 1:3], 1, 3), 5, 1)
end

function candidate_checks(m, K, P0, K0, N)
    all(isfinite, K) || error("Nonfinite gain")
    bn = norm(m.B*N)
    delta = norm(m.B*(K-K0))
    bn <= 1e-11*max(1, norm(m.B)) || error("BN residual exceeds tolerance")
    delta <= 1e-10*max(1, norm(m.B*K0)) || error("B(K-K0) residual exceeds tolerance")
    c = certificate(m, K, P0)
    seed_full = m.A-m.B*K0
    full = m.A-m.B*K
    endpoint_delta = norm(full'*c.P*full-seed_full'*c.P*seed_full)
    endpoint_delta <= 1e-10*max(1, norm(c.P)) || error("Fixed-P endpoint changed")
    Dict("BN_norm"=>bn, "B_gain_delta_norm"=>delta,
         "P_full_endpoint_delta_norm"=>endpoint_delta,
         "P_symmetry_residual"=>norm(c.P-c.P'),
         "P_trace_residual"=>abs(tr(c.P)-3),
         "endpoint_decreases"=>c.check["endpoint_decreases"])
end

function validate_score(score, denominators)
    length(score.costs) == length(denominators) == 6 || error("Invalid training cost count")
    all(x->isfinite(x) && x>=0, score.costs) || error("Invalid training costs")
    all(isfinite, (score.mean_ratio, score.worst_ratio, score.gain_norm)) ||
        error("Nonfinite training score")
    score.gain_norm >= 0 || error("Invalid gain norm")
    ratios = score.costs ./ denominators
    isapprox(score.mean_ratio, sum(ratios)/6; rtol=1e-12, atol=1e-12) ||
        error("Inconsistent mean ratio")
    isapprox(score.worst_ratio, maximum(ratios); rtol=1e-12, atol=1e-12) ||
        error("Inconsistent worst ratio")
    length(score.settling) == 6 &&
        all(x->isnothing(x) || (x isa Integer && 0<=x<=100), score.settling) ||
        error("Invalid settling outputs")
    score
end

function main()
    started = time_ns()
    m = load_model()
    K0, P0 = m.Kdecay, m.Pdecay
    N = nullspace(m.B)
    size(N) == (8,5) || error("Expected an 8-by-5 nullspace basis")
    norm(N'*N-I) < 1e-12 || error("Nullspace basis is not orthonormal")
    scales = parameter_scales(K0)
    all(x->isfinite(x) && x>0, scales) || error("Invalid parameter scales")
    denominators = baseline_costs(m)
    all(x->isfinite(x) && x>0, denominators) || error("Invalid baseline denominators")
    budget, bound = 200, 2.0
    step, minimum_step, reduction = 0.5, 0.015625, 0.5
    p = zeros(15)
    logs = Dict{String,Any}[]
    improvements = Dict{String,Any}[]
    seen = Dict{NTuple{15,Float64},Int}()
    evaluations = 0
    certificate_rejections = 0
    simulation_rejections = 0
    unexpected_exceptions = 0
    bound_skips = 0
    duplicate_skips = 0
    best_score = nothing
    seed_score = nothing
    best_id = 0
    sweep = 0
    step_history = Dict{String,Any}[]
    termination = ""

    function evaluate_candidate(q; coordinate=0, direction=0, sweep=0, step=0.0)
        id = length(logs)+1
        entry = Dict{String,Any}("candidate_id"=>id, "parameters"=>copy(q),
            "coordinate"=>coordinate, "direction"=>direction,
            "sweep"=>sweep, "step"=>step, "accepted"=>false)
        push!(logs, entry)
        if any(x->abs(x)>bound, q)
            bound_skips += 1
            entry["status"] = "bounds_skipped"
            return
        end
        key = Tuple(q)
        if haskey(seen, key)
            duplicate_skips += 1
            entry["status"] = "duplicate_skipped"
            entry["previous_candidate_id"] = seen[key]
            return
        end
        seen[key] = id
        Z = reshape(q,5,3).*scales
        K = K0+N*Z
        entry["Z"] = Z
        try
            entry["invariance_and_certificate"] = candidate_checks(m,K,P0,K0,N)
        catch err
            err isa InterruptException && rethrow()
            certificate_rejections += 1
            unexpected_exceptions += !(err isa ErrorException)
            entry["status"] = "certificate_or_invariance_rejected"
            entry["error_type"] = string(typeof(err))
            entry["reason"] = sprint(showerror, err)
            return
        end
        evaluations += 1
        entry["objective_evaluation"] = evaluations
        score = try
            validate_score(training_score(m,K,denominators), denominators)
        catch err
            err isa InterruptException && rethrow()
            simulation_rejections += 1
            unexpected_exceptions += !(err isa ErrorException)
            entry["status"] = "simulation_or_score_rejected"
            entry["error_type"] = string(typeof(err))
            entry["reason"] = sprint(showerror, err)
            return
        end
        entry["status"] = "scored"
        entry["training_score"] = score
        if isnothing(best_score) || better(score,best_score)
            previous_id = best_id
            best_score, best_id, p = score, id, copy(q)
            entry["accepted"] = true
            push!(improvements, Dict("candidate_id"=>id,
                "previous_candidate_id"=>previous_id, "objective_evaluation"=>evaluations,
                "mean_ratio"=>score.mean_ratio, "worst_ratio"=>score.worst_ratio,
                "gain_norm"=>score.gain_norm))
        end
    end

    evaluate_candidate(p)
    best_id == 1 || error("Saved Common-P seed was rejected; refusing to search")
    seed_score = best_score
    # Each coordinate's +/- trials share its starting incumbent. Improvements are
    # accepted immediately using the common tie-break, including the earlier seed.
    while evaluations < budget
        sweep += 1
        before = best_id
        first_evaluation = evaluations+1
        for coordinate in 1:15
            origin = copy(p)
            for direction in (1,-1)
                evaluations >= budget && break
                q = copy(origin)
                q[coordinate] += direction*step
                evaluate_candidate(q; coordinate, direction, sweep, step)
            end
            evaluations >= budget && break
        end
        improved = best_id != before
        push!(step_history, Dict("sweep"=>sweep, "step"=>step,
            "first_evaluation"=>first_evaluation, "last_evaluation"=>evaluations,
            "improved"=>improved, "best_candidate_id"=>best_id))
        if evaluations >= budget
            termination = "objective_evaluation_budget_exhausted"
            break
        elseif !improved
            if step <= minimum_step
                termination = "no_improvement_at_minimum_step"
                break
            end
            step *= reduction
        end
    end
    @assert evaluations <= budget
    @assert logs[1]["accepted"] && logs[1]["parameters"] == zeros(15)
    @assert count(l->haskey(l,"objective_evaluation"), logs) == evaluations
    @assert count(l->l["accepted"], logs) == length(improvements)
    Z = reshape(p,5,3).*scales
    K = K0+N*Z
    final_checks = candidate_checks(m,K,P0,K0,N)
    c = certificate(m,K,P0)
    open_residual = c.P-m.A'*c.P*m.A
    full = m.A-m.B*K
    full_residual = c.P-full'*c.P*full
    write_result("strategy-4",m,K,P0,best_score,logs;
        description="Bounded deterministic nullspace timing redistribution with fixed saved Common-P certificate and exact conditioned training cost.",
        parameters=Dict("parameter_shape"=>[5,3], "parameter_order"=>"column-major",
            "mapping"=>"Z = reshape(parameters,5,3) .* scales; K = K0 + N*Z",
            "scales"=>scales, "scale_rule"=>"norm(K0[:,j])/sqrt(5) for all five coordinates of column j",
            "lower_bounds"=>fill(-bound,15), "upper_bounds"=>fill(bound,15),
            "Z_absolute_bounds"=>bound.*scales, "initial_step"=>0.5,
            "step_reduction"=>reduction, "minimum_step"=>minimum_step,
            "step_reduction_rule"=>"Halve only after a complete sweep without an accepted improvement.",
            "directions"=>"Coordinates 1:15; +step then -step, both from the coordinate's starting incumbent; skip duplicates and out-of-bounds points.",
            "objective_evaluation_budget"=>budget,
            "BN_relative_tolerance"=>1e-11, "B_gain_delta_relative_tolerance"=>1e-10,
            "P_endpoint_delta_relative_tolerance"=>1e-10),
        elapsed_seconds=(time_ns()-started)/1e9,
        extra=Dict("status"=>best_id==1 ? "unchanged_seed" : "improved_seed",
            "seed"=>"saved Common-P decay gain and certificate",
            "seed_training_score"=>seed_score, "baseline_costs"=>denominators,
            "baseline_trajectory_count"=>6, "baseline_objective_evaluations"=>0,
            "candidate_count"=>length(logs), "unique_candidate_count"=>length(seen),
            "objective_evaluations"=>evaluations, "solver_calls"=>0,
            "certificate_rejections"=>certificate_rejections,
            "simulation_rejections"=>simulation_rejections,
            "rejection_count"=>certificate_rejections+simulation_rejections,
            "unexpected_exceptions"=>unexpected_exceptions,
            "bounds_skipped"=>bound_skips, "duplicates_skipped"=>duplicate_skips,
            "accepted_improvements"=>improvements[2:end],
            "accepted_candidate_count"=>length(improvements),
            "termination_reason"=>termination, "final_step"=>step,
            "step_history"=>step_history, "selected_candidate_id"=>best_id,
            "selected_parameters"=>p, "Z"=>Z, "N"=>N,
            "K0"=>K0, "P0_saved"=>P0,
            "nullspace_orthonormality_residual"=>norm(N'*N-I),
            "invariance_checks"=>final_checks, "BN"=>m.B*N,
            "B_gain_delta"=>m.B*(K-K0),
            "P_endpoint_residuals"=>Dict("open"=>open_residual,"full"=>full_residual),
            "regression_checks"=>"Run strategy-4.jl --self-test; search also asserts seed inclusion, budget and log accounting.",
            "scope"=>"Training-only exploratory search. Fixed certificate covers the conditioned linearized family, not nonlinear stability or a region of attraction."))
end

function self_test()
    m = load_model()
    N = nullspace(m.B)
    K0, P0 = m.Kdecay, m.Pdecay
    scales = parameter_scales(K0)
    @assert size(N) == (8,5) && norm(N'*N-I)<1e-12
    for coordinate in 1:15, direction in (-1,1)
        q = zeros(15)
        q[coordinate] = 2.0*direction
        K = K0+N*(reshape(q,5,3).*scales)
        candidate_checks(m,K,P0,K0,N)
    end
    @assert K0+N*(zeros(5,3).*scales) == K0
    invalid_rejected = false
    try
        candidate_checks(m,K0+m.B',P0,K0,N)
    catch err
        err isa ErrorException || rethrow()
        invalid_rejected = true
    end
    @assert invalid_rejected
    score = (mean_ratio=1.0,worst_ratio=1.0,gain_norm=norm(K0),
             costs=ones(6),settling=fill(nothing,6))
    validate_score(score,ones(6))
    @assert !better(score,score)
    invalid_rejected = false
    try
        validate_score(merge(score,(costs=fill(NaN,6),)),ones(6))
    catch err
        err isa ErrorException || rethrow()
        invalid_rejected = true
    end
    @assert invalid_rejected
    println("strategy-4 self-test passed: 30 bounded directions preserve the certificate; altered gain and nonfinite score rejected; seed and tie-break checked.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    if ARGS == ["--self-test"]
        self_test()
    elseif isempty(ARGS)
        main()
    else
        error("Usage: strategy-4.jl [--self-test]")
    end
end
