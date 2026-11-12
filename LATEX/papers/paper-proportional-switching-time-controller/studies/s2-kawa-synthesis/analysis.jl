# Offline decay-rate synthesis for the saved normalized article cycle model.
# Run from the paper root: julia --project=studies/lyapunov studies/kawa-synthesis/analysis.jl
# Convex variables, PSD blocks, and constant feasibility objective:
# https://jump.dev/Convex.jl/stable/manual/types/
# Clarabel tolerance and iteration settings:
# https://clarabel.org/stable/api_settings/

using Convex, Clarabel, LinearAlgebra, JSON3, SHA

const HERE = @__DIR__
const ROOT = normpath(joinpath(HERE, "..", ".."))
const REPO_ROOT = normpath(joinpath(ROOT, "..", "..", ".."))
const SOLVER_OPTIONS = (tol_gap_abs = 1e-9, tol_feas = 1e-9,
                        tol_gap_rel = 1e-9, max_iter = 500)
const RATE_TOLERANCE = 1e-6
const INPUT_WEIGHT = 0.001

# JSON matrices have rows, not Julia's column-major linear indexing.
json_matrix(rows) = [Float64(rows[i][j]) for i in eachindex(rows), j in eachindex(rows[1])]
symmetric(A) = Symmetric((A + A') / 2)
contraction_block(X, G, rate) = [rate^2 * X G'; G X]

function check_certificate(A, B, K, P)
    P = Matrix(symmetric(P))
    endpoints = (A, A - B * K)
    decreases = [eigmin(symmetric(P - M' * P * M)) for M in endpoints]
    minimum_P = eigmin(symmetric(P))
    minimum_P > 0 && minimum(decreases) > 1e-9 ||
        error("Invalid common-P certificate: minimum_P=$minimum_P, decreases=$decreases")
    return Dict{String,Any}(
        "K" => K, "P" => P, "endpoint_decreases" => decreases,
        "min_eigenvalue_P" => minimum_P,
        "raw_radius" => maximum(abs, eigvals(endpoints[2])),
        "Pnorm_rates" => [sqrt(last(eigvals(symmetric(M' * P * M), symmetric(P))))
                          for M in endpoints],
        "gain_frobenius" => norm(K), "condition_number_P" => cond(P),
    )
end

function solve_decay_at_rate(A, B, rate)
    n, m = size(B)
    Id = Matrix{Float64}(I, n, n)
    X, Y = Semidefinite(n), Variable(m, n)
    constraints = [tr(X) == n, X ⪰ 1e-7 * Id]
    append!(constraints, [contraction_block(X, G, rate) ⪰ 0
                          for G in (A * X, A * X - B * Y)])
    problem = minimize(0, constraints)
    solver = () -> Clarabel.Optimizer(; SOLVER_OPTIONS...)
    solve!(problem, solver; silent = true)
    status = string(problem.status)
    record = Dict{String,Any}("rate" => rate, "status" => status, "accepted" => false)
    # OPTIMAL / ALMOST_OPTIMAL correspond to CVXPY optimal / optimal_inaccurate.
    status in ("OPTIMAL", "ALMOST_OPTIMAL") || return nothing, record
    x, y = Matrix(symmetric(evaluate(X))), evaluate(Y)
    all(isfinite, x) && all(isfinite, y) || return nothing, record
    minimum_X = eigmin(symmetric(x))
    minimum_X > 0 && minimum_X >= 1e-7 - 1e-9 && abs(tr(x) - n) < 1e-6 ||
        return nothing, record
    K = y / x
    result = try
        check_certificate(A, B, K, inv(x))
    catch err
        err isa ErrorException || rethrow()
        return nothing, record
    end
    P = result["P"]
    residuals = [eigmin(symmetric(rate^2 * P - M' * P * M)) for M in (A, A - B * K)]
    merge!(record, Dict("min_rate_residual" => minimum(residuals),
                        "min_eigenvalue_X" => minimum_X))
    minimum(residuals) > 1e-9 && maximum(result["Pnorm_rates"]) <= rate + 1e-10 ||
        return nothing, record
    record["accepted"] = true
    merge!(result, Dict("X" => x, "Y" => y, "rate" => rate,
                        "rate_residuals" => residuals, "solver_status" => status,
                        "trace_X" => tr(x)))
    return result, record
end

function zero_gain_certificate(A, rate)
    n = size(A, 1)
    Id = Matrix{Float64}(I, n, n)
    F = A / rate
    # P - F'PF = I, using vec(F'PF) = kron(F', F') vec(P).
    P = reshape((Matrix{Float64}(I, n * n, n * n) - kron(F', F')) \ vec(Id), n, n)
    P = Matrix(symmetric(P))
    P *= tr(inv(P)) / n
    residual = symmetric(rate^2 * P - A' * P * A)
    eigmin(symmetric(P)) > 0 && eigmin(residual) > 0 ||
        error("Zero-feedback counterexample certificate failed")
    return P, eigmin(residual)
end

function synthesize_decay(A, B)
    floor = maximum(abs, eigvals(A))
    low, high = floor, 1.0 - 1e-8
    best, first = solve_decay_at_rate(A, B, high)
    isnothing(best) && error("Initial decay-rate SDP failed independent checks")
    history = [first]
    while high - low > RATE_TOLERANCE
        rate = (low + high) / 2
        candidate, record = solve_decay_at_rate(A, B, rate)
        push!(history, record)
        if isnothing(candidate)
            low = rate
        else
            high, best = rate, candidate
        end
    end
    # K=0 is an equally good limiting design, certified separately.
    _, zero_residual = zero_gain_certificate(A, high)
    merge!(best, Dict(
        "objective" => "minimum full-interval contraction; solver-selected feasible gain",
        "analytical_rate_floor" => floor, "bisection_lower" => low,
        "bisection_upper" => high, "bisection_tolerance" => RATE_TOLERANCE,
        "bisection_history" => history, "zero_gain_same_rate_feasible" => true,
        "zero_gain_min_rate_residual" => zero_residual,
        "gain_selection" => "CLARABEL pure-feasibility point, no secondary performance objective",
    ))
    return best
end

json_value(value) = value
json_value(value::AbstractMatrix) = [collect(row) for row in eachrow(value)]
json_value(value::AbstractVector) = json_value.(value)
json_value(value::AbstractDict) = Dict(k => json_value(v) for (k, v) in value)
json_value(value::NamedTuple) = map(json_value, value)

function main(; output_dir = joinpath(@__DIR__, "results"))
    lyapunov_dir = joinpath(ROOT, "studies", "lyapunov")
    source = joinpath(lyapunov_dir, "results", "certificate.json")
    julia_path = joinpath(lyapunov_dir, "results", "lyapunov_analysis_julia_certificate.json")
    saved = JSON3.read(read(source, String))
    julia = JSON3.read(read(julia_path, String))
    A, B, K = (json_matrix(saved[name]) for name in (:A0, :B, :K))
    S, ts = json_matrix(saved.S), Float64(saved.ts)
    norm(A - B * K - json_matrix(saved.A1)) <= 1e-12 ||
        error("Saved model and current gain are inconsistent")
    current = check_certificate(A, B, K, json_matrix(julia.P))
    decay = synthesize_decay(A, B)
    for candidate in (current, decay)
        candidate["Kphysical"] = ts * candidate["K"] / S
    end
    sources = [source, julia_path, @__FILE__,
               joinpath(lyapunov_dir, "Project.toml"), joinpath(lyapunov_dir, "Manifest.toml"),
               joinpath(ROOT, "scripts", "+paper", "benchmark.m"),
               joinpath(ROOT, "scripts", "+paper", "design_feedback.m"),
               joinpath(ROOT, "scripts", "condition_dwell_times.m"),
               joinpath(ROOT, "studies", "mpc-comparison", "mpc_problem.m"),
               joinpath(REPO_ROOT, "simulations", "matlab-sim", "+Mpc", "build_problem.m"),
               joinpath(REPO_ROOT, "simulations", "matlab-sim", "+Mpc", "solve.m")]
    result = Dict(
        "A" => A, "B" => B, "K_current" => K, "P_current" => current["P"],
        "current" => current, "state_scale" => S, "timing_scale" => ts,
        "boundaries_us" => saved.boundaries_us, "input_weight" => INPUT_WEIGHT,
        "candidates" => Dict("decay" => decay),
        "solver" => (interface = "Convex.jl", solver = "Clarabel",
                     options = merge((solver = "CLARABEL",), SOLVER_OPTIONS),
                     julia = string(VERSION), convex = string(pkgversion(Convex)),
                     clarabel = string(pkgversion(Clarabel)),
                     json3 = string(pkgversion(JSON3)), platform = Sys.MACHINE),
        "source_sha256" => Dict(replace(relpath(path, REPO_ROOT), '\\' => '/') =>
                                bytes2hex(sha256(read(path))) for path in sources),
        "limitations" => ["floating-point certificates, not interval verification",
                          "linearized stability only; no nonlinear attraction or hardware guarantee",
                          "the original objective does not uniquely select a useful gain"],
    )
    mkpath(output_dir)
    output_path = joinpath(output_dir, "synthesis.json")
    open(output_path, "w") do io
        JSON3.pretty(io, json_value(result))
        println(io)
    end
    open(joinpath(output_dir, "gains_normalized.csv"), "w") do io
        println(io, "method,switching_instant,k_z1,k_z2,k_z3")
        for (name, candidate) in (("current", current), ("kawa_decay", decay))
            for (i, row) in enumerate(eachrow(candidate["K"]))
                println(io, join((name, i, row...), ','))
            end
        end
    end
    println("Open-loop spectral radius: ", decay["analytical_rate_floor"])
    println("Decay-rate bracket: [", decay["bisection_lower"], ", ", decay["bisection_upper"], "]")
    for (name, candidate) in (("current", current), ("decay", decay))
        println(name, ": raw radius=", candidate["raw_radius"],
                ", gain norm=", candidate["gain_frobenius"],
                ", endpoint decrease=", candidate["endpoint_decreases"])
    end
    println("Saved ", normpath(output_path))
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
