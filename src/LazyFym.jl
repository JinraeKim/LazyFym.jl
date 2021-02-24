module LazyFym

using Transducers

import Base: size
using ProgressMeter

export Fym,  # types
       # internalAPI
       ∫,  # integration
       Sim,  # simulation
       # tools
       trajectory, catTrajectory, sequentialise  # postprocess

export InputAffineQuadraticCostEnv


include("types.jl")
include("internalAPI.jl")
include("integration.jl")
include("simulation.jl")
include("tools.jl")
include("postprocess.jl")

include("fymenvs.jl")


end  # module
