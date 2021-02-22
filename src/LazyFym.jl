module LazyFym

using Transducers

# Types
export Fym
# convenient APIs
export ∫
export Sim
export evaluate, sequentialise
# for test
# export euler, rk4  # exporting them is deprecated
# export update, ẋ  # exporting them is deprecated


## Types
# environments
abstract type Fym end

## Numerical integration
# euler method
function euler(_ẋ, _x, t, Δt, args...; kwargs...)
    return _x + Δt * _ẋ(_x, t, args...; kwargs...)
end
# rk4 method
function rk4(_ẋ, _x, t, Δt, args...; kwargs...)
    k1 = _ẋ(_x, t, args...; kwargs...)
    k2 = _ẋ(_x + k1*(0.5*Δt), t + 0.5*Δt, args...; kwargs...)
    k3 = _ẋ(_x + k2*(0.5*Δt), t + 0.5*Δt, args...; kwargs...)
    k4 = _ẋ(_x + k3*Δt, t + Δt, args...; kwargs...)
    return _x + (Δt/6)*sum([k1, k2, k3, k4] .* [1, 2, 2, 1])
end
# API
function ∫(env, ẋ, x, t, Δt, args...; integrator=rk4, kwargs...)
    # TODO: preprocess data everytime may be bad for performance;
    # for now it is left as unresolved
    env_index_nt, env_size_nt = preprocess(env, x)
    _x = raw(env, x)
    _ẋ = function(_x, t, args...; kwargs...)
        x = process(_x, env_index_nt, env_size_nt)
        ẋ_evaluated = ẋ(env, x, t, args...; kwargs...)
        return ẋ_raw = raw(env, ẋ_evaluated)
    end
    _x_next = integrator(_ẋ, _x, t, Δt, args...; kwargs...)
    return process(_x_next, env_index_nt, env_size_nt)
end

## Simulator
# Transducers
Step(env, x0, t0, ẋ, update) = ScanEmit((x0, t0)) do (x, t), t_next
    Δt = t_next - t
    datum, x_next = update(env, ẋ, x, t, Δt)
    return datum, (x_next, t_next)
end
# simulation (better for short simulation time)
Sim(env::Fym, x0, ts, ẋ, update) = foldxl(|>, [ts, Drop(1), Step(env, x0, ts[1], ẋ, update)])
Sim(env::Fym, x0, ts, ẋ) = Sim(env::Fym, x0, ts, ẋ, update)  # default data structure
Sim(env::Fym, x0, ts) = Sim(env::Fym, x0, ts, ẋ, update)  # for test
# partitioned simulation (better for long simulation time)
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

## Convenient tools
# all-zero dynamics (for test)
function ẋ(env::Fym, x, t)
    env_names = names(env)
    if env_names == []
        return zero(x)
    else
        zero_values = env_names |> Map(name -> ẋ(getfield(env, name), x[name], t))
        return (; zip(env_names, zero_values)...)  # NamedTuple
    end
end
# default update (for test)
function update(env::Fym, ẋ, x, t, Δt)  # provided
    _datum = Dict(:x => x, :t => t)
    x_next = ∫(env, ẋ, x, t, Δt)
    _datum[:x_next] = x_next
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum, x_next
end
# automatic completion of initial condition
function initial_condition(env::Fym)
    env_names = LazyFym.names(env)
    values = env_names |> Map(name -> initial_condition(getfield(env, name)))
    return (; zip(env_names, values)...)  # NamedTuple
end
# trajs -> NamedTuple (may take a lot of time for long time span)
function evaluate(trajs)
    _trajs = trajs |> collect
    all_keys = union([keys(traj) for traj in _trajs]...)
    get_values(key) = [get(traj, key, missing) for traj in _trajs]
    all_values = all_keys |> Map(get_values)
    return (; zip(all_keys, all_values)...)  # NamedTuple
end
# array in array -> array (the first dimension is added)
function sequentialise(data)
    return vcat([reshape(data[i], (1, size(data[i])...)) for i in 1:length(data)]...)
end

## Internal API
# get names
function Base.names(env::Fym)
    return [name for name in fieldnames(typeof(env)) if typeof(getfield(env, name)) <: Fym]
end
function preprocess(env::Fym, x0)
    env_size_nt = size(env, x0)
    env_flatten_length = flatten_length(env, x0)
    env_index_nt = index(env, x0, 1:env_flatten_length)
    return env_index_nt, env_size_nt
end
# raw view
function raw(env, x)
    env_names = names(env)
    if env_names == []
        return x
    else
        _x = env_names |> MapCat(name -> raw(getfield(env, name), x[name])) |> collect
        return _x
    end
end
# processed view
function process(_x, env_index_nt, env_size_nt)
    if typeof(env_index_nt) <: AbstractRange
        return reshape(_x[env_index_nt], env_size_nt...)
    else
        index_names = keys(env_index_nt)
        processed_values = index_names |> Map(name -> process(_x, env_index_nt[name], env_size_nt[name]))
        return (; zip(index_names, processed_values)...)
    end
end
# size
function Base.size(env::Fym, x0)
    env_names = names(env)
    if env_names == []
        return size(x0)
    else
        env_sizes = env_names |> Map(name -> size(getfield(env, name), x0[name]))
        return (; zip(env_names, env_sizes)...)  # NamedTuple
    end
end
# flatten length
function flatten_length(env::Fym, x0)
    env_names = names(env)
    if env_names == []
        return prod(size(x0))
    else
        return env_names |> Map(name -> flatten_length(getfield(env, name), x0[name])) |> sum
    end
end
# index
function index(env::Fym, x0, _range)
    env_names = names(env)
    if env_names == []
        return _range
    else
        env_accumulated_flatten_lengths = env_names |> Map(name -> flatten_length(getfield(env, name), x0[name])) |> Scan(+) |> collect
        range_first = first(_range)
        env_ranges_tmp = (range_first-1) .+ [0, env_accumulated_flatten_lengths...] |> Consecutive(length(env_accumulated_flatten_lengths); step=1)
        env_ranges = zip(env_ranges_tmp...) |> MapSplat((x, y) -> x+1:y)
        env_indices = zip(env_names, env_ranges) |> MapSplat((name, range) -> index(getfield(env, name), x0[name], range))
        return (; zip(env_names, env_indices)...)  # NamedTuple
    end
end


end  # module
