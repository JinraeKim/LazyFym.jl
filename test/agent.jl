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
struct IntegralReward <: Fym
end
struct RLEnv <: Fym
    env::LazyFym.InputAffineQuadraticCostEnv
    ∫r::IntegralReward
    policy::Policy
end
# dynamics
function ẋ(rlenv::RLEnv, x_nt, t; action=0.0)
    x = x_nt.env
    ẋ = LazyFym.ẋ(rlenv.env, x, t, action)
    r = LazyFym.r(rlenv.env, x, action)
    (; env = ẋ, ∫r = r)
end
# update (RL agent generates zero-order-hold (ZOH) action in this scenario)
function update(rlenv::RLEnv, ẋ, x_nt, t, Δt)
    action = command(rlenv.policy, x_nt.env, t)
    _datum = Dict(:x => x_nt.env, :t => t, :action => action)
    x_next_nt = ∫(rlenv, ẋ, x_nt, t, Δt; action=action)  # `action` will be a kwarg of ẋ
    _datum[:x_next] = x_next_nt.env
    _datum[:Δr] = x_next_nt.∫r - x_nt.∫r
    datum = (; zip(keys(_datum), values(_datum))...)
    return datum, x_next_nt
end
# initial condition
function initial_condition(rlenv::RLEnv)
    (; env=rand(2), ∫r = 0.0)
end
# LazyFym.initial_condition(env::LazyFym.InputAffineQuadraticCostEnv) = rand(2)  # NOTE: `LazyFym.initial_condition` will automatically guess the appropriate initial condition for nested envs.

function main()
    Random.seed!(1)
    rlenv = RLEnv(LazyFym.InputAffineQuadraticCostEnv(), IntegralReward(), ExamplePolicy())
    t0 = 0.0
    tf = 5.00
    Δt = 0.01
    ts = t0:Δt:tf
    x0 = initial_condition(rlenv)
    # x0 = LazyFym.initial_condition(rlenv)
    traj(x0) = Sim(rlenv, x0, ts, ẋ, update) |> collect |> StructArray
    data = traj(x0)
end
