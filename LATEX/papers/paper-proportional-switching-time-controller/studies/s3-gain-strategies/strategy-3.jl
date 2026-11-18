using LinearAlgebra, Convex, Clarabel
include("common.jl")
using .GainStudy

const BLOCK_ATOL = 1e-7
const BLOCK_RTOL = 1e-7
const RATE_TOL = 1e-6

# Rebuild all blocks numerically, without using the Convex expression values.
function verify_synthesis(m, X, Y, U, t, r0, r1)
    Id = Matrix{Float64}(I, 3, 3)
    h = (m.dwell .- 3e-6) / m.ts
    H = Diagonal(1 ./ h) * m.D
    G0, G1 = m.A*X, m.A*X-m.B*Y
    blocks = Dict{String,Matrix{Float64}}(
        "X_floor" => X-1e-7*Id,
        "open_contraction" => [r0^2*X G0'; G0 X],
        "feedback_contraction" => [r1^2*X G1'; G1 X],
        "effort" => [U Y; Y' X])
    for j in 1:9
        w = H[j:j,:]*Y
        blocks["dwell_$j"] = [reshape([t],1,1) w; w' X]
    end
    minima = Dict(k=>eigmin(symmetric(b)) for (k,b) in blocks)
    tolerances = Dict(k=>BLOCK_ATOL+BLOCK_RTOL*opnorm(b) for (k,b) in blocks)
    reasons = String[]
    for k in sort!(collect(keys(blocks)))
        minima[k] >= -tolerances[k] || push!(reasons, "$k block residual")
    end
    trace_residual = abs(tr(X)-3)
    symmetry_residual = max(norm(X-X'),norm(U-U'))
    trace_residual <= 1e-6 || push!(reasons,"trace(X) residual")
    symmetry_residual <= 1e-8 || push!(reasons,"symmetry residual")
    eigX = eigmin(symmetric(X))
    eigX >= 1e-7-1e-9 || push!(reasons,"X positive-definiteness floor")
    check = Dict{String,Any}("block_min_eigenvalues"=>minima,
        "block_tolerances"=>tolerances,"trace_X_residual"=>trace_residual,
        "symmetry_residual"=>symmetry_residual,"min_eigenvalue_X"=>eigX,
        "condition_number_X"=>cond(X),"condition_number_U"=>cond(U),
        "rejection_reasons"=>reasons)
    if eigX <= 0
        check["accepted"] = false
        return (K=nothing,P=nothing,check=check)
    end
    K = Y / X
    P = Matrix(symmetric(X \ Id))
    check["condition_number_P_raw"] = cond(P)
    check["gain_recovery_residual"] = norm(K*X-Y)/max(1,norm(Y))
    check["inverse_recovery_residual"] = norm(P*X-Id)
    check["physical_gain_recovery_residual"] = norm((m.ts*K/m.S)*m.S/m.ts-K)/max(1,norm(K))
    # Generalized eigenvalues test the recovered rate in the P metric.
    matrices = (m.A,m.A-m.B*K)
    rates = (r0,r1)
    check["endpoint_rate_residuals"] = [eigmin(symmetric(r^2*P-M'*P*M))
                                         for (M,r) in zip(matrices,rates)]
    squared_rates = [maximum(eigvals(symmetric(M'*P*M),symmetric(P))) for M in matrices]
    check["recovered_squared_rates"] = squared_rates
    check["squared_rate_tolerance"] = RATE_TOL
    all(squared_rates .<= collect(rates).^2 .+ RATE_TOL) || push!(reasons,"recovered endpoint rate")
    check["gain_recovery_residual"] <= 1e-9 || push!(reasons,"gain recovery")
    check["inverse_recovery_residual"] <= 1e-6 || push!(reasons,"inverse recovery")
    check["physical_gain_recovery_residual"] <= 1e-10 || push!(reasons,"physical gain conversion")
    # These Schur complements bound K*X*K', not merely Y*Y'.
    effort = U-K*X*K'
    dwell_residuals = [t-only(H[j:j,:]*K*X*K'*H[j:j,:]') for j in 1:9]
    check["effort_schur_min_eigenvalue"] = eigmin(symmetric(effort))
    check["effort_schur_tolerance"] = BLOCK_ATOL+BLOCK_RTOL*max(opnorm(U),opnorm(K*X*K'))
    check["dwell_schur_residuals"] = dwell_residuals
    check["dwell_schur_tolerance"] = BLOCK_ATOL+BLOCK_RTOL*max(1,abs(t))
    check["effort_schur_min_eigenvalue"] >= -check["effort_schur_tolerance"] || push!(reasons,"recovered effort bound")
    minimum(dwell_residuals) >= -check["dwell_schur_tolerance"] || push!(reasons,"recovered dwell bound")
    accepted_P = nothing
    try
        c = certificate(m,K,P)
        accepted_P = c.P
        check["common_stability"] = c.check
        check["normalized_P_symmetry_residual"] = norm(c.P-c.P')
        check["normalized_P_trace_residual"] = abs(tr(c.P)-3)
    catch err
        err isa ErrorException || rethrow()
        push!(reasons,"common stability: "*sprint(showerror,err))
    end
    check["accepted"] = isempty(reasons)
    (K=K,P=accepted_P,check=check)
end

function regression_checks()
    m = load_model()
    fake = Model(.5*Matrix{Float64}(I,3,3),zeros(3,8),m.S,m.ts,m.anchor,
                 m.dwell,m.D,m.F,m.Kcurrent,m.Pcurrent,m.Kdecay,m.Pdecay)
    X, Y, U = Matrix{Float64}(I,3,3), zeros(8,3), Matrix{Float64}(I,8,8)
    @assert verify_synthesis(fake,X,Y,U,1.,.8,.7).check["accepted"]
    @assert !verify_synthesis(fake,X,Y,-U,1.,.8,.7).check["accepted"]
    @assert !verify_synthesis(fake,X,Y,U,-1.,.8,.7).check["accepted"]
    @assert !verify_synthesis(fake,X,Y,U,1.,.8,.1).check["accepted"]
    @assert !verify_synthesis(fake,2X,Y,U,1.,.8,.7).check["accepted"]
    @assert !verify_synthesis(fake,X,ones(8,3),U,0.,.8,.7).check["accepted"]
    println("strategy-3 regression checks passed: valid certificate and five corrupted cases")
end

function main()
    started = time()
    m = load_model()
    denominators = baseline_costs(m)
    seed = certificate(m,m.Kcurrent,m.Pcurrent)
    bestK, bestP = m.Kcurrent, seed.P
    bestscore = training_score(m,bestK,denominators)
    selected = "current-LQR-seed"
    selected_synthesis = nothing
    logs = Dict{String,Any}[Dict("candidate"=>selected,"status"=>"accepted_seed",
                               "score"=>bestscore,"certificate"=>seed.check)]
    counts = Dict("solver_calls"=>0,"candidate_count"=>1,"objective_evaluations"=>1,
        "accepted_synthesis_count"=>0,"certificate_rejections"=>0,
        "solver_reported_infeasible"=>0,"solver_failures"=>0,
        "solver_exceptions"=>0,"evaluation_failures"=>0,
        "setup_exceptions"=>0,"verification_exceptions"=>0)
    h = (m.dwell .- 3e-6)/m.ts
    @assert minimum(h)>0
    H = Diagonal(1 ./ h)*m.D
    for r0 in (.9999,.99999), r1 in (.25,.5,.8), lambda in (.01,.1)
        entry = Dict{String,Any}("candidate"=>"sdp-$(counts["solver_calls"]+1)",
                                "r0"=>r0,"r1"=>r1,"lambda"=>lambda)
        push!(logs,entry)
        counts["candidate_count"] += 1
        began = time()
        stage = "setup"
        try
            X, Y, U, t = Semidefinite(3), Variable(8,3), Semidefinite(8), Variable()
            Id = Matrix{Float64}(I,3,3)
            constraints = [tr(X)==3,X ⪰ 1e-7*Id,
                contraction_block(X,m.A*X,r0) ⪰ 0,
                contraction_block(X,m.A*X-m.B*Y,r1) ⪰ 0,
                [U Y; Y' X] ⪰ 0]
            for j in 1:9
                w = H[j:j,:]*Y
                push!(constraints,[t w; w' X] ⪰ 0)
            end
            problem = minimize(.001*tr(U)+lambda*t,constraints)
            counts["solver_calls"] += 1
            stage = "solver"
            solve!(problem,solver_factory; silent=true)
            status = string(problem.status)
            entry["solver_status"] = status
            entry["solve_elapsed_seconds"] = time()-began
            if status == "INFEASIBLE"
                entry["status"] = "solver_reported_infeasible"
                counts["solver_reported_infeasible"] += 1
                continue
            elseif !(status in ("OPTIMAL","ALMOST_OPTIMAL"))
                entry["status"] = "solver_failure"
                counts["solver_failures"] += 1
                continue
            end
            stage = "verification"
            x,y,u,tn = Matrix(evaluate(X)),Matrix(evaluate(Y)),Matrix(evaluate(U)),Float64(evaluate(t))
            raw = Dict("X"=>x,"Y"=>y,"U"=>u,"t"=>tn,"r0"=>r0,"r1"=>r1,"lambda"=>lambda)
            entry["synthesis"] = raw
            entry["synthesis_objective"] = .001*tr(u)+lambda*tn
            verified = verify_synthesis(m,x,y,u,tn,r0,r1)
            entry["verification"] = verified.check
            if !verified.check["accepted"]
                entry["status"] = "numerically_rejected"
                counts["certificate_rejections"] += 1
                continue
            end
            counts["accepted_synthesis_count"] += 1
            counts["objective_evaluations"] += 1
            score = try
                training_score(m,verified.K,denominators)
            catch err
                counts["evaluation_failures"] += 1
                entry["status"] = "evaluation_failure"
                entry["error"] = sprint(showerror,err)
                continue
            end
            entry["status"] = "accepted"
            entry["score"] = score
            if better(score,bestscore)
                bestK,bestP,bestscore = verified.K,verified.P,score
                selected = entry["candidate"]
                selected_synthesis = Dict("variables"=>raw,"verification"=>verified.check)
            end
        catch err
            counts[stage*"_exceptions"] += 1
            entry["status"] = stage*"_exception"
            entry["error"] = sprint(showerror,err)
        finally
            entry["elapsed_seconds"] = time()-began
        end
        println(entry["candidate"],": ",entry["status"])
    end
    @assert counts["solver_calls"] == 12
    write_result("strategy-3",m,bestK,bestP,bestscore,logs;
        description="Separate endpoint contraction targets with input and margin-normalized dwell effort minimization",
        parameters=Dict("r0_grid"=>[.9999,.99999],"r1_grid"=>[.25,.5,.8],
                        "lambda_grid"=>[.01,.1],"effort_weight"=>.001,
                        "block_atol"=>BLOCK_ATOL,"block_rtol"=>BLOCK_RTOL,
                        "squared_rate_tolerance"=>RATE_TOL),
        elapsed_seconds=time()-started,
        extra=Dict("counts"=>counts,"selected_candidate"=>selected,
            "status"=>selected=="current-LQR-seed" ? "unchanged_seed" : "improved_training_score",
            "termination_reason"=>"completed_all_12_SDP_settings",
            "training_denominators"=>denominators,"selected_synthesis"=>selected_synthesis,
            "certificate_scope"=>"Floating-point common-P check of the linearized conditioned family only"))
end

if abspath(PROGRAM_FILE) == @__FILE__
    if "--self-test" in ARGS
        regression_checks()
    else
        main()
    end
end
