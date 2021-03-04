using LazyFym
using Transducers

using Random
using StructArrays


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
function ẋ(rlenv::RLEnv, _x, t; action=0.0)
    x = _x.env
    ẋ = LazyFym.ẋ(rlenv.env, x, t, action)
    (; env = ẋ)
end
# update (RL agent generates zero-order-hold (ZOH) action in this scenario)
function update(rlenv::RLEnv, ẋ, x, t, Δt)
    action = command(rlenv.policy, x.env, t)
    _datum = Dict(:x => x, :t => t, :action => action)
    x_next = ∫(rlenv, ẋ, x, t, Δt; action=action)  # `action` will be a kwarg of ẋ
    _datum[:x_next] = x_next
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum, x_next
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
    traj(x0) = Sim(rlenv, x0, ts, ẋ, update) |> collect |> StructArray
    data = traj(x0)
end
