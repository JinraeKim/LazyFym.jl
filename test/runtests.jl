using LazyFym
using Test
using Transducers

using LinearAlgebra


# systems
struct Sys1 <: FymEnv
    a
end
struct Sys2 <: FymEnv
    b
end
# environments
struct Env <: FymEnv
    sys1::Sys1
    sys2::Sys2
end
# dynamics
function ẋ(env::Env, x, t; c=1)
    x1 = x.sys1  # x will be given as NamedTuple
    x2 = x.sys2
    ẋ1 = -(env.sys1.a * c) * x1
    ẋ2 = -(env.sys2.b * c) * x2
    return (; zip([:sys1, :sys2], [ẋ1, ẋ2])...)  # NamedTuple; Dict will also work
end
# update rule within each time step
function update(env::Env, ẋ, x, t, Δt)
    _datum = Dict(:x1 => x.sys1, :x2 => x.sys2, :t => t)
    c = gain(t)
    x_next = ∫(env, ẋ, x, t, Δt; c=c)  # default method: RK4
    # Recording data after update is someetimes required
    # e.g., integrated reward in integral reinforcement learning
    _datum[:x1_next] = x_next.sys1
    _datum[:x2_next] = x_next.sys2
    datum = (; zip(keys(_datum), values(_datum))...)  # to make it immutable; not necessary
    return datum, x_next
end
function gain(t)
    return 1  # for test
end
# terminal condition
function is_terminated(datum)
    return norm(datum.x1) < 1e-6
end
# initial condition
LazyFym.initial_condition(sys::Sys1) = [1, 2, 3]
LazyFym.initial_condition(sys::Sys2) = [3, 2, 1]


function test()
    sys1 = Sys1(2.0)
    sys2 = Sys2(1.0)
    env = Env(sys1, sys2)
    # time
    t0 = 0.0
    tf = 100.0
    Δt = 0.01
    ts = t0:Δt:tf
    ts_reverse = t0:-Δt:-tf
    # extend `LazyFym.initial_condition` will automatically construct a NamedTuple; not mandatory
    x0 = LazyFym.initial_condition(env)
    # simulator
    trajs(x0, ts) = Sim(env, x0, ts, ẋ, update)
    @time trajs(x0, ts_reverse) |> evaluate  # reverse time test
    # reuse simulator
    @time res = trajs(x0, ts) |> TakeWhile(!is_terminated) |> evaluate
    # exact solution
    x1_exact = function(t)
        c = gain(t)
        return exp(-env.sys1.a * c * t) * x0.sys1
    end
    x1_exacts = res.t |> Map(x1_exact) |> collect
    ϵ = 1e-5
    @test ([norm(res.x1[i] - x1_exacts[i])
            for i in 1:length(x1_exacts)] |> maximum) < ϵ
end

test()
