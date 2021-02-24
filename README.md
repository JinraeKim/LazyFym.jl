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

![Test Image 1](./figures/lazy.pdf)

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
