using LazyFym
using Test
using Transducers

using LinearAlgebra


struct Sys1 <: FymSys
    a
end

struct Sys2 <: FymSys
    b
end

struct Env <: FymEnv
    sys1::Sys1
    sys2::Sys2
end

function ẋ(env::Env, x, t; c=1)
    x1 = x[:sys1]
    x2 = x[:sys2]
    ẋ1 = -(env.sys1.a * c) * x1
    ẋ2 = -(env.sys2.b * c) * x2
    return zip([:sys1, :sys2], [ẋ1, ẋ2]) |> Dict
end

function update(env::Env, ẋ, x, t, Δt)
    datum = Dict(:x1 => x[:sys1], :x2 => x[:sys2], :t => t)
    c = gain(t)
    x_next = ∫(env, ẋ, x, t, Δt; c=c)
    # datum[:x_next] = x  # if necessary
    return datum, x_next
end

function gain(t)
    return 1  # should be constant for comparison with exact solution
end

function is_terminated(datum)
    return datum[:t] < 50
end

function observe(trajs)
    _trajs = trajs |> collect
    all_keys = union([keys(traj) for traj in _trajs]...)
    get_values(key) = [get(traj, key, missing) for traj in _trajs]
    all_values = all_keys |> Map(get_values)
    return zip(all_keys, all_values) |> Dict
end

function generate_initial_values()
    x1 = [1, 2, 3]
    x2 = [3, 2, 1]
    return Dict(:sys1 => x1, :sys2 => x2)
end


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
    # initial condition
    x0 = generate_initial_values()
    # simulator
    trajs(x0, ts) = foldxl(|>, [
                                Sim(env, x0, ts, ẋ, update),
                                TakeWhile(is_terminated),
                               ])
    @time trajs(x0, ts_reverse) |> observe  # reverse time test
    # exact solution
    x1_exact = function(t)
        c = gain(t)
        return exp(-env.sys1.a * c * t) * x0[:sys1]
    end
    @time res = trajs(x0, ts) |> observe
    x1_exacts = res[:t] |> Map(x1_exact) |> collect
    ϵ = 1e-5
    @test ([norm(res[:x1][i] - x1_exacts[i])
            for i in 1:length(x1_exacts)] |> maximum) < ϵ
end

test()
