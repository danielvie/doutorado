module GainStudy

using LinearAlgebra, Statistics, Convex, Clarabel, JSON3, SHA

export Model, load_model, training_cases, all_cases, simulate, training_score,
       baseline_costs, better, certificate, fixed_gain_certificate, solver_factory,
       symmetric, json_matrix, write_json, read_json, write_result, HERE, ROOT,
       json_value, file_hash, source_hashes, contraction_block, checked_lqr

const HERE = @__DIR__
const ROOT = normpath(joinpath(HERE, "..", ".."))
const LEGACY = joinpath(ROOT, "studies", "s2-kawa-synthesis", "results", "synthesis.json")
const SOLVER_OPTIONS = (tol_gap_abs=1e-9, tol_feas=1e-9, tol_gap_rel=1e-9, max_iter=500)
LinearAlgebra.BLAS.set_num_threads(1)

json_matrix(rows) = [Float64(rows[i][j]) for i in eachindex(rows), j in eachindex(rows[1])]
symmetric(A) = Symmetric((A + A') / 2)
read_json(path) = JSON3.read(read(path, String), Dict{String,Any})
json_value(x) = x
json_value(x::AbstractMatrix) = [collect(row) for row in eachrow(x)]
json_value(x::AbstractVector) = json_value.(x)
json_value(x::AbstractDict) = Dict(string(k)=>json_value(v) for (k,v) in x)
json_value(x::NamedTuple) = Dict(string(k)=>json_value(v) for (k,v) in pairs(x))
function write_json(path, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, json_value(value))
        println(io)
    end
end
file_hash(path) = bytes2hex(sha256(read(path)))
source_hashes(paths) = Dict(replace(relpath(p, ROOT), '\\'=>'/')=>file_hash(p) for p in paths)
solver_factory() = Clarabel.Optimizer(; SOLVER_OPTIONS...)
# Official PSD-variable/solve API: https://jump.dev/Convex.jl/stable/manual/types/
contraction_block(X, G, rate) = [rate^2 * X G'; G X]

struct Model
    A::Matrix{Float64}
    B::Matrix{Float64}
    S::Matrix{Float64}
    ts::Float64
    anchor::Vector{Float64}
    dwell::Vector{Float64}
    D::Matrix{Float64}
    F::Vector{Matrix{Float64}}
    Kcurrent::Matrix{Float64}
    Pcurrent::Matrix{Float64}
    Kdecay::Matrix{Float64}
    Pdecay::Matrix{Float64}
end

function load_model()
    saved = read_json(LEGACY)
    S = Matrix(Diagonal([10.0,20.0,1.0]))
    ts = 1e-5
    anchor = [9.9247,19.2928,0.9823]
    boundaries = Float64.(saved["boundaries_us"]) * 1e-6
    dwell = diff(boundaries)
    modes = (0,1,3,7,2,0,4,7,4)
    D = zeros(9,8)
    for j in 1:8
        D[j,j] = 1
        D[j+1,j] = -1
    end
    F = Matrix{Float64}[]
    transitions = Matrix{Float64}[]
    orbit = [vcat(anchor,1.0)]
    Phi = Matrix{Float64}(I,4,4)
    for (mode,d) in zip(modes,dwell)
        u1,u2,u3 = ((mode >> bit) & 1 for bit in (2,1,0))
        Ac = [0.0 0.0 (u2-u1)/40e-6;
              0.0 0.0 (u3-u2)/40e-6;
              (u1-u2)/0.01 (u2-u3)/0.01 -1000.0]
        f = zeros(4,4)
        f[1:3,1:3] = Ac
        f[3,4] = 30*u3/0.01
        push!(F,f)
        T = exp(f*d)
        push!(transitions,T)
        push!(orbit,T*orbit[end])
        Phi = T*Phi
    end
    Gamma = zeros(4,9)
    downstream = Matrix{Float64}(I,4,4)
    for i in 9:-1:1
        Gamma[:,i] = downstream * F[i] * orbit[i+1]
        downstream = downstream * transitions[i]
    end
    A = S \ (Phi[1:3,1:3]*S)
    B = S \ (Gamma[1:3,:]*D) * ts
    norm(A-json_matrix(saved["A"])) < 1e-11 || error("Reconstructed A mismatch")
    norm(B-json_matrix(saved["B"])) < 1e-11 || error("Reconstructed B mismatch")
    norm(orbit[end][1:3]-anchor,Inf) < 1e-10 || error("Reference does not close")
    Model(A,B,S,ts,anchor,dwell,D,F,
          json_matrix(saved["current"]["K"]),json_matrix(saved["current"]["P"]),
          json_matrix(saved["candidates"]["decay"]["K"]),
          json_matrix(saved["candidates"]["decay"]["P"]))
end

function training_cases(m)
    z1 = m.S \ ([7.5143,20.8211,0.0314]-m.anchor)
    zs = [z1,-z1,[-.2,-.1,-.4],[.2,.1,.4],[-.1,.15,.2],[.1,-.15,-.2]]
    [(name=i==1 ? "article-1x" : "train-$i",split="training",z=z) for (i,z) in enumerate(zs)]
end
function all_cases(m)
    cases = training_cases(m)
    zs = [[.15,0.,0.],[-.15,0.,0.],[0.,.15,0.],[0.,-.15,0.],
          [0.,0.,.5],[0.,0.,-.5],[.15,.15,.3],[-.15,-.15,-.3],
          [.15,-.15,.3],[-.15,.15,-.3],[.15,.15,-.3],[-.15,-.15,.3]]
    append!(cases,[(name="withheld-$i",split="withheld",z=z) for (i,z) in enumerate(zs)])
    z1 = cases[1].z
    append!(cases,[(name="article-$(i)x",split="historical-stress",z=i*z1) for i in (2,3)])
    cases
end

function simulate(m, K, z0; cycles=100)
    states = zeros(3,cycles+1)
    states[:,1] = m.anchor+m.S*z0
    errors = zeros(cycles+1)
    raw = zeros(8,cycles)
    applied = zeros(8,cycles)
    dwells = zeros(9,cycles)
    betas = ones(cycles)
    stage = zeros(cycles)
    for k in 1:cycles
        z = m.S \ (states[:,k]-m.anchor)
        errors[k] = norm(z)
        raw[:,k] = -m.ts * K*z
        q = m.D*raw[:,k]
        beta = 1.0
        for i in 1:9
            q[i] < 0 && (beta=min(beta,(m.dwell[i]-3e-6)/(-q[i])))
        end
        betas[k] = beta
        applied[:,k] = beta*raw[:,k]
        dwells[:,k] = m.dwell+m.D*applied[:,k]
        minimum(dwells[:,k]) >= 3e-6-1e-12 || error("Applied dwell violation")
        chi = vcat(states[:,k],1.0)
        for i in 1:9
            chi = exp(m.F[i]*dwells[i,k])*chi
        end
        states[:,k+1] = chi[1:3]
        all(isfinite,chi) && norm(chi[1:3]) < 1e6 || error("Nonfinite/unbounded simulation")
        stage[k] = dot(z,z) + .001*sum(abs2,applied[:,k]/m.ts)
    end
    errors[end] = norm(m.S \ (states[:,end]-m.anchor))
    first = findfirst(x->x<.01,errors)
    lastbad = findlast(x->x>=.01,errors)
    sustained = isnothing(lastbad) ? 0 : lastbad == length(errors) ? nothing : lastbad
    Dict{String,Any}("cost"=>sum(stage),"states"=>states,"errors"=>errors,
        "raw_offsets"=>raw,"applied_offsets"=>applied,"dwells"=>dwells,
        "beta"=>betas,"stage_cost"=>stage,
        "first_cycle"=>isnothing(first) ? nothing : first-1,
        "sustained_cycle"=>sustained,"final_error"=>errors[end],
        "minimum_dwell_us"=>minimum(dwells)*1e6,
        "minimum_raw_dwell_us"=>minimum(m.dwell .+ m.D*raw)*1e6,
        "minimum_beta"=>minimum(betas),"conditioned_cycles"=>count(x->x<1-1e-12,betas),
        "cycle_sample_minimum_state"=>vec(minimum(states,dims=2)))
end
baseline_costs(m) = [simulate(m,m.Kcurrent,c.z)["cost"] for c in training_cases(m)]
function training_score(m,K,denominators=baseline_costs(m))
    runs = [simulate(m,K,c.z) for c in training_cases(m)]
    costs = Float64[r["cost"] for r in runs]
    ratios = costs ./ denominators
    (mean_ratio=mean(ratios),worst_ratio=maximum(ratios),gain_norm=norm(K),
     costs=costs,settling=[r["sustained_cycle"] for r in runs])
end
function better(a,b)
    a.mean_ratio < b.mean_ratio-1e-10 && return true
    abs(a.mean_ratio-b.mean_ratio) > 1e-10 && return false
    a.worst_ratio < b.worst_ratio-1e-10 && return true
    abs(a.worst_ratio-b.worst_ratio) > 1e-10 && return false
    a.gain_norm < b.gain_norm-1e-10
end

function certificate(m,K,P; margin=1e-9)
    P = Matrix(symmetric(P))
    tr(P)>0 || error("Nonpositive trace")
    P *= 3/tr(P)
    eigP = eigmin(symmetric(P))
    decreases = [eigmin(symmetric(P-M'*P*M)) for M in (m.A,m.A-m.B*K)]
    eigP >= 1e-7-1e-10 && minimum(decreases)>margin || error("Certificate rejected")
    check = Dict("min_eigenvalue_P"=>eigP,"endpoint_decreases"=>decreases,
                 "trace_P"=>tr(P),"condition_number_P"=>cond(P),
                 "raw_radius"=>maximum(abs,eigvals(m.A-m.B*K)))
    (P=P,check=check)
end
function fixed_gain_certificate(m,K)
    n = 3
    Id = Matrix{Float64}(I,n,n)
    P,eta = Semidefinite(n),Variable()
    constraints = [tr(P)==3,P ⪰ 1e-7*Id]
    append!(constraints,[P-M'*P*M ⪰ eta*Id for M in (m.A,m.A-m.B*K)])
    problem = maximize(eta,constraints)
    solve!(problem,solver_factory; silent=true)
    status = string(problem.status)
    status in ("OPTIMAL","ALMOST_OPTIMAL") || return nothing
    p = evaluate(P)
    isnothing(p) && return nothing
    try
        c = certificate(m,K,p)
        (P=c.P,check=c.check,status=status,eta=Float64(evaluate(eta)))
    catch err
        err isa ErrorException || rethrow()
        nothing
    end
end

function checked_lqr(A,B,Q,R)
    H = copy(Q)
    K = zeros(size(B,2),size(A,1))
    converged = false
    for _ in 1:100000
        K = (R+B'*H*B) \ (B'*H*A)
        next = Matrix(symmetric(Q+A'*H*A-A'*H*B*K))
        if norm(next-H) <= 1e-12*max(1,norm(H))
            H = next
            converged = true
            break
        end
        H = next
    end
    converged || error("Riccati iteration did not converge")
    K = (R+B'*H*B) \ (B'*H*A)
    residual = H-Q-A'*H*A+A'*H*B*K
    norm(residual)/max(1,norm(H)) < 1e-10 || error("Riccati residual")
    eigmin(symmetric(H))>0 && maximum(abs,eigvals(A-B*K))<1 || error("Invalid LQR")
    K
end

function write_result(name,m,K,P,score,logs; description,parameters=Dict(),
                      elapsed_seconds=0.0,extra=Dict())
    c = certificate(m,K,P)
    source = joinpath(HERE,"$name.jl")
    result = Dict{String,Any}("name"=>name,"description"=>description,
        "K"=>K,"P"=>c.P,"Kphysical"=>m.ts*K/m.S,
        "certificate"=>c.check,"training_score"=>score,
        "parameters"=>parameters,"candidate_log"=>logs,
        "elapsed_seconds"=>elapsed_seconds,
        "runtime"=>Dict("julia"=>string(VERSION),"Convex"=>string(pkgversion(Convex)),
                        "Clarabel"=>string(pkgversion(Clarabel))),
        "source_sha256"=>source_hashes([source,joinpath(HERE,"common.jl"),
                                          joinpath(HERE,"SPEC.md"),LEGACY]))
    merge!(result,extra)
    write_json(joinpath(HERE,"results","$name.json"),result)
    println("$name: training ratio=",score.mean_ratio,
            ", minimum certificate decrease=",minimum(c.check["endpoint_decreases"]))
    result
end

end
