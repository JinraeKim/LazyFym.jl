using LazyFym
using Transducers

using Plots


function ẋ(env::Envs.InputAffineQuadraticCostEnv, x, t)
    u = command(env, x)
    ẋ = Envs.ẋ(env, x, t, u)
    return ẋ
end
_env = Envs.InputAffineQuadraticCostEnv()
command(env, x) = Envs.u_optimal(_env, x)

function initial_condition(env::Envs.InputAffineQuadraticCostEnv)
    return rand(2)
end

function postprocess(_datum)
    datum = (; t = _datum.t, x = _datum.x)
    return datum
end

function test()
    env = Envs.InputAffineQuadraticCostEnv()
    t0 = 0.0
    Δt = 0.01
    tf = 100.0
    ts = t0:Δt:tf
    x0 = initial_condition(env)
    trajs(x0, ts) = Sim(env, x0, ts, ẋ) |> Map(postprocess) |> evaluate
    @time data = trajs(x0, ts)
    plot(data.t, sequentialise(data.x))
end

test()
