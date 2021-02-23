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
    env_names = names(env)
    values = env_names |> Map(name -> initial_condition(getfield(env, name)))
    return (; zip(env_names, values)...)  # NamedTuple
end
