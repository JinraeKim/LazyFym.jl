using LazyFym
using Transducers

using Test
using LinearAlgebra


# single environment (dynamical system) case
struct Env <: Fym
end
# dynamicas
function ẋ(env::Env, x, t)
    ẋ = -x
    return ẋ
end
# initial condition
function initial_condition(env::Env)
    return rand(10)
end
# data postprocessing
function postprocess(datum_raw)
    _datum = Dict(:t => datum_raw.t, :x => datum_raw.x)
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum
end
# terminal_condition
function terminal_condition(datum)
    return norm(datum.x) < 1e-3
end

# test code
function parallel()
    env = Env()
    t0 = 0.0
    Δt = 0.01
    tf = 100.0
    ts = t0:Δt:tf
    num = 1:100
    @time x0s = num |> Map(i -> initial_condition(env)) |> collect  # initial conditions
    # simulator
    trajs_evaluate(x0, ts) = Sim(env, x0, ts, ẋ) |> TakeWhile(!terminal_condition) |> Map(postprocess) |> evaluate
    # parallel simulation
    n = rand(num)
    @time data_single = trajs_evaluate(x0s[n], ts)  # single scenario
    @time data_multiple = x0s |> Map(x0 -> trajs_evaluate(x0, ts)) |> collect  # multiple scenarios (sequential)
    @time data_parallel_t = x0s |> Map(x0 -> trajs_evaluate(x0, ts)) |> tcollect  # multiple scenarios with thread-based parallel computing
    @time data_parallel_d = x0s |> Map(x0 -> trajs_evaluate(x0, ts)) |> dcollect  # multiple scenarios with process-based parallel computing
    @test data_single == data_multiple[n]
    @test data_multiple == data_parallel_t == data_parallel_d
    return data_single, data_multiple, data_parallel_t, data_parallel_d
end

data_single, data_multiple, data_parallel_t, data_parallel_d = parallel()
nothing
