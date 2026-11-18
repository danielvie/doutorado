using LinearAlgebra, Statistics
include("common.jl")
using .GainStudy
include("comparison_timing.jl")
using .ComparisonTiming
include("strategy-marcolino.jl")

function csv_rows(path)
    lines = split(strip(read(path,String)),'\n')
    names = split(strip(lines[1]),',')
    [Dict(names .=> split(strip(line),',')) for line in lines[2:end]]
end

function main()
    m = load_model()
    cases = all_cases(m)
    denominators = baseline_costs(m)
    methods = Dict{String,Any}[]
    for (name,description,K,P) in (("current-lqr","Current article LQR",m.Kcurrent,m.Pcurrent),
                                  ("saved-common-p","Saved Python Common-P gain",m.Kdecay,m.Pdecay))
        c = certificate(m,K,P)
        push!(methods,Dict("name"=>name,"description"=>description,"K"=>K,"P"=>c.P,
                          "Kphysical"=>m.ts*K/m.S,"certificate"=>c.check,
                          "training_score"=>training_score(m,K,denominators)))
    end
    result_paths = [joinpath(HERE,"results","strategy-$i.json") for i in 1:5]
    for path in result_paths
        result = read_json(path)
        for (relative,digest) in result["source_sha256"]
            file_hash(normpath(joinpath(ROOT,relative)))==digest || error("Stale source: $relative")
        end
        K,P = json_matrix(result["K"]),json_matrix(result["P"])
        c = certificate(m,K,P)
        score = training_score(m,K,denominators)
        abs(score.mean_ratio-result["training_score"]["mean_ratio"])<1e-10 || error("Stale training score")
        push!(methods,Dict("name"=>result["name"],"description"=>result["description"],
            "K"=>K,"P"=>c.P,"Kphysical"=>m.ts*K/m.S,"certificate"=>c.check,
            "training_score"=>score,"elapsed_seconds"=>result["elapsed_seconds"]))
    end
    for method in methods
        method["policy"] = "uniform"
        method["certificate_status"] = "verified-conditioned-linearized"
    end
    marcolino_path = joinpath(HERE,"results","strategy-marcolino.json")
    marcolino = read_json(marcolino_path)
    for (relative,digest) in marcolino["source_sha256"]
        file_hash(normpath(joinpath(ROOT,relative)))==digest || error("Stale Marcolino source: $relative")
    end
    marcolino["policy"]=="marcolino" && isnothing(marcolino["P"]) && isnothing(marcolino["certificate"]) || error("Invalid Marcolino coverage label")
    norm(json_matrix(marcolino["K"])-m.Kcurrent)<1e-12 || error("Marcolino gain was changed")
    marcolino["K"] = json_matrix(marcolino["K"])
    push!(methods,marcolino)
    responses = Dict{String,Any}[]
    for method in methods, case in cases
        response = method["policy"]=="marcolino" ? simulate_marcolino(m,method["K"],case.z) :
                   add_time_metrics!(m,simulate(m,method["K"],case.z))
        merge!(response,Dict("method"=>method["name"],"case"=>case.name,"split"=>case.split))
        push!(responses,response)
    end
    baseline = Dict(r["case"]=>r["cost"] for r in responses if r["method"]=="current-lqr")
    clocked_baseline = Dict(r["case"]=>r["clocked_error_sum"] for r in responses if r["method"]=="current-lqr")
    for r in responses
        r["cost_ratio_lqr"] = r["cost"]/baseline[r["case"]]
        r["clocked_error_ratio_lqr"] = r["clocked_error_sum"]/clocked_baseline[r["case"]]
    end
    summaries = Dict{String,Any}[]
    for method in methods, split in ("training","withheld","historical-stress")
        rs = filter(r->r["method"]==method["name"] && r["split"]==split,responses)
        ratios = [r["cost_ratio_lqr"] for r in rs]
        clocked_ratios = [r["clocked_error_ratio_lqr"] for r in rs]
        clocked_times = [r["clocked_sustained_time_ms"] for r in rs]
        settled = all(!isnothing(t) for t in clocked_times)
        push!(summaries,Dict("method"=>method["name"],"split"=>split,"cases"=>length(rs),
            "mean_cost_ratio_lqr"=>mean(ratios),"worst_cost_ratio_lqr"=>maximum(ratios),
            "best_cost_ratio_lqr"=>minimum(ratios),
            "cost_regressions"=>count(x->x>1+1e-8,ratios),
            "mean_sustained_cycle"=>all(!isnothing(r["sustained_cycle"]) for r in rs) ? mean([r["sustained_cycle"] for r in rs]) : nothing,
            "worst_sustained_cycle"=>all(!isnothing(r["sustained_cycle"]) for r in rs) ? maximum([r["sustained_cycle"] for r in rs]) : nothing,
            "mean_clocked_error_ratio_lqr"=>mean(clocked_ratios),
            "worst_clocked_error_ratio_lqr"=>maximum(clocked_ratios),
            "clocked_error_regressions"=>count(x->x>1+1e-8,clocked_ratios),
            "mean_clocked_sustained_time_ms"=>settled ? mean(clocked_times) : nothing,
            "worst_clocked_sustained_time_ms"=>settled ? maximum(clocked_times) : nothing,
            "clocked_unsettled_cases"=>count(isnothing,clocked_times),
            "maximum_final_reference_error"=>maximum(r["final_reference_error"] for r in rs)))
    end
    old = joinpath(ROOT,"studies","s2-kawa-synthesis","results")
    mpc = Dict{String,Any}[]
    oldhistory = csv_rows(joinpath(old,"history.csv"))
    for row in csv_rows(joinpath(old,"summary.csv"))
        row["method"]=="mpc5" || continue
        scale = parse(Int,row["error_scale"])
        history = filter(r->r["method"]=="mpc5" && parse(Int,r["error_scale"])==scale,oldhistory)
        push!(mpc,Dict("case"=>"article-$(scale)x","cost"=>parse(Float64,row["evaluation_cost"]),
            "first_cycle"=>parse(Int,row["first_cycle_below_001"]),
            "sustained_cycle"=>parse(Int,row["sustained_cycle_below_001"]),
            "minimum_dwell_us"=>parse(Float64,row["minimum_dwell_us"]),
            "errors"=>[parse(Float64,r["normalized_error"]) for r in history],
            "cumulative_cost"=>[parse(Float64,r["cumulative_cost"]) for r in history]))
    end
    sources = [joinpath(HERE,"common.jl"),@__FILE__,joinpath(HERE,"SPEC.md"),
               joinpath(HERE,"results","baseline_validation.json"),
               joinpath(old,"synthesis.json"),joinpath(old,"summary.csv"),joinpath(old,"history.csv")]
    append!(sources,result_paths)
    append!(sources,[joinpath(HERE,"strategy-$i.jl") for i in 1:5])
    append!(sources,[marcolino_path,joinpath(HERE,"strategy-marcolino.jl"),
                     joinpath(HERE,"comparison_timing.jl"),joinpath(HERE,"MARCOLINO.md")])
    append!(sources,[normpath(joinpath(ROOT,relative)) for relative in keys(marcolino["source_sha256"])])
    comparison = Dict("model"=>Dict("A"=>m.A,"B"=>m.B,"S"=>m.S,"timing_scale"=>m.ts,
        "anchor"=>m.anchor,"nominal_dwell"=>m.dwell,"D"=>m.D,"generators"=>m.F),
        "cases"=>cases,"methods"=>methods,"responses"=>responses,"summaries"=>summaries,
        "historical_mpc"=>mpc,"source_sha256"=>source_hashes(sources),
        "scope"=>"Seven fixed-period gains have conditioned-linearized common-P checks. Marcolino is an uncovered variable-period reference. Anchor costs are not common-clock costs.")
    write_json(joinpath(HERE,"results","comparison.json"),comparison)
    fields = ["method","case","split","cost","cost_ratio_lqr","first_cycle","sustained_cycle",
              "final_error","minimum_dwell_us","minimum_raw_dwell_us","minimum_beta","conditioned_cycles",
              "anchor_sustained_time_ms","reference_sustained_time_ms","final_reference_error",
              "clocked_error_sum","clocked_error_ratio_lqr","clocked_sustained_time_ms","final_clocked_error",
              "extended_cycles","maximum_cycle_duration_us","total_boundary_delay_us"]
    open(joinpath(HERE,"results","metrics.csv"),"w") do io
        println(io,join(fields,','))
        for r in responses
            println(io,join([isnothing(r[k]) ? "" : string(r[k]) for k in fields],','))
        end
    end
    fields = ["method","split","cases","mean_cost_ratio_lqr","worst_cost_ratio_lqr",
              "best_cost_ratio_lqr","cost_regressions","mean_sustained_cycle","worst_sustained_cycle",
              "mean_clocked_error_ratio_lqr","worst_clocked_error_ratio_lqr","clocked_error_regressions",
              "mean_clocked_sustained_time_ms","worst_clocked_sustained_time_ms","clocked_unsettled_cases",
              "maximum_final_reference_error"]
    open(joinpath(HERE,"results","summary.csv"),"w") do io
        println(io,join(fields,','))
        for r in summaries
            println(io,join([isnothing(r[k]) ? "" : string(r[k]) for k in fields],','))
        end
    end
    println("Evaluated ",length(methods)," frozen controller policies on ",length(cases)," cases: ",length(responses)*100," exact cycles.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
