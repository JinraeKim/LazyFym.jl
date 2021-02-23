module LazyFym

using Reexport


export Fym
abstract type Fym end


include("LazyFymBase.jl")
@reexport using .LazyFymBase
using .LazyFymBase: initial_condition, PartitionedSim  # for convenience
using .LazyFymBase: size, flatten_length, index  # to improve the simulation speed

include("Envs.jl")
@reexport using .Envs

end  # module
