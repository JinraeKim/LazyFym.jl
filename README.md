# LazyFym
**LazyFym** is a general-purpose simulator for dynamical systems.
I'm too *lazy* to run a simulation but *eager* to make a better simulator.
## Notes
The origin of the name `Fym` is from the previous versions of flight (but also general-purpose) simulators:
[fym](https://github.com/fdcl-nrf/fym) in `Python` and [FymEnvs.jl](https://github.com/fdcl-nrf/FymEnvs.jl) in `Julia`.

## Features
### Lazy evaluation
LazyFym is highly based on Julia's pipeline syntax and [Transducers.jl](https://github.com/JuliaFolds/Transducers.jl).
This makes it possible to evaluate your simulator lazily.
You may possibly save **your custom simulator** and load it to reproduce
simulation data and perform simulation with different configurations.
You can reuse your simulator with various initial values and time span.
### Flexible usage pattern and nested environments
LazyFym supports **nested environments**.
In addition,
LazyFym does not restrict the forms of your custom environments
and thus provides a general-purpose interface.
You can take either eager or lazy data postprocessing with LazyFym.
Since LazyFym automatically calculate the information of environments (including size, flatten_length, etc.)
and may result in performance degeneration,
you should consider extend `LazyFym` functions for your custom environments such as `LazyFym.size`
to improve the simulation speed.
### Parallelism
It is not seemingly different from the sequential simulation.
For example,
you can perform simulation with various initial conditions by
replacing `collect` by `tcollect` (thread-based) or `dcollect` (process-based), which are provided by `Transducers.jl`.
For more details, see the below example code or `test/parallel.jl`.
You should run Julia codes with option `-t`, for example, `julia -t 4`
for thread-based parallel simulation.
### Predefined Environments
LazyFym provides some predefined environments for reproducible codes.
Take a look at `src/fymenvs.jl`.
<!-- ### Performance improvement for simulations with long time span (Todo; experimental) -->
<!-- (I'm trying to apply some ideas, e.g., `PartitionedSim`, -->
<!-- but it seems slower than expected.) -->

## Interface
LazyFym provides a Type `Fym`.
`Fym` contains the information of an environment (system),
probably consisting of other `Fym`s as sub-environments (sub-systems).
### Quick start
you can find more examples in directory `test`,
including nested custom environments,
flexible usage patterns with eager or lazy data postprocessing,
and parallel simulation.
Here is a basic example with parallel computing and data manipulation to generate a data table (`DataFrames`) and save and load data (`JLD2`) and plot figures (`Plots`) (see `test/parallel.jl`):
```julia
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
```
## Todo
- [x] Nested environments (like `fym` and `FymEnvs`)
- [x] Performance improvement (supporting nested env. makes it slow -> can be improved by telling LazyFym the information of your custom environments)
- [x] Add an example of parallel simulation
- [ ] Performance improvement for simulations with long time span
