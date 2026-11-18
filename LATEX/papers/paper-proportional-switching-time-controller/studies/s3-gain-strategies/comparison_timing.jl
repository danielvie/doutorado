module ComparisonTiming

using LinearAlgebra
using ..GainStudy
export sequential_schedule, state_in_cycle, reference_state, state_at_time, add_time_metrics!

function sequential_schedule(m,raw)
    length(raw)==8 && all(isfinite,raw) || error("Invalid raw timing request")
    nominal = vcat(0.0,cumsum(m.dwell))
    actual = zeros(10)
    for j in 2:9
        actual[j] = max(nominal[j]+raw[j-1],actual[j-1]+3e-6)
    end
    actual[end] = max(nominal[end],actual[end-1]+3e-6)
    minimum(diff(actual)) >= 3e-6-1e-12 || error("Sequential dwell violation")
    actual
end

function state_in_cycle(m,initial,dwell,elapsed)
    -1e-14 <= elapsed <= sum(dwell)+1e-12 || error("Time outside cycle")
    remaining = max(0.0,elapsed)
    chi = vcat(initial,1.0)
    for i in 1:9
        dt = min(remaining,dwell[i])
        dt > 0 && (chi=exp(m.F[i]*dt)*chi)
        remaining -= dt
        remaining <= 0 && break
    end
    chi[1:3]
end

function reference_state(m,time)
    period = sum(m.dwell)
    phase = mod(time,period)
    min(phase,period-phase)<1e-12 && return copy(m.anchor)
    state_in_cycle(m,m.anchor,m.dwell,phase)
end

function state_at_time(m,response,time)
    clock = response["cycle_times"]
    time >= -1e-14 && time <= clock[end]+1e-12 || error("Time outside saved trajectory")
    if time >= clock[end]-1e-14
        return copy(response["states"][:,end])
    end
    k = clamp(searchsortedlast(clock,time),1,length(clock)-1)
    state_in_cycle(m,response["states"][:,k],response["dwells"][:,k],max(0.0,time-clock[k]))
end

function crossings(errors)
    first = findfirst(x->x<.01,errors)
    lastbad = findlast(x->x>=.01,errors)
    first_sample = isnothing(first) ? nothing : first-1
    sustained = isnothing(lastbad) ? 0 : lastbad==length(errors) ? nothing : lastbad
    first_sample,sustained
end

function add_time_metrics!(m,response; policy="uniform")
    period = sum(m.dwell)
    n = length(response["errors"])-1
    grid = collect(0:n)*period
    if policy=="uniform"
        response["cycle_times"] = copy(grid)
        response["cycle_durations"] = fill(period,n)
        response["terminal_extensions"] = zeros(n)
        reference_errors = copy(response["errors"])
        clocked_states = copy(response["states"])
        clocked_errors = copy(response["errors"])
    elseif policy=="marcolino"
        reference_errors = [norm(m.S \ (response["states"][:,j]-reference_state(m,t)))
                            for (j,t) in enumerate(response["cycle_times"])]
        clocked_states = hcat([state_at_time(m,response,t) for t in grid]...)
        clocked_errors = vec(sqrt.(sum(abs2,m.S \ (clocked_states .- m.anchor),dims=1)))
    else
        error("Unknown conditioning policy: $policy")
    end
    times = response["cycle_times"]
    _,reference_sustained = crossings(reference_errors)
    clocked_first,clocked_sustained = crossings(clocked_errors)
    anchor_sustained = response["sustained_cycle"]
    merge!(response,Dict("policy"=>policy,"reference_errors"=>reference_errors,
        "reference_sustained_cycle"=>reference_sustained,
        "reference_sustained_time_ms"=>isnothing(reference_sustained) ? nothing : times[reference_sustained+1]*1e3,
        "final_reference_error"=>reference_errors[end],
        "anchor_sustained_time_ms"=>isnothing(anchor_sustained) ? nothing : times[anchor_sustained+1]*1e3,
        "extended_cycles"=>count(x->x>period+1e-12,response["cycle_durations"]),
        "maximum_cycle_duration_us"=>maximum(response["cycle_durations"])*1e6,
        "total_boundary_delay_us"=>(times[end]-n*period)*1e6,
        "clocked_times"=>grid,"clocked_states"=>clocked_states,"clocked_errors"=>clocked_errors,
        "clocked_first_sample"=>clocked_first,"clocked_sustained_sample"=>clocked_sustained,
        "clocked_sustained_time_ms"=>isnothing(clocked_sustained) ? nothing : grid[clocked_sustained+1]*1e3,
        "final_clocked_error"=>clocked_errors[end],
        "clocked_error_sum"=>sum(abs2,clocked_errors[1:end-1])))
    response
end

end
