using Test, LinearAlgebra
include("common.jl")
using .GainStudy

function main()
    m = load_model()
    maximum_error = 0.0
    checks = Dict{String,Any}[]
    @testset "model, LQR and certificate contracts" begin
        K = checked_lqr(m.A,m.B,Matrix{Float64}(I,3,3),.001*Matrix{Float64}(I,8,8))
        @test norm(K-m.Kcurrent)/norm(m.Kcurrent) < 1e-7
        @test rank(m.B)==3
        for (K,P) in ((m.Kcurrent,m.Pcurrent),(m.Kdecay,m.Pdecay))
            c = certificate(m,K,P)
            @test minimum(c.check["endpoint_decreases"])>1e-9
            @test tr(c.P)≈3
        end
        @test_throws ErrorException certificate(m,m.Kcurrent,-Matrix{Float64}(I,3,3))
        @test_throws ErrorException certificate(m,-100*m.Kcurrent,m.Pcurrent)
        @test length(training_cases(m))==6
        @test length(all_cases(m))==20
        @test all(minimum(m.anchor+m.S*c.z)>0 for c in all_cases(m) if c.split!="historical-stress")
    end
    path = joinpath(ROOT,"studies","s2-kawa-synthesis","results","history.csv")
    lines = split(strip(read(path,String)),'\n')
    header = split(strip(lines[1]),',')
    col = Dict(name=>i for (i,name) in enumerate(header))
    rows = [split(strip(line),',') for line in lines[2:end]]
    z1 = training_cases(m)[1].z
    @testset "exact Julia reproduction of saved MATLAB baselines" begin
        for (method,K) in (("current",m.Kcurrent),("kawa_decay",m.Kdecay)), scale in 1:3
            selected = [r for r in rows if r[col["method"]]==method && parse(Int,r[col["error_scale"]])==scale]
            r = simulate(m,K,scale*z1)
            x = [parse(Float64,row[col[key]]) for key in ("vc1_v","vc2_v","il_a"), row in selected]
            errors = [parse(Float64,row[col["normalized_error"]]) for row in selected]
            cost = parse(Float64,selected[end][col["cumulative_cost"]])
            discrepancy = maximum(abs,r["states"]-x)
            maximum_error = max(maximum_error,discrepancy)
            @test discrepancy < 1e-9
            @test maximum(abs,r["errors"]-errors) < 1e-9
            @test abs(r["cost"]-cost) < 1e-8
            @test minimum(r["dwells"])>=3e-6-1e-12
            @test maximum(abs,vec(sum(r["dwells"],dims=1)).-286e-6)<1e-12
            push!(checks,Dict("method"=>method,"scale"=>scale,"cost"=>r["cost"],
                             "maximum_state_error"=>discrepancy))
        end
    end
    write_json(joinpath(HERE,"results","baseline_validation.json"),
        Dict("status"=>"passed","maximum_state_error"=>maximum_error,
             "checks"=>checks,"source_sha256"=>source_hashes([joinpath(HERE,"common.jl"),@__FILE__,path])))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
