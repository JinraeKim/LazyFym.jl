## Numerical integration
"""
    euler(_ẋ, _x, t, Δt, args...; kwargs...)

Calculate the next state using Euler method.
`args` and `kwargs` are regarded as constant within the time step.
"""
function euler(_ẋ, _x, t, Δt, args...; kwargs...)
    return _x + Δt * _ẋ(_x, t, args...; kwargs...)
end
"""
    rk4(_ẋ, _x, t, Δt, args...; kwargs...)

Calculate the next state using Runge-Kutta 4th method.
`args` and `kwargs` are regarded as constant within the time step.
"""
function rk4(_ẋ, _x, t, Δt, args...; kwargs...)
    k1 = _ẋ(_x, t, args...; kwargs...)
    k2 = _ẋ(_x + k1*(0.5*Δt), t + 0.5*Δt, args...; kwargs...)
    k3 = _ẋ(_x + k2*(0.5*Δt), t + 0.5*Δt, args...; kwargs...)
    k4 = _ẋ(_x + k3*Δt, t + Δt, args...; kwargs...)
    return _x + (Δt/6)*sum([k1, k2, k3, k4] .* [1, 2, 2, 1])
end
"""
    ∫(env, ẋ, x, t, Δt, args...; integrator=method, kwargs...)

Perform numerical integration using `method`.
"""
function ∫(env, ẋ, x, t, Δt, args...; integrator=rk4, kwargs...)
    # preprocess data everytime may be bad for performance;
    # to improve the simulation speed, you should extend LazyFym functions
    # such as LazyFym.size
    env_index_nt, env_size_nt = preprocess(env, x)
    _x = raw(env, x)
    _ẋ = function(_x, t, args...; kwargs...)
        x = process(_x, env_index_nt, env_size_nt)
        ẋ_evaluated = ẋ(env, x, t, args...; kwargs...)
        return ẋ_raw = raw(env, ẋ_evaluated)
    end
    _x_next = integrator(_ẋ, _x, t, Δt, args...; kwargs...)
    process(_x_next, env_index_nt, env_size_nt)
end
