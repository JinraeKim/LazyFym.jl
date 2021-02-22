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
### Parallelism (Todo)
(It is expected that parallel simulation is easy with this package.
Detailed explanation will be given after testing some examples.)
### Performance improvement for simulations with long time span (Todo)
(I'm trying to apply some ideas, e.g., `PartitionedSim`,
but it seems not fast as I expected.)

## Interface
LazyFym provides a Type `FymEnv`.
`FymEnv` contains the information of an environment (system),
probably consisting of other `FymEnv`s as sub-environments (sub-systems).
### Quick start
Examples including simulation with a custom environment
can be found in directory `test`.
Here is a basic example:
```
using LazyFym
using Test
using Transducers

using LinearAlgebra


# sub-envs
struct Env1 <: FymEnv
    a
end
struct Env2 <: FymEnv
    b
end
struct EnvBig <: FymEnv
    env1::Env1
    env2::Env2
end
# environments
struct Env <: FymEnv
    env1::Env1
    envbig::EnvBig
end
# dynamics
function ẋ(env::Env, x, t; c=1)
    x1 = x.env1  # x will be given as NamedTuple
    xbig1 = x.envbig.env1
    xbig2 = x.envbig.env2
    ẋ1 = -(env.env1.a * c) * x1
    ẋbig1 = -(env.envbig.env1.a * c) * xbig1
    ẋbig2 = -(env.envbig.env2.b * c) * xbig2
    return (; env1 = ẋ1, envbig = (; env1 = ẋbig1, env2 = ẋbig2))
end
# (eager data postprocessing) update rule within each time step
# To improve simulator speed, you should consider lazy data postprocessing using `LazyFym.update`.
function update(env::Env, ẋ, x, t, Δt)
    _datum = Dict()
    _datum[:x] = x
    _datum[:t] = t
    _datum[:x1] = x.env1
    _datum[:xbig1] = x.envbig.env1
    _datum[:xbig2] = x.envbig.env2
    c = gain(t)
    x_next = ∫(env, ẋ, x, t, Δt; c=c)  # default method: RK4
    # Recording data after update is someetimes required
    # e.g., integrated reward in integral reinforcement learning
    _datum[:x_next] = x_next
    _datum[:x1_next] = x_next.env1
    _datum[:xbig1_next] = x_next.envbig.env1
    _datum[:xbig2_next] = x_next.envbig.env2
    datum = (; zip(keys(_datum), values(_datum))...)  # to make it immutable; not necessary
    return datum, x_next
end
function postprocess(datum_raw)
    _datum = Dict(:t => datum_raw.t, :x1 => datum_raw.x.env1)
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum
end
function gain(t)
    return 1  # for test
end
# terminal condition
function terminal_condition(datum)
    return norm(datum.x.env1) < 1e-6
end
function terminal_condition_readable(datum)
    return norm(datum.x1) < 1e-6
end
# initial condition
LazyFym.initial_condition(env::Env1) = [1, 2, 3]
LazyFym.initial_condition(env::Env2) = [3, 2, 1]


## lazy postprocessing
function default_update()
    println("Simulation with custom update (lazy postprocessing)")
    env1 = Env1(2.0)
    envbig1 = Env1(3.0)
    envbig2 = Env2(1.0)
    envbig = EnvBig(envbig1, envbig2)
    env = Env(env1, envbig)
    # time
    t0 = 0.0
    tf = 100.0
    Δt = 0.01
    ts = t0:Δt:tf
    # extend `LazyFym.initial_condition` will automatically construct a NamedTuple; not mandatory
    x0 = LazyFym.initial_condition(env)
    # simulator (default)
    trajs(x0, ts) = Sim(env, x0, ts, ẋ)  # `update` is loaded from `LazyFym`
    # (example) simulation with terminal condition
    @time _ = trajs(x0, ts) |> TakeWhile(!terminal_condition) |> Map(postprocess) |> evaluate
    @time data_ = trajs(x0, ts) |> Map(postprocess) |> TakeWhile(!terminal_condition_readable) |> evaluate
    # (example) simulation with given time span
    @time data = trajs(x0, ts) |> Map(postprocess) |> evaluate
    # (tool) `PartitionedSim` for very long simulation (to use this, you must add `x_next` to datum in your custom `update` function)
    # TODO: `PartitionedSim` is quite slow although it is introduced for long simulation
    @time _data = LazyFym.PartitionedSim(trajs, x0, ts; horizon=1000) |> Map(postprocess) |> TakeWhile(!terminal_condition_readable) |> evaluate
    _trajs(x0, ts) = trajs(x0, ts) |> TakeWhile(!terminal_condition)
    @time _ = LazyFym.PartitionedSim(_trajs, x0, ts; horizon=1000) |> Map(postprocess) |> evaluate
    @test data_ == _data  # test `PartitionedSim`
    # (test) compare simulation result with the exact solution (linear system)
    x1_exact = function(t)
        c = gain(t)
        return exp(-env.env1.a * c * t) * x0.env1
    end
    x1_exacts = data.t |> Map(x1_exact) |> collect
    ϵ = 1e-6
    @test ([norm(data.x1[i] - x1_exacts[i]) for i in 1:length(x1_exacts)] |> maximum) < ϵ
    return data_, data, _data  # for test
end

default_update()
```
## Todo
- [x] Nested environments (like `fym` and `FymEnvs`)
- [x] Performance improvement (supporting nested env. makes it slow -> can be improved by telling LazyFym the information of your custom environments)
- [ ] Add an example of parallel simulation
