using LazyFym
using Transducers
using InfiniteArrays

function ẋ(env::LazyFym.InputAffineQuadraticCostEnv, x, t)
    u = command(env, x)
    ẋ = LazyFym.ẋ(env, x, t, u)
    return ẋ
end
_env = LazyFym.InputAffineQuadraticCostEnv()
command(env, x) = LazyFym.u_optimal(_env, x)

function initial_condition(env::LazyFym.InputAffineQuadraticCostEnv)
    return rand(2)
end

function postprocess(_datum)
    datum = (; t = _datum.t, x = _datum.x)
    return datum
end

function test()
    env = LazyFym.InputAffineQuadraticCostEnv()
    t0 = 0.0
    Δt = 0.01
    # tf = 100.0
    # ts = t0:Δt:tf
    # ts = t0:Δt:∞
    x0 = initial_condition(env)
    sim(x0) = t -> Sim(env, x0, t0:Δt:∞, ẋ) |> TakeWhile(datum -> datum.t <= t) |> collect
    traj = sim(x0)
    @show traj(0.3)
end
test()
