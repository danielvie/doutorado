using LinearAlgebra, Convex, Clarabel
include("common.jl")
using .GainStudy

const S2_PSD_TOL = 1e-8
const S2_COST_MARGIN = 1e-9
const S2_MAX_INFLATION = 1e-5
# Clarabel 0.11.1 PSD completion indexes an OrderedSet unsupported by the pinned
# dependency. The official setting disables that optional decomposition only.
s2_solver_factory() = Clarabel.Optimizer(; GainStudy.SOLVER_OPTIONS..., chordal_decomposition_enable=false)

# The four-block Schur complement certifies full feedback only.
function s2_cost_block(X, Y, A, B, weight)
    G = A*X-B*Y
    I3 = Matrix{Float64}(I,3,3)
    I8 = Matrix{Float64}(I,8,8)
    [X G' X sqrt(weight)*Y';
     G X zeros(3,3) zeros(3,8);
     X zeros(3,3) I3 zeros(3,8);
     sqrt(weight)*Y zeros(8,3) zeros(8,3) I8]
end

function s2_check(m, Xraw, Y, Wraw, weight, rate)
    X = Matrix(symmetric(Xraw))
    W = Matrix(symmetric(Wraw))
    I3 = Matrix{Float64}(I,3,3)
    K = Y/X
    Praw = Matrix(symmetric(X\I3))
    F = m.A-m.B*K
    Q = I3+weight*K'*K
    D = Matrix(symmetric(Praw-F'*Praw*F))
    raw_cost = eigmin(symmetric(D-Q))
    # Scaling P changes neither K nor its contraction factors. A bounded, tiny
    # inflation restores a strict full-feedback cost residual after roundoff.
    inflation = raw_cost >= S2_COST_MARGIN ? 1.0 :
        1+max(0.0,(S2_COST_MARGIN-raw_cost)/eigmin(symmetric(D)))
    Pcost = inflation*Praw
    residuals = Dict{String,Any}(
        "symmetry_X"=>norm(Xraw-Xraw',Inf),
        "symmetry_W"=>norm(Wraw-Wraw',Inf),
        "min_eigenvalue_X"=>eigmin(symmetric(X)),
        "X_floor_residual"=>eigmin(symmetric(X-1e-7*I3)),
        "epigraph_min_eigenvalue"=>eigmin(symmetric([W I3; I3 X])),
        "open_rate_block_residual"=>eigmin(symmetric(contraction_block(X,m.A*X,rate)-1e-8*Matrix{Float64}(I,6,6))),
        "cost_block_min_eigenvalue"=>eigmin(symmetric(s2_cost_block(X,Y,m.A,m.B,weight))),
        "gain_recovery_relative"=>norm(K*X-Y)/max(1,norm(Y)),
        "inverse_recovery_relative"=>norm(Praw*X-I3)/norm(I3),
        "raw_full_feedback_cost_residual"=>raw_cost,
        "raw_open_rate_P_residual"=>eigmin(symmetric(rate^2*Praw-m.A'*Praw*m.A)),
        "cost_inflation"=>inflation,
        "full_feedback_cost_residual"=>eigmin(symmetric(Pcost-F'*Pcost*F-Q)),
        "open_rate_P_residual"=>eigmin(symmetric(rate^2*Pcost-m.A'*Pcost*m.A)),
        "full_feedback_stability_residual"=>eigmin(symmetric(Pcost-F'*Pcost*F)),
        "min_eigenvalue_Pcost"=>eigmin(symmetric(Pcost)),
        "epigraph_trace_gap"=>tr(W)-tr(Praw))
    reasons = String[]
    all(isfinite,X) && all(isfinite,Y) && all(isfinite,W) && all(isfinite,Pcost) || push!(reasons,"nonfinite synthesis variables")
    for key in ("symmetry_X","symmetry_W","gain_recovery_relative","inverse_recovery_relative")
        residuals[key] <= S2_PSD_TOL || push!(reasons,"$key exceeds tolerance")
    end
    residuals["min_eigenvalue_X"] >= 1e-7-1e-10 || push!(reasons,"X floor rejected")
    for key in ("epigraph_min_eigenvalue","open_rate_block_residual","cost_block_min_eigenvalue")
        residuals[key] >= -S2_PSD_TOL || push!(reasons,"$key rejected")
    end
    residuals["raw_open_rate_P_residual"] > 0 || push!(reasons,"open rate rejected in P coordinates")
    1 <= inflation <= 1+S2_MAX_INFLATION || push!(reasons,"cost inflation exceeds bounded numerical repair")
    residuals["full_feedback_cost_residual"] > 0 || push!(reasons,"strict full-feedback cost residual rejected")
    residuals["min_eigenvalue_Pcost"] > 0 || push!(reasons,"cost certificate not positive definite")
    (K=K,Praw=Praw,Pcost=Pcost,residuals=residuals,reasons=reasons)
end

# Runnable regression covers valid synthesis, numerical repair and rejection.
function s2_self_test()
    I3 = Matrix{Float64}(I,3,3)
    m = (A=.5*I3,B=zeros(3,8))
    Y = zeros(8,3)
    @assert isempty(s2_check(m,.5*I3,Y,2*I3,.001,.9).reasons)
    repaired = s2_check(m,(.75+1e-11)*I3,Y,(4/3)*I3,.001,.9)
    @assert isempty(repaired.reasons)
    @assert 1 < repaired.residuals["cost_inflation"] < 1+S2_MAX_INFLATION
    @assert !isempty(s2_check(m,.5*I3,Y,-I3,.001,.9).reasons)
    @assert !isempty(s2_check(m,.5*I3,Y,2*I3,.001,.4).reasons)
    @assert !isempty(s2_check((A=.9*I3,B=zeros(3,8)),I3,Y,I3,.001,.99).reasons)
    println("strategy-2 residual regression checks passed")
end

function main()
    started = time()
    m = load_model()
    denominators = baseline_costs(m)
    seed = certificate(m,m.Kcurrent,m.Pcurrent)
    seed_score = training_score(m,m.Kcurrent,denominators)
    bestK,bestP,bestscore = m.Kcurrent,seed.P,seed_score
    selected_id = "current-LQR"
    selected_synthesis = nothing
    best_synthesized = nothing
    best_synthesized_score = nothing
    logs = Dict{String,Any}[Dict("id"=>selected_id,"origin"=>"accepted seed",
        "accepted"=>true,"score"=>seed_score,"certificate"=>seed.check)]
    solver_calls,evaluations,accepted,rejected,solver_failures,exceptions = 0,1,1,0,0,0
    weights = [.0001,.001,.01]
    rates = [.9999,.99995,.99999]
    for weight in weights, rate in rates
        id = "w=$(weight),r0=$(rate)"
        entry = Dict{String,Any}("id"=>id,"synthesis_weight"=>weight,"open_rate"=>rate,"accepted"=>false)
        push!(logs,entry)
        stage = "solver construction"
        try
            I3 = Matrix{Float64}(I,3,3)
            X,Y,W = Semidefinite(3),Variable(8,3),Semidefinite(3)
            constraints = [X ⪰ 1e-7*I3,
                [W I3; I3 X] ⪰ 0,
                contraction_block(X,m.A*X,rate) ⪰ 1e-8*Matrix{Float64}(I,6,6),
                s2_cost_block(X,Y,m.A,m.B,weight) ⪰ 0]
            # No trace constraint: X retains the scale required by the cost LMI.
            problem = minimize(tr(W),constraints)
            solver_calls += 1
            stage = "solver execution"
            solved_at = time()
            solve!(problem,s2_solver_factory; silent=true)
            entry["solver_seconds"] = time()-solved_at
            entry["solver_status"] = string(problem.status)
            if !(entry["solver_status"] in ("OPTIMAL","ALMOST_OPTIMAL"))
                entry["rejection_reason"] = "solver did not return an accepted status; no instability claim"
                solver_failures += 1
                rejected += 1
                continue
            end
            stage = "independent synthesis checks"
            xr,yr,wr = evaluate(X),evaluate(Y),evaluate(W)
            entry["raw_solver_outputs"] = Dict("X"=>xr,"Y"=>yr,"W"=>wr,"objective"=>problem.optval)
            checked = s2_check(m,xr,yr,wr,weight,rate)
            diagnostics = Dict{String,Any}("id"=>id,"weight"=>weight,"open_rate"=>rate,
                "X"=>xr,"Y"=>yr,"W"=>wr,"K"=>checked.K,
                "P_cost_raw"=>checked.Praw,"P_cost"=>checked.Pcost,
                "inflation"=>checked.residuals["cost_inflation"],"residuals"=>checked.residuals,"raw_solver_outputs"=>entry["raw_solver_outputs"],
                "cost_bound_scope"=>"infinite-horizon normalized linearized full feedback only; not conditioned or nonlinear cost")
            entry["synthesis"] = diagnostics
            if !isempty(checked.reasons)
                entry["rejection_reason"] = join(checked.reasons,"; ")
                rejected += 1
                continue
            end
            stage = "trace-normalized stability certificate"
            cert = certificate(m,checked.K,checked.Pcost)
            diagnostics["stability_certificate"] = cert.check
            diagnostics["P_stability"] = cert.P
            diagnostics["stability_symmetry_residual"] = norm(cert.P-cert.P',Inf)
            diagnostics["stability_trace_residual"] = abs(tr(cert.P)-3)
            diagnostics["physical_gain_recovery_relative"] = norm((m.ts*checked.K/m.S)*m.S/m.ts-checked.K)/max(1,norm(checked.K))
            stage = "six-case training evaluation"
            evaluations += 1
            score = training_score(m,checked.K,denominators)
            entry["score"] = score
            entry["accepted"] = true
            entry["selection_outcome"] = "accepted, not selected"
            accepted += 1
            if isnothing(best_synthesized_score) || better(score,best_synthesized_score)
                best_synthesized,best_synthesized_score = diagnostics,score
            end
            if better(score,bestscore)
                bestK,bestP,bestscore = checked.K,cert.P,score
                selected_id,selected_synthesis = id,diagnostics
            end
            println("strategy-2 ",id,": accepted, training ratio=",score.mean_ratio)
        catch err
            err isa InterruptException && rethrow()
            entry["rejection_reason"] = sprint(showerror,err)
            entry["exception_stage"] = stage
            exceptions += 1
            rejected += 1
            println("strategy-2 ",id,": rejected at ",stage,": ",entry["rejection_reason"])
        end
    end
    for entry in logs
        if entry["accepted"]
            entry["selection_outcome"] = entry["id"] == selected_id ? "selected" : "accepted, not selected by training_score/better"
        end
    end
    improved = selected_id != "current-LQR"
    write_result("strategy-2",m,bestK,bestP,bestscore,logs;
        description="Joint full-feedback cost-LMI synthesis with a common open/full-feedback stability certificate",
        parameters=Dict("synthesis_weights"=>weights,"open_rates"=>rates,
            "evaluation_weight"=>.001,"evaluation_cycles"=>100,"training_cases"=>[c.name for c in training_cases(m)],
            "X_floor"=>1e-7,"open_rate_block_floor"=>1e-8,"PSD_absolute_tolerance"=>S2_PSD_TOL,
            "cost_residual_target"=>S2_COST_MARGIN,"maximum_cost_inflation_increment"=>S2_MAX_INFLATION,
            "trace_constraint_in_cost_synthesis"=>false,"chordal_decomposition_enable"=>false),
        elapsed_seconds=time()-started,
        extra=Dict("status"=>improved ? "improved training score" : "unchanged current-LQR seed",
            "selected_candidate"=>selected_id,"selected_synthesis"=>selected_synthesis,
            "best_synthesized_candidate"=>best_synthesized,"best_synthesized_training_score"=>best_synthesized_score,
            "development_solver_rejection_history"=>Dict("attempted_settings"=>9,"exceptions"=>9,
                "initial_chordal_decomposition_enable"=>true,
                "exception"=>"MethodError getindex(OrderedCollections.OrderedSet{Int64},Int64) in Clarabel psd_complete!",
                "resolution"=>"disabled optional chordal decomposition locally, retaining shared solver tolerances; no package changes"),
            "baseline_cost_denominators"=>denominators,"seed_training_score"=>seed_score,
            "counts"=>Dict("candidate_count"=>length(logs),"solver_calls"=>solver_calls,
                "objective_evaluations"=>evaluations,"baseline_trajectory_evaluations"=>6,
                "training_trajectory_evaluations"=>6*evaluations,"accepted_candidates"=>accepted,
                "rejected_settings"=>rejected,"solver_status_rejections"=>solver_failures,"exceptions"=>exceptions),
            "termination_reason"=>"completed all nine approved SDP settings",
            "cost_certificate_note"=>"Pcost may have bounded numerical inflation; raw X/Y/W and Pcost_raw are saved. Trace-normalized stability P is separate and carries no cost-bound claim.",
            "heldout_used"=>false))
end

if abspath(PROGRAM_FILE) == @__FILE__
    if "--self-test" in ARGS
        s2_self_test()
    else
        main()
    end
end
