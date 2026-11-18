using LinearAlgebra
if !isdefined(@__MODULE__, :GainStudy)
    include("common.jl")
end
using .GainStudy
if !isdefined(@__MODULE__, :ComparisonTiming)
    include("comparison_timing.jl")
end
using .ComparisonTiming

function simulate_marcolino(m,K,z0; cycles=100)
    nominal = vcat(0.0,cumsum(m.dwell))
    period = nominal[end]
    states = zeros(3,cycles+1)
    states[:,1] = m.anchor+m.S*z0
    errors = zeros(cycles+1)
    raw,applied = zeros(8,cycles),zeros(8,cycles)
    dwells,boundaries = zeros(9,cycles),zeros(10,cycles)
    clock,durations,extensions = zeros(cycles+1),zeros(cycles),zeros(cycles)
    changed,postponed = falses(cycles),zeros(Int,cycles)
    stage = zeros(cycles)
    for k in 1:cycles
        z = m.S \ (states[:,k]-m.anchor)
        errors[k] = norm(z)
        raw[:,k] = -m.ts*K*z
        actual = sequential_schedule(m,raw[:,k])
        requested = nominal+vcat(0.0,raw[:,k],0.0)
        boundaries[:,k] = actual
        applied[:,k] = actual[2:9]-nominal[2:9]
        dwells[:,k] = diff(actual)
        durations[k] = actual[end]
        extensions[k] = actual[end]-period
        clock[k+1] = clock[k]+durations[k]
        changed[k] = any(abs.(actual-requested).>1e-12)
        postponed[k] = count(x->x>1e-12,actual-requested)
        chi = vcat(states[:,k],1.0)
        for i in 1:9
            chi = exp(m.F[i]*dwells[i,k])*chi
        end
        all(isfinite,chi) && norm(chi[1:3])<1e6 || error("Nonfinite/unbounded Marcolino simulation")
        states[:,k+1] = chi[1:3]
        stage[k] = dot(z,z)+.001*sum(abs2,applied[:,k]/m.ts)
    end
    errors[end] = norm(m.S \ (states[:,end]-m.anchor))
    first,sustained = ComparisonTiming.crossings(errors)
    response = Dict{String,Any}("cost"=>sum(stage),"states"=>states,"errors"=>errors,
        "raw_offsets"=>raw,"applied_offsets"=>applied,"dwells"=>dwells,
        "applied_boundaries"=>boundaries,"beta"=>nothing,"stage_cost"=>stage,
        "first_cycle"=>first,"sustained_cycle"=>sustained,"final_error"=>errors[end],
        "minimum_dwell_us"=>minimum(dwells)*1e6,
        "minimum_raw_dwell_us"=>minimum(m.dwell .+ m.D*raw)*1e6,
        "minimum_beta"=>nothing,"conditioned_cycles"=>count(changed),
        "postponed_switches"=>postponed,"total_postponed_switches"=>sum(postponed),
        "cycle_sample_minimum_state"=>vec(minimum(states,dims=2)),
        "cycle_times"=>clock,"cycle_durations"=>durations,"terminal_extensions"=>extensions)
    add_time_metrics!(m,response; policy="marcolino")
end

function run_marcolino_reference()
    started = time()
    m = load_model()
    runs = [simulate_marcolino(m,m.Kcurrent,c.z) for c in training_cases(m)]
    costs = [r["cost"] for r in runs]
    ratios = costs ./ baseline_costs(m)
    score = (mean_ratio=sum(ratios)/6,worst_ratio=maximum(ratios),gain_norm=norm(m.Kcurrent),
             costs=costs,settling=[r["sustained_cycle"] for r in runs])
    old = joinpath(ROOT,"studies","s1-marcolino-conditioning-comparison")
    sources = [@__FILE__,joinpath(HERE,"comparison_timing.jl"),joinpath(HERE,"MARCOLINO.md"),
               joinpath(HERE,"common.jl"),joinpath(old,"sequential_dwell_condition.m"),
               joinpath(ROOT,"studies","s2-kawa-synthesis","results","synthesis.json")]
    for dir in (joinpath(old,"results"),joinpath(old,"results","error-scale-2x"),joinpath(old,"results","error-scale-3x"))
        push!(sources,joinpath(dir,"cycle_history.csv"))
    end
    result = Dict("name"=>"strategy-marcolino","description"=>"Current LQR with Marcolino sequential-delay conditioning",
        "policy"=>"marcolino","certificate_status"=>"not-covered-variable-period",
        "P"=>nothing,"certificate"=>nothing,"K"=>m.Kcurrent,"Kphysical"=>m.ts*m.Kcurrent/m.S,
        "training_score"=>score,"status"=>"reference-policy-no-gain-redesign",
        "candidate_log"=>Any[],"parameters"=>Dict("gain"=>"unchanged current LQR","minimum_dwell_us"=>3.0),
        "elapsed_seconds"=>time()-started,"solver_calls"=>0,"objective_evaluations"=>0,
        "source_sha256"=>source_hashes(sources),
        "scope"=>"No common-P coverage. Anchor-sampled cost uses different physical times; common-clock tracking is reported separately.")
    write_json(joinpath(HERE,"results","strategy-marcolino.json"),result)
    println("strategy-marcolino: current LQR gain reused; sequential-delay reference, no common-P claim")
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_marcolino_reference()
end
