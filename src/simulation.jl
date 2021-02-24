## Simulator
# Transducers
Step(env, x0, t0, ẋ, update, renderer) = ScanEmit((x0, t0)) do (x, t), t_next
    renderer == nothing ? nothing : ProgressMeter.next!(renderer)
    Δt = t_next - t
    datum, x_next = update(env, ẋ, x, t, Δt)
    return datum, (x_next, t_next)
end
 
# simulation (better for short simulation time)
function Sim(env::Fym, x0, ts, ẋ, update; rendering=false)
    renderer = rendering ? ProgressMeter.Progress(length(ts), 0.001, "") : nothing
    return ts |> Drop(1) |> Step(env, x0, ts[1], ẋ, update, renderer)
end
Sim(env::Fym, x0, ts, ẋ; rendering=false) = Sim(env::Fym, x0, ts, ẋ, update; rendering=rendering)  # default data structure
Sim(env::Fym, x0, ts; rendering=false) = Sim(env::Fym, x0, ts, ẋ, update; rendering=rendering)  # for test

# partitioned simulation (NOTICE: probably gonna be deprecated)
function PartitionedSim(trajs, x0, ts; horizon=1000)
    ts_length = ts |> collect |> length
    if ts_length < horizon
        error("Partition horizon should be less than the number of time instants")
    end
    # ex) trajs(x0, ts) = Sim(env, x0, ts, ẋ, update) |> TakeWhile(!is_terminated)
    split_sim(x0, ts0) = ScanEmit((x0, ts0)) do (x, ts), ts_next
        # data = trajs(x, ts) |> collect
        # x_next = data[end].x_next
        data = trajs(x, ts) |> collect
        if length(data) == 0
            data = missing
            x_next = x
        else
            x_next = data[end].x_next
        end
        return data, (x_next, ts_next)
    end
    ts_partitioned = ts |> Partition(horizon, step=horizon-1, flush=true) |> Map(copy)
    ts_partitioned_appended = [ts_partitioned..., missing]
    # _data = ts_partitioned_appended |> Drop(1) |> split_sim(x0, ts[1:horizon]) |> collect
    _data = ts_partitioned_appended |> Drop(1) |> split_sim(x0, ts[1:horizon]) |> Filter(!ismissing) |> collect
    data = vcat(_data...)
    return data
end
