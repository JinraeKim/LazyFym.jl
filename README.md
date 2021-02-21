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
### Parallelism
(It is expected that parallel simulation is easy with this package.
Detailed explanation will be given after testing some examples.)

## Interface
LazyFym provides a Type `FymEnv`.
`FymEnv` contains the information of an environment (system),
probably consisting of other `FymEnv`s as sub-environments (sub-systems).
### Quick start
Examples including simulation with a custom environment
can be found in directory `test`.
Here is a basic example:
```julia
using LazyFym
using Test
using Transducers

using LinearAlgebra
# using Plots


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
# update rule within each time step
function update(env::Env, ẋ, x, t, Δt)
    _datum = Dict()
    _datum[:t] = t
    _datum[:x1] = x.env1
    _datum[:xbig1] = x.envbig.env1
    _datum[:xbig2] = x.envbig.env2
    c = gain(t)
    x_next = ∫(env, ẋ, x, t, Δt; c=c)  # default method: RK4
    # Recording data after update is someetimes required
    # e.g., integrated reward in integral reinforcement learning
    _datum[:x1_next] = x_next.env1
    _datum[:xbig1_next] = x_next.envbig.env1
    _datum[:xbig2_next] = x_next.envbig.env2
    datum = (; zip(keys(_datum), values(_datum))...)  # to make it immutable; not necessary
    return datum, x_next
end
function gain(t)
    return 1  # for test
end
# terminal condition
function is_terminated(datum)
    return norm(datum.x1) < 1e-6
end
# initial condition
LazyFym.initial_condition(env::Env1) = [1, 2, 3]
LazyFym.initial_condition(env::Env2) = [3, 2, 1]


function custom_env()
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
    ts_reverse = t0:-Δt:-tf
    # extend `LazyFym.initial_condition` will automatically construct a NamedTuple; not mandatory
    x0 = LazyFym.initial_condition(env)
    # simulator
    trajs(x0, ts) = Sim(env, x0, ts, ẋ, update)
    # trajs(x0, ts) = Sim(env, x0, ts, LazyFym.ẋ, LazyFym.update)  # for test
    @time trajs(x0, ts) |> evaluate  # reuse test
    @time data = trajs(x0, ts) |> TakeWhile(!is_terminated) |> evaluate
    # exact solution
    x1_exact = function(t)
        c = gain(t)
        return exp(-env.env1.a * c * t) * x0.env1
    end
    x1_exacts = data.t |> Map(x1_exact) |> collect
    ϵ = 1e-5
    @test ([norm(data.x1[i] - x1_exacts[i]) for i in 1:length(x1_exacts)] |> maximum) < ϵ
    # plot(data.t, sequentialise(data.x1))
    # return data  # for debug
end

custom_env()
# data = custom_env()  # for debug
```
## Todo
- [x] Nested environments (like `fym` and `FymEnvs`)
- [ ] Performance optimisation (supporting nested env. makes it slow)
- [ ] Add an example of parallel simulation
