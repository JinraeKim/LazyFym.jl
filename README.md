# LazyFym
**LazyFym** is a general-purpose simulator for dynamical systems.
I'm too *lazy* to run a simulation but *eager* to make a better simulator.
## Notes
This package is **work-in-progress**.
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
Since LazyFym automatically calculate the information of environments (including size, flatten_length, etc.),
you should consider extend `LazyFym` functions for your custom environments such as `LazyFym.size`
to improve the simulation speed.
### Parallelism
It is not seemingly different from the sequential simulation.
For example,
you can perform simulation with various initial conditions by
replacing `collect` by `tcollect` (thread-based) or `dcollect` (process-based), which are provided by `Transducers.jl`.
For more details, see the below example code or `test/paralle.jl`.
### Performance improvement for simulations with long time span (Todo)
(I'm trying to apply some ideas, e.g., `PartitionedSim`,
but it seems not fast as I expected.)

## Interface
LazyFym provides a Type `Fym`.
`Fym` contains the information of an environment (system),
probably consisting of other `Fym`s as sub-environments (sub-systems).
### Quick start
you can find more examples in directory `test`,
including nested custom environments,
flexible usage patterns with eager or lazy data postprocessing,
and parallel simulation.
Here is a basic example with parallel computing (see `test/parallel.jl`):
```julia
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
```
## Todo
- [x] Nested environments (like `fym` and `FymEnvs`)
- [x] Performance improvement (supporting nested env. makes it slow -> can be improved by telling LazyFym the information of your custom environments)
- [x] Add an example of parallel simulation
