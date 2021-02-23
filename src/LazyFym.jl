module LazyFym

using Transducers

import Base: size


include("types.jl")
include("internalAPI.jl")
include("integration.jl")
include("simulation.jl")
include("tools.jl")
include("postprocess.jl")

include("fymenvs.jl")

export Fym,
       ∫,
       Sim,
       evaluate, catevaluate, sequentialise

export InputAffineQuadraticCostEnv


end  # module
