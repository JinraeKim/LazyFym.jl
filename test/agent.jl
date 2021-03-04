using LazyFym
using Transducers


## Policy
abstract type Policy end
struct ExamplePolicy <: Policy
end
# command
command(policy::Policy, x, t) = -sum(x)

## simulation envs
struct RLEnv <: Fym
    env::LazyFym.InputAffineQuadraticCostEnv
    policy::Policy
end
# dynamics
function ẋ(rlenv::RLEnv, _x, t)
    x = _x.env
    u = command(rlenv.policy, x, t)
    ẋ = LazyFym.ẋ(rlenv.env, x, t, u)
    (; env = ẋ)
end
# initial condition
function initial_condition(rlenv::RLEnv)
    (; env=rand(2))
end
# LazyFym.initial_condition(env::LazyFym.InputAffineQuadraticCostEnv) = rand(2)  # NOTE: `LazyFym.initial_condition` will automatically guess the appropriate initial condition for nested envs.

function main()
    Random.seed!(1)
    rlenv = RLEnv(LazyFym.InputAffineQuadraticCostEnv(), ExamplePolicy())
    t0 = 0.0
    tf = 5.00
    Δt = 0.01
    ts = t0:Δt:tf
    x0 = initial_condition(rlenv)
    # x0 = LazyFym.initial_condition(rlenv)
    traj(x0) = Sim(rlenv, x0, ts, ẋ) |> collect |> StructArray
    data = traj(x0)
end
