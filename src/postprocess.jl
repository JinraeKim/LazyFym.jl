"""
    evaluate(trajs)

Convert an array of datum to a concatenated data.

# Examples
julia> using LazyFym

julia> evaluate([(; t=1, x=[1, 2, 3]), (; t=2, x=[2, 3, 4])])
(t = [1, 2], x = [[1, 2, 3], [2, 3, 4]])
"""
function evaluate(trajs)
    _trajs = trajs |> collect
    all_keys = union([keys(traj) for traj in _trajs]...)
    get_values(key) = [get(traj, key, missing) for traj in _trajs]
    all_values = all_keys |> Map(get_values)
    return (; zip(all_keys, all_values)...)  # NamedTuple
end

"""
    catevaluate(multiple_trajs)

Concatenate a collection of evaluated trajectories.
It is probably useful to concatenate the result of parallel simulation.
Applying `catevaluate` to a single trajectory or
`evaluate` to multiple trajectories would yield undesirable results.

# Examples
julia> using LazyFym

julia> catevaluate([(t = [1, 2], x = [[1, 2, 3], [2, 3, 4]]), (t = [3, 4], x = [[3, 4, 5], [4, 5, 6]])])
(t = [1, 2, 3, 4], x = [[1, 2, 3], [2, 3, 4], [3, 4, 5], [4, 5, 6]])

julia> catevaluate([(; t=1, x=[1, 2, 3]), (; t=2, x=[2, 3, 4])])
(t = [1, 2], x = [1, 2, 3, 2, 3, 4])

julia> evaluate([(t = [1, 2], x = [[1, 2, 3], [2, 3, 4]]), (t = [3, 4], x = [[3, 4, 5], [4, 5, 6]])])
(t = [[1, 2], [3, 4]], x = [[[1, 2, 3], [2, 3, 4]], [[3, 4, 5], [4, 5, 6]]])
"""
function catevaluate(multiple_trajs)
    _multiple_trajs = multiple_trajs |> collect
    all_keys = union([keys(trajs) for trajs in _multiple_trajs]...)
    get_values(key) = vcat([get(trajs, key, missing) for trajs in _multiple_trajs]...)
    all_values = all_keys |> Map(get_values)
    return (; zip(all_keys, all_values)...)  # NamedTuple
end

"""
    sequentialise(data)

Convert an array of arrays to a concatenated array throught the first dimension.

It would be useful when plotting figures using data obtained from Transducers.

# Examples
julia> using LazyFym

julia> sequentialise([[1, 2], [3, 4], [5, 6]])
3×2 Array{Int64,2}:
 1  2
 3  4
 5  6
"""
function sequentialise(data)
    return vcat([reshape(data[i], (1, size(data[i])...)) for i in 1:length(data)]...)
end
