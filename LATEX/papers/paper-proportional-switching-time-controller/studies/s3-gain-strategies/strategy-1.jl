using LinearAlgebra, Convex, Clarabel
include("common.jl")
using .GainStudy

const COARSE_VALUES = (-1.0, 0.0, 1.0)
const REFINEMENT_STEPS = (0.5, 0.25, 0.125)
const SETTING_BUDGET = 45

function coordinate_neighbors(center, step)
    neighbors = NTuple{3,Float64}[]
    for axis in 1:3, direction in (-1.0, 1.0)
        point = collect(center)
        point[axis] = clamp(point[axis] + direction * step, -1.0, 1.0)
        push!(neighbors, Tuple(point))
    end
    neighbors
end

function self_test()
    @assert length(collect(Iterators.product(COARSE_VALUES, COARSE_VALUES, COARSE_VALUES))) == 27
    @assert coordinate_neighbors((0.0, 0.0, 0.0), 0.5) == [
        (-0.5, 0.0, 0.0), (0.5, 0.0, 0.0), (0.0, -0.5, 0.0),
        (0.0, 0.5, 0.0), (0.0, 0.0, -0.5), (0.0, 0.0, 0.5)]
    clipped = coordinate_neighbors((1.0, -1.0, 0.0), 0.5)
    @assert count(==((1.0, -1.0, 0.0)), clipped) == 2
    @assert all(p -> all(x -> -1.0 <= x <= 1.0, p), clipped)
    settings = Set(Tuple(Float64.(p)) for p in Iterators.product(COARSE_VALUES, COARSE_VALUES, COARSE_VALUES))
    for step in REFINEMENT_STEPS
        union!(settings, coordinate_neighbors((1.0, -1.0, 0.0), step))
    end
    @assert length(settings) <= SETTING_BUDGET
    score = (mean_ratio=1.0, worst_ratio=1.1, gain_norm=2.0)
    @assert !better(score, score) # Exact ties retain the earlier candidate.
    @assert better((mean_ratio=0.9, worst_ratio=2.0, gain_norm=3.0), score)
    @assert better((mean_ratio=1.0, worst_ratio=1.0, gain_norm=3.0), score)
    @assert better((mean_ratio=1.0, worst_ratio=1.1, gain_norm=1.0), score)
    println("strategy-1 self-test passed")
end

function main()
    started = time_ns()
    m = load_model()
    cases = training_cases(m)
    @assert length(cases) == 6 && all(c -> c.split == "training", cases)
    denominators = baseline_costs(m)
    @assert length(denominators) == 6 && all(x -> isfinite(x) && x > 0, denominators)
    seed_certificate = certificate(m, m.Kcurrent, m.Pcurrent)
    seed_score = training_score(m, m.Kcurrent, denominators)
    @assert abs(seed_score.mean_ratio - 1.0) < 1e-12

    best_K, best_P, best_score = copy(m.Kcurrent), seed_certificate.P, seed_score
    best_setting = (0.0, 0.0, 0.0)
    best_id = 0
    logs = Dict{String,Any}[Dict(
        "candidate_id"=>0, "phase"=>"seed", "status"=>"accepted_seed",
        "source"=>"current LQR", "setting"=>collect(best_setting),
        "certificate"=>seed_certificate.check, "score"=>seed_score,
        "incumbent_updated"=>true)]
    cache = Dict{NTuple{3,Float64},Int}()
    solver_calls = 0
    objective_evaluations = 1
    lqr_calls = 0
    certificate_rejections = 0
    exception_count = 0
    evaluated_settings = 0

    function visit(setting, phase)
        if haskey(cache, setting)
            push!(logs, Dict("phase"=>phase, "setting"=>collect(setting),
                "status"=>"cached", "cached_candidate_id"=>cache[setting]))
            return
        end
        @assert length(cache) < SETTING_BUDGET
        id = length(cache) + 1
        cache[setting] = id
        a, b, c = setting
        Q = Matrix(Diagonal([10.0^a, 10.0^b, 1.0]))
        R = Matrix(Diagonal(fill(0.001 * 10.0^c, 8)))
        log = Dict{String,Any}("candidate_id"=>id, "phase"=>phase,
            "setting"=>collect(setting), "Q_diagonal"=>diag(Q),
            "R_scalar"=>R[1,1], "incumbent_updated"=>false)
        push!(logs, log)
        candidate_started = time_ns()
        stage = "checked_lqr"
        try
            lqr_calls += 1
            K = checked_lqr(m.A, m.B, Q, R)
            stage = "fixed_gain_certificate"
            solver_calls += 1
            cert = fixed_gain_certificate(m, K)
            if isnothing(cert)
                certificate_rejections += 1
                log["status"] = "certificate_numerically_rejected"
                log["reason"] = "Shared fixed-gain SDP returned no accepted certificate; this is not proof of instability."
                return
            end
            log["solver_status"] = cert.status
            log["eta"] = cert.eta
            log["certificate"] = cert.check
            stage = "training_score"
            objective_evaluations += 1
            score = training_score(m, K, denominators)
            evaluated_settings += 1
            log["status"] = "certified_evaluated"
            log["score"] = score
            if better(score, best_score)
                best_K, best_P, best_score = K, cert.P, score
                best_setting, best_id = setting, id
                log["incumbent_updated"] = true
            end
        catch err
            err isa InterruptException && rethrow()
            exception_count += 1
            log["status"] = "exception_rejected"
            log["failure_stage"] = stage
            log["exception_type"] = string(typeof(err))
            log["reason"] = sprint(showerror, err)
        finally
            log["elapsed_seconds"] = (time_ns() - candidate_started) / 1e9
        end
    end

    # Explicit nested loops establish the deterministic earlier-candidate order.
    for a in COARSE_VALUES, b in COARSE_VALUES, c in COARSE_VALUES
        visit((a, b, c), "coarse_grid")
    end
    refinement_centers = Dict{String,Any}[]
    for step in REFINEMENT_STEPS
        center = best_setting
        push!(refinement_centers, Dict("step"=>step, "center"=>collect(center),
            "incumbent_candidate_id"=>best_id))
        for setting in coordinate_neighbors(center, step)
            visit(setting, "coordinate_step_$step")
        end
    end
    @assert length(cache) <= SETTING_BUDGET
    @assert lqr_calls == length(cache)
    @assert evaluated_settings + certificate_rejections + exception_count == length(cache)
    @assert objective_evaluations == evaluated_settings + 1 || exception_count > 0
    improved = better(best_score, seed_score)
    @assert improved == (best_id != 0)
    termination = "Completed 27-point coarse grid and six clipped coordinate proposals at each of 0.5, 0.25, 0.125; duplicates reused from cache."
    write_result("strategy-1", m, best_K, best_P, best_score, logs;
        description="Diagonal LQR-weight search with a checked common-P certificate for every evaluated gain.",
        parameters=Dict("Q"=>"diag(10^a,10^b,1)", "R"=>"0.001*10^c I8",
            "coarse_values"=>collect(COARSE_VALUES), "refinement_steps"=>collect(REFINEMENT_STEPS),
            "bounds"=>[-1.0,1.0], "candidate_setting_budget"=>SETTING_BUDGET,
            "selected_setting"=>collect(best_setting), "refinement_centers"=>refinement_centers,
            "evaluation_Q"=>"I3", "evaluation_R"=>"0.001 I8",
            "selection"=>"shared better(): mean ratio, worst ratio, gain norm, earlier candidate"),
        elapsed_seconds=(time_ns()-started)/1e9,
        extra=Dict("status"=>improved ? "improved_training_score" : "unchanged_current_lqr_seed",
            "selected_candidate_id"=>best_id, "seed_training_score"=>seed_score,
            "baseline_denominators"=>denominators, "training_case_names"=>[c.name for c in cases],
            "candidate_count"=>length(cache)+1, "candidate_settings_count"=>length(cache),
            "proposal_count"=>45, "cache_hits"=>count(l -> l["status"] == "cached", logs),
            "objective_evaluations"=>objective_evaluations,
            "baseline_trajectory_evaluations"=>6,
            "training_trajectory_evaluations_requested"=>6*objective_evaluations,
            "solver_calls"=>solver_calls, "lqr_calls"=>lqr_calls,
            "certified_evaluated_settings"=>evaluated_settings,
            "certificate_rejections"=>certificate_rejections, "exception_rejections"=>exception_count,
            "termination_reason"=>termination,
            "limitations"=>"Training selection only; endpoint common-P checks cover the conditioned linearized family, not nonlinear stability or heldout performance."))
end

if abspath(PROGRAM_FILE) == @__FILE__
    if ARGS == ["--self-test"]
        self_test()
    elseif isempty(ARGS)
        main()
    else
        error("Usage: strategy-1.jl [--self-test]")
    end
end
