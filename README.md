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
```
## Todo
- [x] Nested environments (like `fym` and `FymEnvs`)
- [x] Performance improvement (supporting nested env. makes it slow -> can be improved by telling LazyFym the information of your custom environments)
- [ ] Add an example of parallel simulation
