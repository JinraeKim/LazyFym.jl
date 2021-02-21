# LazyFym
**LazyFym** is a general purpose simulator for dynamical systems.
## NOTICE
This package is **work-in-progress**.

## Features
### Lazy evaluation
LazyFym is highly based on Julia's pipeline syntax and [Transducers.jl](https://github.com/JuliaFolds/Transducers.jl).
This makes it possible to evaluate your simulator lazily.
You may possibly save **your custom simulator** and load it to reproduce
simulation data and perform simulation with different configurations.
You can reuse your simulator with various initial values and time span.
### Flexible usage pattern
Unlike the previous versions of `fym` simulators, [fym](https://github.com/fdcl-nrf/fym) and [FymEnvs](https://github.com/fdcl-nrf/FymEnvs.jl),
LazyFym barely restricts the forms of your custom systems and environments
by avoding inheritance (`fym`) and class-like constructors (`FymEnvs`).
### Parallelism
(It is expected that parallel simulation is easy with this package.
Detailed explanation will be given after testing some examples.)

## Interface
LazyFym provides two Types: 1) 'FymSys' and 2) 'FymEnv'.
`FymSys` (probably) contains the information of dynamical system.
`FymEnv` (probably) contains the information of the whole environment,
consisting of `FymSys` systems.
### Quick start
Examples including simulation with a custom environment
can be found in directory `test`.
Here is a basic example:
```julia
using LazyFym
using Test
using Transducers

using LinearAlgebra


# systems
struct Sys1 <: FymSys
    a
end
struct Sys2 <: FymSys
    b
end
# environments
struct Env <: FymEnv
    sys1::Sys1
    sys2::Sys2
end
# dynamics
function ẋ(env::Env, x, t; c=1)
    x1 = x[:sys1]
    x2 = x[:sys2]
    ẋ1 = -(env.sys1.a * c) * x1
    ẋ2 = -(env.sys2.b * c) * x2
    return zip([:sys1, :sys2], [ẋ1, ẋ2]) |> Dict
end
# update rule within each time step
function update(env::Env, ẋ, x, t, Δt)
    datum = Dict(:x1 => x[:sys1], :x2 => x[:sys2], :t => t)
    c = gain(t)
    x_next = ∫(env, ẋ, x, t, Δt; c=c)  # default method: RK4
    # datum[:x_next] = x  # if necessary
    return datum, x_next
end
function gain(t)
    return 1  # for test
end
# terminal condition
function is_terminated(datum)
    return datum[:t] < 50
end
# trajs -> dict
function observe(trajs)
    _trajs = trajs |> collect
    all_keys = union([keys(traj) for traj in _trajs]...)
    get_values(key) = [get(traj, key, missing) for traj in _trajs]
    all_values = all_keys |> Map(get_values)
    return zip(all_keys, all_values) |> Dict
end
# initial condition
function generate_initial_values()
    x1 = [1, 2, 3]
    x2 = [3, 2, 1]
    return Dict(:sys1 => x1, :sys2 => x2)
end


function test()
    sys1 = Sys1(2.0)
    sys2 = Sys2(1.0)
    env = Env(sys1, sys2)
    # time
    t0 = 0.0
    tf = 100.0
    Δt = 0.01
    ts = t0:Δt:tf
    ts_reverse = t0:-Δt:-tf
    # initial condition
    x0 = generate_initial_values()
    # simulator
    trajs(x0, ts) = foldxl(|>, [
                                Sim(env, x0, ts, ẋ, update),
                                TakeWhile(is_terminated),
                               ])
    @time trajs(x0, ts_reverse) |> observe  # reverse time test
    # reuse simulator
    @time res = trajs(x0, ts) |> observe
    # exact solution
    x1_exact = function(t)
        c = gain(t)
        return exp(-env.sys1.a * c * t) * x0[:sys1]
    end
    x1_exacts = res[:t] |> Map(x1_exact) |> collect
    ϵ = 1e-5
    @test ([norm(res[:x1][i] - x1_exacts[i])
            for i in 1:length(x1_exacts)] |> maximum) < ϵ
end

test()
```
## Todo
- [ ] Nested environments (like `fym` and `FymEnvs`)
- [ ] Add an example of parallel simulation
