# trajs -> NamedTuple
function evaluate(trajs)
    _trajs = trajs |> collect
    all_keys = union([keys(traj) for traj in _trajs]...)
    get_values(key) = [get(traj, key, missing) for traj in _trajs]
    # get_values(key) = vcat([get(traj, key, missing) for traj in _trajs]...)
    all_values = all_keys |> Map(get_values)
    return (; zip(all_keys, all_values)...)  # NamedTuple
end

# multiple trajs -> NamedTuple (NOTICE: applying `catevaluate` to trajs will give you concatenated NamedTuple)
function catevaluate(trajs)
    _trajs = trajs |> collect
    all_keys = union([keys(traj) for traj in _trajs]...)
    get_values(key) = vcat([get(traj, key, missing) for traj in _trajs]...)
    all_values = all_keys |> Map(get_values)
    return (; zip(all_keys, all_values)...)  # NamedTuple
end

# array in array -> array (the first dimension is added)
function sequentialise(data)
    return vcat([reshape(data[i], (1, size(data[i])...)) for i in 1:length(data)]...)
end
