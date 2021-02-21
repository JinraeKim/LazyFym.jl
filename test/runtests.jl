using LazyFym
using Test
using Transducers

using LinearAlgebra
using Plots


# sub-envs
struct Env1 <: FymEnv
    a
end
struct Env2 <: FymEnv
    b
end
struct EnvBig <: FymEnv
    env1::Env1
    env2::Env2
end
# environments
struct Env <: FymEnv
    env1::Env1
    envbig::EnvBig
end
# dynamics
function ẋ(env::Env, x, t; c=1)
    x1 = x.env1  # x will be given as NamedTuple
    xbig1 = x.envbig.env1
    xbig2 = x.envbig.env2
    ẋ1 = -(env.env1.a * c) * x1
    ẋbig1 = -(env.envbig.env1.a * c) * xbig1
    ẋbig2 = -(env.envbig.env2.b * c) * xbig2
    return (; env1 = ẋ1, envbig = (; env1 = ẋbig1, env2 = ẋbig2))
end
# update rule within each time step
function update(env::Env, ẋ, x, t, Δt)
    _datum = Dict()
    _datum[:t] = t
    _datum[:x1] = x.env1
    _datum[:xbig1] = x.envbig.env1
    _datum[:xbig2] = x.envbig.env2
    c = gain(t)
    x_next = ∫(env, ẋ, x, t, Δt; c=c)  # default method: RK4
    # Recording data after update is someetimes required
    # e.g., integrated reward in integral reinforcement learning
    _datum[:x1_next] = x_next.env1
    _datum[:xbig1_next] = x_next.envbig.env1
    _datum[:xbig2_next] = x_next.envbig.env2
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
LazyFym.initial_condition(env::Env1) = [1, 2, 3]
LazyFym.initial_condition(env::Env2) = [3, 2, 1]


function custom_env()
    env1 = Env1(2.0)
    envbig1 = Env1(3.0)
    envbig2 = Env2(1.0)
    envbig = EnvBig(envbig1, envbig2)
    env = Env(env1, envbig)
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
    # trajs(x0, ts) = Sim(env, x0, ts, LazyFym.ẋ, LazyFym.update)  # for test
    @time trajs(x0, ts) |> evaluate  # reuse test
    @time data = trajs(x0, ts) |> TakeWhile(!is_terminated) |> evaluate
    # exact solution
    x1_exact = function(t)
        c = gain(t)
        return exp(-env.env1.a * c * t) * x0.env1
    end
    x1_exacts = data.t |> Map(x1_exact) |> collect
    ϵ = 1e-5
    @test ([norm(data.x1[i] - x1_exacts[i]) for i in 1:length(x1_exacts)] |> maximum) < ϵ
    # plot(data.t, sequentialise(data.x1))
    # return data  # for debug
end

custom_env()
# data = custom_env()  # for debug
