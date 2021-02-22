using LazyFym
using Transducers

using Test
using LinearAlgebra


struct Env <: Fym
end

function ẋ(env::Env, x, t)
    ẋ = -x
    return ẋ
end

function initial_condition(env::Env)
    return rand(3)
end

function postprocess(datum_raw)
    _datum = Dict(:t => datum_raw.t, :x => datum_raw.x)
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum
end

function terminal_condition(datum)
    return norm(datum.x) < 1e-3
end

function parallel()
    env = Env()
    t0 = 0.0
    Δt = 0.01
    tf = 1.0
    ts = t0:Δt:tf
    num = 1000
    # initial conditions
    x0s = 1:num |> Map(i -> initial_condition(env)) |> collect
    # simulator
    trajs(x0, ts) = Sim(env, x0, ts, ẋ) |> TakeWhile(!terminal_condition)
    # paralell simulation
    @time data_single = trajs(x0s[1], ts) |> Map(postprocess) |> evaluate
    @time data_parallel = foldxl(|>,
                                 [x0s,
                                  Map(x0 -> trajs(x0, ts)),
                                  collect,
                                  Map(_data -> _data |> Map(postprocess) |> evaluate),
                                  collect])
    @time data_parallel_distributed = foldxd(|>,
                                             [x0s,
                                              Map(x0 -> trajs(x0, ts)),
                                              collect,
                                              Map(_data -> _data |> Map(postprocess) |> evaluate),
                                              collect])
    @test data_single == data_parallel[1]
    # @test data_parallel == data_parallel_distributed
    return data_single, data_parallel, data_parallel_distributed
end

data_single, data_parallel, data_parallel_distributed = parallel()
nothing
