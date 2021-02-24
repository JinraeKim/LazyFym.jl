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
You can also perform numerical simulations with lazy evaluation,
nested custom environments, eager or lazy data postprocessing, and parallel simulation.
Please take a look at directory `test` (some examples may be omitted).

```julia
using LazyFym
using Transducers

using InfiniteArrays
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
    sim(x0) = t -> Sim(env, x0, ts, ẋ) |> TakeWhile(datum -> datum.t <= t) |> collect |> trajectory
    traj_x0 = sim(x0)
    data = traj_x0(t1)
    p = plot(data.t, data.x |> sequentialise, seriestype=:scatter, label=["x1" "x2"])
    savefig(p, "figures/lazy.png")
end
lazy()
```
![lazy](./figures/lazy.png)
```julia
function parallel()
    Random.seed!(1)
    env = LazyFym.InputAffineQuadraticCostEnv()
    t0 = 0.0
    t1 = 10.00
    Δt = 0.01
    ts = t0:Δt:∞
    num = 10
    x0s = 1:num |> Map(i -> initial_condition(env))
    traj(x0) = Sim(env, x0, ts, ẋ) |> TakeWhile(datum -> datum.t <= t1) |> collect |> trajectory
    data_parallel = x0s |> Map(x0 -> traj(x0)) |> tcollect
    data_parallel_whole = data_parallel |> catTrajectory
    p = plot(data_parallel_whole.t, data_parallel_whole.x |> sequentialise, seriestype=:scatter, label=["x1" "x2"])
    savefig(p, "figures/parallel.png")
end
parallel()
```
![parallel](./figures/parallel.png)

## Performance Tips
### Environment information
Since LazyFym automatically calculate the information of environments (including size, flatten_length, etc.)
and may result in performance degeneration,
you should consider extend `LazyFym` functions for your custom environments such as `LazyFym.size`
to improve the simulation speed (about 2~3 times faster in most cases).
### Postprocess data after simulation
Postprocessing will make your simulator slow.
Postprocessing after obtaining simulation data would be beneficial if your simulation itself has bottleneck.

## Todo
- [x] Nested environments (like `fym` and `FymEnvs`)
- [x] Performance improvement (supporting nested env. makes it slow -> can be improved by telling LazyFym the information of your custom environments)
- [x] Add an example of parallel simulation
<!-- - [ ] Performance improvement for simulations with long time span -->
