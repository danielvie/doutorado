# Same common-P SDP as Python, expressed with Convex.jl.
# A0 and A1 come from the Python builder's physical converter reconstruction.
# Latest Lyapunov analysis. From the paper root: task lyapunov
# Or from this directory: julia --project=. analysis.jl
# See README.md for the model source, checks, and manuscript integration boundary.

using Convex, Clarabel, LinearAlgebra, JSON3

function solve_common_lyapunov(A0, A1)
    n = size(A0, 1)
    Id = Matrix{Float64}(I, n, n)
    P = Semidefinite(n)
    η = Variable()

    problem = maximize(η, [
        tr(P) == n,
        P ⪰ 1e-7 * Id,
        P - A0' * P * A0 ⪰ η * Id,
        P - A1' * P * A1 ⪰ η * Id,
    ])

    solver = () -> Clarabel.Optimizer(
        tol_gap_abs = 1e-11,
        tol_feas = 1e-11,
        tol_gap_rel = 1e-11,
        max_iter = 300,
    )
    solve!(problem, solver; silent = true)
    string(problem.status) == "OPTIMAL" || error("Solver status: $(problem.status)")
    return evaluate(P), evaluate(η), string(problem.status)
end

# JSON stores matrices as rows. Preserve that ordering when loading into Julia.
json_matrix(rows) = [Float64(rows[i][j]) for i in eachindex(rows), j in eachindex(rows[1])]
symmetric(A) = Symmetric((A + A') / 2)

function main()
    output_dir = joinpath(@__DIR__, "results")
    input_path = joinpath(output_dir, "certificate.json")
    isfile(input_path) || error("Run task lyapunov:python first: $input_path is missing")
    python = JSON3.read(read(input_path, String))
    A0, A1 = json_matrix(python.A0), json_matrix(python.A1)

    P, η, status = solve_common_lyapunov(A0, A1)
    P = Matrix(symmetric(P))
    eigP = eigvals(symmetric(P))
    eigQs = [eigvals(symmetric(P - A' * P * A)) for A in (A0, A1)]
    q = minimum(first.(eigQs))
    @assert first(eigP) > 0 "P is not positive definite"
    @assert q > 1e-9 "An endpoint fails strict Lyapunov decrease"
    @assert abs(tr(P) - size(P, 1)) < 1e-6 "Trace normalization failed"

    # Compare objectives, not exact P entries: the optimizer need not be unique.
    η_error = abs(η - python.eta) / abs(python.eta)
    P_error = norm(P - json_matrix(python.P)) / norm(json_matrix(python.P))
    @assert η_error < 1e-3 "Julia and Python objectives differ by more than 0.1%"

    result = (
        solver = (interface = "Convex.jl", solver = "Clarabel", status = status,
                  julia = string(VERSION), convex = string(pkgversion(Convex)),
                  clarabel = string(pkgversion(Clarabel))),
        input = "certificate.json: A0 and A1, normalized physical-error dynamics",
        P = collect(eachrow(P)), eta = η, eigP = eigP, eigQs = eigQs,
        q = q, rho_bound = sqrt(1 - q / last(eigP)),
        python_comparison = (eta_relative_error = η_error, P_relative_error = P_error),
    )
    output_path = joinpath(output_dir, "lyapunov_analysis_julia_certificate.json")
    open(output_path, "w") do io
        JSON3.pretty(io, result)
    end

    println("Convex.jl / Clarabel: ", status)
    println("P =")
    show(stdout, "text/plain", P)
    println("\nη = ", η, "\nminimum endpoint decrease = ", q)
    println("Objective relative difference from Python = ", η_error)
    println("Written: ", normpath(output_path))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
