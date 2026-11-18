using LinearAlgebra, Convex, Clarabel
include("common.jl")
using .GainStudy

# Every poll uses the same incumbent, visits column-major coordinates and tries
# + before -. Only certificate-passing proposals consume objective evaluations.
function coordinate_search(K0, D, check_gain, score_gain;
                           max_evaluations=200, initial_step=0.1,
                           minimum_step=1e-4, bound=2.0)
    theta = zeros(size(K0))
    seed_check = check_gain(K0)
    seed_score = score_gain(K0)
    best_score = seed_score
    logs = Dict{String,Any}[
        Dict("trial"=>1, "poll"=>0, "Theta"=>copy(theta), "coordinate"=>nothing,
             "direction"=>0, "step"=>0.0, "backtracks"=>0,
             "status"=>"seed", "certificate"=>seed_check,
             "score"=>seed_score, "accepted"=>true)]
    evaluations, rejections, bound_rejections, failures = 1, 0, 0, 0
    acceptance_count, backtracks, polls = 1, 0, 0
    step = initial_step
    while evaluations < max_evaluations && step >= minimum_step
        polls += 1
        poll_theta, poll_score = copy(theta), best_score
        winning_trial = 0
        for coordinate in CartesianIndices(theta), direction in (1, -1)
            evaluations >= max_evaluations && break
            proposal_step, trial_backtracks = step, 0
            while proposal_step >= minimum_step
                proposal = copy(theta)
                proposal[coordinate] += direction * proposal_step
                K = K0 + D .* proposal
                entry = Dict{String,Any}(
                    "trial"=>length(logs)+1, "poll"=>polls,
                    "Theta"=>copy(proposal), "coordinate"=>collect(Tuple(coordinate)),
                    "direction"=>direction, "step"=>proposal_step,
                    "poll_step"=>step, "backtracks"=>trial_backtracks,
                    "accepted"=>false, "score"=>nothing)
                push!(logs, entry)
                if maximum(abs, proposal) > bound
                    entry["status"] = "bound_rejected"
                    bound_rejections += 1
                else
                    checked = try
                        check_gain(K)
                    catch err
                        err isa ErrorException || rethrow()
                        entry["status"] = "certificate_rejected"
                        entry["reason"] = sprint(showerror, err)
                        rejections += 1
                        nothing
                    end
                    if !isnothing(checked)
                        entry["certificate"] = checked
                        evaluations += 1
                        entry["objective_evaluation"] = evaluations
                        score = try
                            score_gain(K)
                        catch err
                            err isa ErrorException || rethrow()
                            entry["status"] = "simulation_failed"
                            entry["reason"] = sprint(showerror, err)
                            failures += 1
                            nothing
                        end
                        if !isnothing(score)
                            entry["status"] = "evaluated"
                            entry["score"] = score
                            if better(score, poll_score)
                                poll_theta, poll_score = proposal, score
                                winning_trial = length(logs)
                            end
                        end
                        break
                    end
                end
                proposal_step /= 2
                trial_backtracks += 1
                backtracks += 1
            end
        end
        if winning_trial != 0
            theta, best_score = poll_theta, poll_score
            logs[winning_trial]["accepted"] = true
            acceptance_count += 1
        else
            step /= 2
        end
        println("strategy-5 poll=", polls, " evaluations=", evaluations,
                " certificate_rejections=", rejections,
                " step=", step, " best_ratio=", best_score.mean_ratio)
        flush(stdout)
    end
    counts = Dict("candidate_count"=>length(logs),
        "objective_evaluations"=>evaluations, "solver_calls"=>0,
        "certificate_rejections"=>rejections, "bound_rejections"=>bound_rejections,
        "simulation_failures"=>failures, "acceptance_count"=>acceptance_count,
        "certificate_passes"=>evaluations, "backtracks"=>backtracks,
        "poll_count"=>polls)
    termination = evaluations >= max_evaluations ? "evaluation_budget" : "minimum_step"
    (; theta, score=best_score, seed_score, logs, counts, termination, final_step=step)
end

# These checks recompute endpoint matrices directly, without certificate().
function independent_postchecks(m, K, P, K0, D, theta, score, denominators, margin)
    @assert norm(P-P', Inf) <= 1e-12
    @assert abs(tr(P)-3) <= 1e-12
    eigenvalue_P = eigmin(Symmetric((P+P')/2))
    decreases = Float64[]
    for M in (m.A, m.A-m.B*K)
        Q = P-M'*P*M
        push!(decreases, eigmin(Symmetric((Q+Q')/2)))
    end
    @assert eigenvalue_P >= 1e-7-1e-10
    @assert minimum(decreases) > margin
    @assert maximum(abs, theta) <= 2.0
    @assert norm(K-(K0+D.*theta), Inf) <= 1e-12
    physical = m.ts*K/m.S
    recovery_residual = norm(physical*m.S/m.ts-K, Inf)
    @assert recovery_residual <= 1e-10
    # Verification runs are not used for candidate selection or its budget.
    runs = [simulate(m,K,c.z) for c in training_cases(m)]
    costs = Float64[r["cost"] for r in runs]
    ratios = costs ./ denominators
    @assert maximum(abs, costs-score.costs) <= 1e-10
    @assert abs(sum(ratios)/length(ratios)-score.mean_ratio) <= 1e-12
    @assert abs(maximum(ratios)-score.worst_ratio) <= 1e-12
    @assert [r["sustained_cycle"] for r in runs] == score.settling
    Dict("endpoint_decreases"=>decreases, "min_eigenvalue_P"=>eigenvalue_P,
         "symmetry_residual"=>norm(P-P',Inf), "trace_residual"=>abs(tr(P)-3),
         "gain_recovery_residual"=>recovery_residual,
         "training_costs"=>costs, "verification_trajectory_count"=>length(runs))
end

function check_search_accounting(search, max_evaluations)
    logs, counts = search.logs, search.counts
    @assert counts["candidate_count"] == length(logs)
    @assert counts["objective_evaluations"] <= max_evaluations
    @assert counts["objective_evaluations"] ==
        count(e->e["status"] in ("seed", "evaluated", "simulation_failed"), logs)
    @assert counts["certificate_rejections"] ==
        count(e->e["status"] == "certificate_rejected", logs)
    @assert counts["bound_rejections"] == count(e->e["status"] == "bound_rejected", logs)
    @assert counts["simulation_failures"] == count(e->e["status"] == "simulation_failed", logs)
    @assert counts["acceptance_count"] == count(e->e["accepted"], logs)
    @assert logs[1]["status"] == "seed" && logs[1]["accepted"]
    @assert all(e->!e["accepted"] || maximum(abs,e["Theta"]) <= 2.0, logs)
    @assert better(search.score, search.seed_score) || search.score == search.seed_score
end

function self_test()
    K0, D = zeros(1,1), ones(1,1)
    check_gain(K) = abs(K[1]) < 0.075 ? Dict("ok"=>true) : error("synthetic rejection")
    score_gain(K) = (mean_ratio=(K[1]-0.04)^2, worst_ratio=(K[1]-0.04)^2,
                     gain_norm=norm(K), costs=[(K[1]-0.04)^2], settling=[nothing])
    search = coordinate_search(K0,D,check_gain,score_gain; max_evaluations=9)
    check_search_accounting(search,9)
    @assert search.counts["objective_evaluations"] == 9
    @assert search.counts["certificate_rejections"] > 0
    @assert any(e->e["direction"] == -1, search.logs)
    @assert better(search.score,search.seed_score)
    @assert any(e->get(e,"backtracks",0)>0 && e["status"]=="evaluated",search.logs)
    constant_score(K) = (mean_ratio=1.0,worst_ratio=1.0,gain_norm=0.0,
                         costs=[1.0],settling=[nothing])
    unchanged = coordinate_search(K0,D,K->Dict("ok"=>true),constant_score;
                                  max_evaluations=200)
    check_search_accounting(unchanged,200)
    @assert unchanged.termination == "minimum_step"
    @assert unchanged.theta == K0 && unchanged.counts["acceptance_count"] == 1
    @assert unchanged.final_step < 1e-4
    # Bound rejection must not consume an objective call.
    bounded = coordinate_search(K0,D,K->Dict("ok"=>true),score_gain;
                                max_evaluations=3,bound=0.03)
    @assert bounded.counts["bound_rejections"] == 4
    @assert bounded.counts["objective_evaluations"] == 3
    # Simulation failures consume the budget and never become accepted updates.
    failed_score(K) = iszero(K[1]) ? constant_score(K) : error("synthetic simulation failure")
    failed = coordinate_search(K0,D,K->Dict("ok"=>true),failed_score;max_evaluations=3)
    check_search_accounting(failed,3)
    @assert failed.counts["simulation_failures"] == 2
    @assert failed.counts["acceptance_count"] == 1
    println("strategy-5 self-test passed")
end

function main()
    started = time()
    m = load_model()
    K0 = copy(m.Kcurrent)
    D = max.(1.0,abs.(K0))
    seed_certificate = certificate(m,K0,m.Pcurrent)
    P = seed_certificate.P
    margin = 0.1*minimum(seed_certificate.check["endpoint_decreases"])+1e-9
    fixed_check(K) = certificate(m,K,P; margin=margin).check
    denominators = baseline_costs(m)
    search = coordinate_search(K0,D,fixed_check,K->training_score(m,K,denominators))
    check_search_accounting(search,200)
    K = K0+D.*search.theta
    final_check = fixed_check(K)
    postchecks = independent_postchecks(m,K,P,K0,D,search.theta,search.score,denominators,margin)
    improved = better(search.score,search.seed_score)
    parameters = Dict("K0"=>K0,"D"=>D,"Theta"=>search.theta,"fixed_P"=>P,
        "theta_absolute_bound"=>2.0,"initial_step"=>0.1,"minimum_step"=>1e-4,
        "final_step"=>search.final_step,"max_objective_evaluations"=>200,
        "margin_threshold"=>margin,"seed_certificate"=>seed_certificate.check,
        "baseline_denominators"=>denominators,
        "coordinate_order"=>"column-major; positive then negative; best of poll",
        "backtracking"=>"halve infeasible directional steps until below minimum_step")
    extra = Dict{String,Any}("counts"=>search.counts,"termination_reason"=>search.termination,
        "status"=>improved ? "improved" : "unchanged_seed",
        "seed_training_score"=>search.seed_score,
        "strict_final_certificate"=>final_check,"independent_postchecks"=>postchecks,
        "postcheck_trajectory_count"=>6,
        "limitations"=>["Finite deterministic local search, not a global optimum.",
            "Fixed-P certificate concerns the conditioned linearized family only.",
            "Floating-point checks are not interval-arithmetic proofs.",
            "No withheld or historical outcomes used in selection."])
    write_result("strategy-5",m,K,P,search.score,search.logs;
        description="Full gain coordinate tuning with the current fixed common P",
        parameters=parameters,elapsed_seconds=time()-started,extra=extra)
end

if abspath(PROGRAM_FILE) == @__FILE__
    if ARGS == ["--self-test"]
        self_test()
    elseif isempty(ARGS)
        main()
    else
        error("Usage: strategy-5.jl [--self-test]")
    end
end
