using LazyFym
using Transducers

using BenchmarkTools
using LinearAlgebra
using Test

using JLD2


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
    _datum = Dict(:t => datum_raw.t, :x => datum_raw.x, :x_next => datum_raw.x_next)
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum
end
# terminal_condition
function terminal_condition(datum)
    false
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

function initialise()
    env = SimpleEnv()
    t0 = 0.0
    Δt = 0.01
    tf = 100.0
    ts = t0:Δt:tf
    # trajs_evaluate(x0, ts) = Sim(env, x0, ts, ẋ) |> TakeWhile(!terminal_condition) |> Map(postprocess) |> evaluate
    trajs_evaluate(x0, ts) = Sim(env, x0, ts, ẋ) |> TakeWhile(!terminal_condition) |> Map(postprocess) |> collect
    x0 = initial_condition(env)
    return trajs_evaluate, x0, ts
end

# test code
function normal(traj, x0, ts)
    traj(x0, ts)
end

function _partitioned(traj, x0, ts)
    num = 100
    for i = 1:num
        traj(x0, ts[1:Int(floor(length(ts)/num))])
    end
end

function partitioned(traj, x0, ts, file_path)
    horizon = 10000
    # reset
    jldopen(file_path, "w") do file
    end
    split_sim(x0, ts0) = ScanEmit((x0, ts0, 1)) do (x, ts, i), ts_next
        x_next = nothing
        if x != nothing
            data = traj(x, ts)
            if data != []
                jldopen(file_path, "a+") do file
                    file["$i"] = data
                end
                x_next = data[end].x_next
            else
                i = missing
            end
        else
            i = missing
        end
        i_next = i + 1
        return i, (x_next, ts_next, i_next)
    end
    ts_partitioned = ts |> Partition(horizon, step=horizon-1, flush=true) |> Map(copy) |> collect
    ts_partitioned_appended = [ts_partitioned..., missing]
    is = ts_partitioned_appended |> Drop(1) |> split_sim(x0, ts_partitioned_appended[1]) |> Filter(!ismissing) |> collect

    data_multiple = jldopen(file_path, "r") do file
        [file["$i"] for i in is]
    end
end

traj, x0, ts = initialise()
file_path = "example.jld2"
println("normal")
data = @btime normal($traj, $x0, $ts)
# data = normal(traj, x0, ts)
println("partitioned")
data_partitioned = @btime partitioned($traj, $x0, $ts, file_path)
# data_partitioned = partitioned(traj, x0, ts, file_path)
@test data == vcat(data_partitioned...)
# data_evaluated = @btime data |> evaluate
nothing
