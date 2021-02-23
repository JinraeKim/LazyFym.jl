module LazyFym

using Reexport


export Fym
abstract type Fym end


include("LazyFymBase.jl")
@reexport using .LazyFymBase
using .LazyFymBase: initial_condition, flatten_length, index
include("Envs.jl")
@reexport using .Envs

end  # module
