using LazyFym
using Transducers

using InfiniteArrays
using StructArrays
using Random
using Plots


function ẋ(env::LazyFym.InputAffineQuadraticCostEnv, x, t)
    u = command(env, x)
    ẋ = LazyFym.ẋ(env, x, t, u)
    return ẋ
end
_env = LazyFym.InputAffineQuadraticCostEnv()
command(env, x) = LazyFym.u_optimal(_env, x)  # you can customise it

function initial_condition(env::LazyFym.InputAffineQuadraticCostEnv)
    return rand(2)
end

function postprocess(_datum)
    datum = (; t = _datum.t, x = _datum.x, sin = sin.(_datum.x))
    return datum
end

function lazy()
    Random.seed!(1)
    env = LazyFym.InputAffineQuadraticCostEnv()
    t0 = 0.0
    t1 = 10.00
    Δt = 0.01
    ts = t0:Δt:∞
    x0 = initial_condition(env)
    sim(x0) = t -> Sim(env, x0, ts, ẋ) |> TakeWhile(datum -> datum.t <= t) |> collect |> StructArray
    traj_x0 = sim(x0)
    data = traj_x0(t1)
    p = plot(data.t, data.x |> sequentialise, seriestype=:scatter, label=["x1" "x2"])
    savefig(p, "figures/lazy.png")
end
lazy()

function parallel()
    Random.seed!(1)
    env = LazyFym.InputAffineQuadraticCostEnv()
    t0 = 0.0
    t1 = 10.00
    Δt = 0.01
    ts = t0:Δt:∞
    num = 10
    x0s = 1:num |> Map(i -> initial_condition(env))
    traj(x0) = Sim(env, x0, ts, ẋ) |> TakeWhile(datum -> datum.t <= t1) |> collect
    data_parallel = x0s |> Map(x0 -> traj(x0)) |> tcollect
    data_parallel_whole = data_parallel |> Cat() |> StructArray 
    p = plot(data_parallel_whole.t, data_parallel_whole.x |> sequentialise, seriestype=:scatter, label=["x1" "x2"])
    savefig(p, "figures/parallel.png")
end
parallel()
