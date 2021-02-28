using LazyFym
using Transducers

# using Lazy
using InfiniteArrays
using StructArrays
using Random
using Plots, LaTeXStrings


function ẋ(env::LazyFym.InputAffineQuadraticCostEnv, x, t)
    u = command(env, x)
    ẋ = LazyFym.ẋ(env, x, t, u)
end
_env = LazyFym.InputAffineQuadraticCostEnv()
command(env, x) = LazyFym.u_optimal(_env, x)  # you can customise it

function initial_condition(env::LazyFym.InputAffineQuadraticCostEnv)
    2*(rand(2) .- 0.5)
end

function postprocess(env::LazyFym.InputAffineQuadraticCostEnv)
    function _postprocess(_datum)
        t = _datum.t
        x = _datum.x
        x1 = _datum.x[1]
        x2 = _datum.x[2]
        u = command(env, x)
        datum = (; t = t, x = x, x1=x1, x2=x2, u = u)
    end
end

function single()
    Random.seed!(1)
    env = LazyFym.InputAffineQuadraticCostEnv()
    t0 = 0.0
    t1 = 5.00
    Δt = 0.01
    ts = t0:Δt:∞
    x0 = initial_condition(env)
    sim(x0) = t -> Sim(env, x0, ts, ẋ) |> TakeWhile(datum -> datum.t <= t) |> Map(postprocess(env)) |> collect |> StructArray
    traj_x0 = sim(x0)
    data = traj_x0(t1)
    # data = @lazy traj_x0(t1);  # for lazy evaluation, see Lazy.jl
    l = @layout [a; b; c]
    p_x1 = plot(data.t, data.x1,
                ylabel=L"x_{1}", label=nothing, ylim=(-1.5, 1.5))
    p_x2 = plot(data.t, data.x2,
                ylabel=L"x_{2}", label=nothing, ylim=(-1.5, 1.5))
    p_u = plot(data.t, data.u,
               xlabel=L"t", ylabel=L"u", label=nothing, ylim=(-3, 3))
    p = plot(p_x1, p_x2, p_u, layout = l)
    savefig(p, "figures/single.png")
end

function parallel()
    Random.seed!(1)
    env = LazyFym.InputAffineQuadraticCostEnv()
    t0 = 0.0
    t1 = 5.00
    Δt = 0.01
    ts = t0:Δt:∞
    num = 10
    x0s = 1:num |> Map(i -> initial_condition(env))
    traj(x0) = Sim(env, x0, ts, ẋ) |> TakeWhile(datum -> datum.t <= t1) |> Map(postprocess(env)) |> collect
    data_parallel = x0s |> Map(x0 -> traj(x0)) |> Map(StructArray) |> tcollect
    # data_parallel_whole = data_parallel |> TCat(Threads.nthreads()) |> collect |> StructArray   # merge data
    l = @layout [a; b; c]
    p_x1 = plot()
    _ = data_parallel |> Map(data -> plot!(p_x1, data.t, data.x1,
                                           ylabel=L"x_{1}", label=nothing,
                                           ylim=(-1.5, 1.5))) |> collect
    p_x2 = plot()
    _ = data_parallel |> Map(data -> plot!(p_x2, data.t, data.x2,
                                           ylabel=L"x_{2}", label=nothing,
                                           ylim=(-1.5, 1.5))) |> collect
    p_u = plot()
    _ = data_parallel |> Map(data -> plot!(p_u, data.t, data.u,
                                           xlabel=L"t", ylabel=L"u", label=nothing,
                                           ylim=(-3, 3))) |> collect
    p = plot(p_x1, p_x2, p_u, layout = l)
    savefig(p, "figures/parallel.png")
end

# single()
# parallel()
