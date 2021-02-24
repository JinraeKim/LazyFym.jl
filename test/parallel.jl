using LazyFym
using Transducers

using DataFrames
using JLD2, FileIO
using Test
using LinearAlgebra
using Plots


# single environment (dynamical system) case
struct SimpleEnv <: Fym
end
# dynamics
function ẋ(env::SimpleEnv, x, t)
    ẋ = -x
    return ẋ
end
# initial condition
function initial_condition(env::SimpleEnv)
    return 2*(rand(10) .- 0.5)
end
# data postprocessing
function postprocess(datum_raw)
    _datum = Dict(:t => datum_raw.t, :x => datum_raw.x)
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum
end
# terminal_condition
function terminal_condition(datum)
    # return norm(datum.x) < 1e-3
    return false
end
# to improve simulation speed
_env = SimpleEnv()
_x0 = initial_condition(_env)
_size = LazyFym.size(_env, _x0)
_flatten_length = LazyFym.flatten_length(_env, _x0)
_index = LazyFym.index(_env, _x0, 1:_flatten_length)
size(env::SimpleEnv, x) = _size
flatten_length(env::SimpleEnv, x) = _flatten_length
index(env::SimpleEnv, x) = _index

# test code
function parallel()
    env = SimpleEnv()
    t0 = 0.0
    Δt = 0.01
    tf = 100.0
    ts = t0:Δt:tf
    num = 1:10
    x0s = num |> Map(i -> initial_condition(env)) |> collect  # initial conditions
    # simulator
    trajs_evaluate(x0, ts) = Sim(env, x0, ts, ẋ) |> TakeWhile(!terminal_condition) |> Map(postprocess) |> evaluate
    # single scenario
    n = rand(num)
    data_single = Dict()
    data_single["raw"] = trajs_evaluate(x0s[n], ts)  # single scenario
    @time trajs_evaluate(x0s[n], ts)  # to check speed
    data_single["dict"] = zip(keys(data_single["raw"]), values(data_single["raw"])) |> Dict
    data_single["df"] = DataFrame(data_single["dict"])
    # multiple scenarios (NOTICE: you should run codes with option -t such as `julia -t 4`)
    data_parallel = Dict()
    data_parallel["raw"] = x0s |> Map(x0 -> trajs_evaluate(x0, ts)) |> tcollect  # tcollect for thread-based parallel computing
    @time x0s |> Map(x0 -> trajs_evaluate(x0, ts)) |> tcollect  # to check speed
    data_parallel["df"] = DataFrame(Dict("x0s" => x0s, "trajs" => data_parallel["raw"]))
    data_parallel["cat"] = data_parallel["df"].trajs |> catevaluate
    # save and load compatiblity with JLD2 and FileIO
    save("example.jld2", Dict("df" => data_parallel["df"]))
    data_parallel["df_loaded"] = load("example.jld2")["df"]
    @test data_parallel["df"] == data_parallel["df_loaded"]
    # plot figures; to see, uncomment the following lines
    # plot(data_single["df"].t, sequentialise(data_single["df"].x); seriestype=:scatter)
    # plot(data_parallel["cat"].t, data_parallel["cat"].x |> sequentialise; seriestype=:scatter)
    return Dict("data_single" => data_single, "data_parallel" => data_parallel)
end

result = parallel()
nothing
