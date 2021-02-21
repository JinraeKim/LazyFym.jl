module LazyFym

using Transducers

export FymSys
export FymEnv

export ∫
# export euler, rk4  # exporting them is deprecated

# export update, ẋ  # exporting them is deprecated

export Sim


## Types
abstract type FymSys end
abstract type FymEnv end

## numerical integration
# methods
function euler(_ẋ, x, t, Δt, args...; kwargs...)
    return x + Δt * _ẋ(x, t, args...; kwargs...)
end
function rk4(_ẋ, x, t, Δt, args...; kwargs...)
    k1 = _ẋ(x, t, args...; kwargs...)
    k2 = _ẋ(x + k1*(0.5*Δt), t + 0.5*Δt, args...; kwargs...)
    k3 = _ẋ(x + k2*(0.5*Δt), t + 0.5*Δt, args...; kwargs...)
    k4 = _ẋ(x + k3*Δt, t + Δt, args...; kwargs...)
    return x + (Δt/6)*sum([k1, k2, k3, k4] .* [1, 2, 2, 1])
end
# API
function ∫(env, ẋ, x, t, Δt, args...; integrator=rk4, kwargs...)
    sys_index_dict, sys_size_dict = preprocess(env, x)  # TODO
    _x = raw(x, sys_index_dict)
    _ẋ = function(_x, t, args...; kwargs...)
        x = process(_x, sys_index_dict, sys_size_dict)
        ẋ_evaluated = ẋ(env, x, t, args...; kwargs...)
        return ẋ_raw = raw(ẋ_evaluated, sys_index_dict)
    end
    _x_next = integrator(_ẋ, _x, t, Δt, args...; kwargs...)
    return process(_x_next, sys_index_dict, sys_size_dict)
end

## dynamics
# default (for test)
function ẋ(env::FymEnv, x::Dict, t)
    names = system_names(env)
    zero_values = names |> Map(name -> zero(x[name]))
    return zip(names, zero_values) |> Dict
end

## update
# default (for test)
function update(env::FymEnv, ẋ, x, t, Δt)  # provided
    datum = Dict(:state => x, :t => t)
    x_next = ∫(env, ẋ, x, t, Δt)
    return datum, x_next
end

## (internal) API
# get names
function system_names(env::FymEnv)
    return [name for name in fieldnames(typeof(env)) if typeof(getfield(env, name)) <: FymSys]
end
function preprocess(env::FymEnv, x0)
    sys_names = system_names(env)
    sys_sizes = sys_names |> Map(name -> size(x0[name]))
    sys_size_dict = zip(sys_names, sys_sizes) |> Dict
    sys_accumulated_lengths = sys_sizes |> Map(size -> prod(size)) |> Scan(+) |> collect
    sys_indices_tmp = [0, sys_accumulated_lengths...] |> Consecutive(length(sys_accumulated_lengths); step=1)
    sys_indices = zip(sys_indices_tmp...) |> MapSplat((x, y) -> x+1:y) |> collect
    sys_index_dict = zip(sys_names, sys_indices) |> Dict
    return sys_index_dict, sys_size_dict
end
# raw view
function raw(x, sys_index_dict)
    _x = length(vcat(values(sys_index_dict)...)) |> zeros
    for name in keys(sys_index_dict)
        _x[sys_index_dict[name]] = x[name][:]
    end
    return _x
end
# processed view
function process(_x, sys_index_dict, sys_size_dict)
    sys_names = keys(sys_size_dict) |> collect
    sys_values = foldxl(|>,
        [
         sys_names,
         Map(name -> reshape(_x[sys_index_dict[name]],
                             sys_size_dict[name]...)),
        ]
    )
    x = zip(sys_names, sys_values) |> Dict
    return x
end

## Simulator
# Transducers
_Step(env, x0, t0, ẋ, update) = ScanEmit((x0, t0)) do (x, t), t_next
    Δt = t_next - t
    datum, x_next = update(env, ẋ, x, t, Δt)
    return datum, (x_next, t_next)
end
# simulation
"""
# Example
using FPFym
using Transducers

struct Env <: FymEnv
    a
end

function ẋ(env::Env)
    return (x, t; b=1) -> -(env.a * b) * x
end

function update(env::Env, ẋ, x, t, Δt)
    datum = Dict(:x => x, :t => t)
    b = t < 0.1 ? 1 : -1
    x_next = ∫(env, ẋ, x, t, Δt; b=b)
    datum[:x_next] = x_next
    return datum, x_next
end

function is_terminated(datum)
    return datum[:t] < 0.5
end

env = Env(2.0)
t0 = 0.0
tf = 1.0
Δt = 0.01
ts = t0:Δt:tf
x0 = 1:3 |> collect
@time traj = Sim(env, x0, ts, ẋ, update) |> TakeWhile(is_terminated) |> collect
"""
Sim(env::FymEnv, x0, ts, ẋ, update) = foldxl(|>,
                                             [ts, Drop(1),
                                              _Step(env, x0, ts[1],
                                                    ẋ, update)])


end  # module
