using Test, LinearAlgebra
include("strategy-marcolino.jl")

function history_rows(path)
    lines = split(strip(read(path,String)),'\n')
    names = split(strip(lines[1]),',')
    [Dict(names .=> split(strip(line),',')) for line in lines[2:end]]
end

function test_marcolino()
    m = load_model()
    period = sum(m.dwell)
    nominal = vcat(0.0,cumsum(m.dwell))
    @testset "sequential rule and fixed-clock sampling" begin
        @test sequential_schedule(m,zeros(8))≈nominal atol=1e-14
        delayed = sequential_schedule(m,fill(100e-6,8))
        @test minimum(diff(delayed))>=3e-6-1e-12
        @test delayed[end]>period
        @test delayed[end]≈delayed[end-1]+3e-6 atol=1e-14
        @test reference_state(m,0.0)==m.anchor
        @test reference_state(m,period)==m.anchor
        @test reference_state(m,11*period)==m.anchor
        z = training_cases(m)[1].z
        fixed = add_time_metrics!(m,simulate(m,m.Kcurrent,z))
        @test fixed["clocked_errors"]==fixed["errors"]
        @test fixed["reference_errors"]==fixed["errors"]
        @test fixed["extended_cycles"]==0
        for k in (1,2,5,50,101)
            @test state_at_time(m,fixed,fixed["cycle_times"][k])≈fixed["states"][:,k] atol=1e-9
        end
        @test_throws ErrorException state_at_time(m,fixed,1.0)
    end
    maximum_error = 0.0
    @testset "reproduce historical MATLAB Marcolino trials" begin
        old = joinpath(ROOT,"studies","s1-marcolino-conditioning-comparison","results")
        z1 = training_cases(m)[1].z
        for scale in 1:3
            directory = scale==1 ? old : joinpath(old,"error-scale-$(scale)x")
            saved = history_rows(joinpath(directory,"cycle_history.csv"))
            r = simulate_marcolino(m,m.Kcurrent,scale*z1)
            clock = [parse(Float64,row["marcolino_time_ms"])/1e3 for row in saved]
            anchor_errors = [parse(Float64,row["marcolino_phase_reset_error"]) for row in saved]
            phase_errors = [parse(Float64,row["marcolino_global_phase_error"]) for row in saved]
            discrepancy = maximum(abs,r["reference_errors"]-phase_errors)
            maximum_error=max(maximum_error,discrepancy)
            @test maximum(abs,r["cycle_times"]-clock)<1e-11
            @test maximum(abs,r["errors"]-anchor_errors)<1e-9
            @test discrepancy<1e-9
            @test isnothing(r["beta"]) && isnothing(r["minimum_beta"])
            @test r["cycle_times"][end]>100*period
            @test minimum(r["dwells"])>=3e-6-1e-12
            @test r["clocked_times"][end]≈100*period atol=1e-14
            @test r["clocked_states"][:,1]≈r["states"][:,1] atol=1e-12
            for k in (1,2,5,101)
                @test state_at_time(m,r,r["cycle_times"][k])≈r["states"][:,k] atol=1e-9
            end
            if scale==1
                @test r["sustained_cycle"]==4
                @test isnothing(r["reference_sustained_cycle"])
                @test isnothing(r["clocked_sustained_sample"])
                @test r["final_reference_error"]>.05
            end
        end
    end
    println("Maximum historical Marcolino reference-error discrepancy: ",maximum_error)
end

if abspath(PROGRAM_FILE) == @__FILE__
    test_marcolino()
end
