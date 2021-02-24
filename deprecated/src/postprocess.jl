"""
    trajectory(trajs)

Convert an array of datum to a concatenated NamedTuple data.

# Examples
```jldoctest
julia> using LazyFym

julia> trajectory([(; t=1, x=[1, 2, 3]), (; t=2, x=[2, 3, 4])])
(t = [1, 2], x = [[1, 2, 3], [2, 3, 4]])
```
"""
function trajectory(trajs)
    _trajs = trajs |> collect
    all_keys = union([keys(traj) for traj in _trajs]...)
    get_values(key) = [get(traj, key, missing) for traj in _trajs]
    all_values = all_keys |> Map(get_values)
    return (; zip(all_keys, all_values)...)  # NamedTuple
end

"""
    catTrajectory(multiple_trajs)

Concatenate a collection of evaluated trajectories.
It is probably useful to concatenate the result of parallel simulation.
Applying `catTrajectory` to a single trajectory or
`evaluate` to multiple trajectories would yield undesirable results.

# Examples
```jldoctest
julia> using LazyFym

julia> catTrajectory([(t = [1, 2], x = [[1, 2, 3], [2, 3, 4]]), (t = [3, 4], x = [[3, 4, 5], [4, 5, 6]])])
(t = [1, 2, 3, 4], x = [[1, 2, 3], [2, 3, 4], [3, 4, 5], [4, 5, 6]])

julia> catTrajectory([(; t=1, x=[1, 2, 3]), (; t=2, x=[2, 3, 4])])
(t = [1, 2], x = [1, 2, 3, 2, 3, 4])

julia> evaluate([(t = [1, 2], x = [[1, 2, 3], [2, 3, 4]]), (t = [3, 4], x = [[3, 4, 5], [4, 5, 6]])])
(t = [[1, 2], [3, 4]], x = [[[1, 2, 3], [2, 3, 4]], [[3, 4, 5], [4, 5, 6]]])
```
"""
function catTrajectory(multiple_trajs)
    _multiple_trajs = multiple_trajs |> collect
    all_keys = union([keys(trajs) for trajs in _multiple_trajs]...)
    get_values(key) = vcat([get(trajs, key, missing) for trajs in _multiple_trajs]...)
    all_values = all_keys |> Map(get_values)
    return (; zip(all_keys, all_values)...)  # NamedTuple
end
