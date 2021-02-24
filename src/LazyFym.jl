module LazyFym

using Transducers

import Base: size
using ProgressMeter


include("types.jl")
include("internalAPI.jl")
include("integration.jl")
include("simulation.jl")
include("tools.jl")
include("postprocess.jl")

include("fymenvs.jl")

export Fym,  # types
       # internalAPI
       ∫,  # integration
       Sim,  # simulation
       # tools
       evaluate, catevaluate, sequentialise  # postprocess

export InputAffineQuadraticCostEnv


end  # module
