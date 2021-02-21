# LazyFym
**LazyFym** is a general purpose simulator for dynamical systems.

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

## Interface
LazyFym provides two Types: 1) 'FymSys' and 2) 'FymEnv'.
`FymSys` (probably) contains the information of dynamical system.
`FymEnv` (probably) contains the information of the whole environment,
consisting of `FymSys` systems.
###
Examples including simulation with a custom environment
can be found in directory `test`.

## Todo
- [ ] Nested environments (like `fym` and `FymEnvs`)
