## Convenient tools
# all-zero dynamics (for test)
function ẋ(env::Fym, x, t)
    println("all-zero dynamics for test; see `LazyFym.ẋ`")
    env_names = names(env)
    if env_names == []
        return zero(x)
    else
        zero_values = env_names |> Map(name -> ẋ(getfield(env, name), x[name], t))
        return (; zip(env_names, zero_values)...)  # NamedTuple
    end
end

# default update (for test)
"""
    update(env::Fym, ẋ, x, t, Δt)

Update law of a simulator.
You may have to customise this function to realise high-level agent
such as zero-order-hold (ZOH) input.
# Examples
function update(rlenv::RLEnv, ẋ, x, t, Δt)
    action = command(rlenv.policy, x.env, t)
    _datum = Dict(:x => x, :t => t, :action => action)
    x_next = ∫(rlenv, ẋ, x, t, Δt; action=action)  # `action` will be a kwarg of ẋ
    _datum[:x_next] = x_next
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum, x_next
end
"""
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
