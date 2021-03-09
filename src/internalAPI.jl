## Internal API
# get names
"""
    names(env::Fym)

Get the symbols of sub-environments.

```jldoctest
# Examples
julia> using LazyFym
julia> struct Env1 <: Fym
       end

julia> struct Env2 <: Fym
       end

julia> struct Env3 <: Fym
       end

julia> struct Env12 <: Fym
           env1::Env1
           env2::Env2
       end

julia> struct Env12_3 <: Fym
           env12::Env12
           env3::Env3
       end

julia> env12_3 = Env12_3(Env12(Env1(), Env2()), Env3())
Env12_3(Env12(Env1(), Env2()), Env3())

julia> LazyFym.names(env12_3)
2-element Array{Symbol,1}:
 :env12
 :env3

julia> LazyFym.names(env12_3.env12)
2-element Array{Symbol,1}:
 :env1
 :env2
```
"""
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
        if env_size_nt == ()
            return _x[env_index_nt][1]  # scalar
        else
            return reshape(_x[env_index_nt], env_size_nt...)
        end
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

## test
function value end
macro myMacro(ex, mystruct)
    local tmp = ex.args[3]
    local valueExpr = :(LazyFym.value($mystruct))
    local multiplyExpr = Expr(:call, :*, tmp, valueExpr)
    ex.args[3] = multiplyExpr
    return esc(ex)
end

"""
It must be called in the global scope for method definition.
"""
macro register(env, x0)
    ex = quote
        if typeof($(env)) <: Fym
            local env_names = LazyFym.names($(env))
            LazyFym.names(env::typeof($(env))) = env_names
            local env_size = LazyFym.size($(env), $(x0))
            LazyFym.size(env::typeof($(env)), x0) = env_size
            local env_flatten_length = LazyFym.flatten_length($(env), $(x0))
            LazyFym.flatten_length(env::typeof($(env)), x0) = env_flatten_length
            local env_index = LazyFym.index($(env), $(x0), 1:env_flatten_length)
            LazyFym.index(env::typeof($(env)), x0, _range) = env_index
            local env_index_nt, env_size_nt = LazyFym.preprocess($(env), $(x0))
            LazyFym.preprocess(env::typeof($(env)), x0) = env_index_nt, env_size_nt
        else
            error("Invalid environment")
        end
    end
    esc(ex)
end
